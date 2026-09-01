import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Production API URL
  static String get baseUrl => 'https://rrc-backend-1dmv.onrender.com';
  final storage = const FlutterSecureStorage();

  static String? _inMemoryToken;

  Future<Map<String, String>> _getHeaders() async {
    String? token = _inMemoryToken;
    if (token == null) {
      try {
        token = await storage.read(key: 'jwt_token');
        _inMemoryToken = token;
      } catch (e) {
        debugPrint('Storage read error: $e');
      }
    }
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      await storage.write(key: 'jwt_token', value: token);
    } catch (e) {
      debugPrint('Storage write error (macOS sandbox): $e');
    }
  }

  Future<void> logout() async {
    _inMemoryToken = null;
    try {
      await storage.delete(key: 'jwt_token');
    } catch (e) {
      debugPrint('Storage delete error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    if (_inMemoryToken != null) return true;
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token != null) _inMemoryToken = token;
      return token != null;
    } catch (e) {
      return false;
    }
  }

  // Safe HTTP request helper with built-in 45-second timeout and exception handling (accommodates Render free tier cold starts)
  Future<http.Response> _safeRequest(Future<http.Response> Function() requestFn) async {
    try {
      return await requestFn().timeout(const Duration(seconds: 45));
    } catch (e) {
      debugPrint("API request error: $e");
      return http.Response(
        jsonEncode({'detail': 'Network connection timed out. Please check your connection and try again.'}),
        504,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Map<String, dynamic>> resendOTP(String mobile) async {
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/auth/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
      }),
    ));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Failed to resend OTP'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['access_token']);
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Login failed'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    ));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': data['message'] ?? 'Password reset instructions sent'};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Failed to send password reset email'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    // The FastAPI expects the user payload in the body
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    ));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['access_token'] != null && data['access_token'] != 'pending_verification') {
        await saveToken(data['access_token']);
      }
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Registration failed'};
    }
  }

  Future<Map<String, dynamic>> verifyMobile(String mobile, String otpCode) async {
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/auth/verify-mobile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'code': otpCode,
      }),
    ));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['access_token'] != null) {
        await saveToken(data['access_token']);
      }
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Verification failed'};
    }
  }

  // Submit Referral
  Future<Map<String, dynamic>> submitReferral(Map<String, String> referralData) async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/referrals/'),
      headers: headers,
      body: jsonEncode(referralData),
    ));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Failed to submit referral'};
    }
  }

  // Get Referrals
  Future<Map<String, dynamic>> getReferrals() async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.get(
      Uri.parse('$baseUrl/api/v1/referrals/'),
      headers: headers,
    ));
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false, 'error': 'Failed to fetch referrals'};
  }

  // Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: headers,
    ));

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Failed to load profile'};
    }
  }

  // Get Events
  Future<Map<String, dynamic>> getEvents() async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.get(
      Uri.parse('$baseUrl/api/v1/events/'),
      headers: headers,
    ));
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Failed to load events'};
    }
  }

  // RSVP to Event
  Future<Map<String, dynamic>> rsvpEvent(String eventId) async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/events/$eventId/rsvp'),
      headers: headers,
    ));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Failed to RSVP'};
    }
  }

  // Scan Event QR Code (User scanning Admin Event QR)
  Future<Map<String, dynamic>> scanEventAttendance(String eventId) async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/events/$eventId/scan-attendance'),
      headers: headers,
    ));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Scan Failed'};
    }
  }

  // Invite Guests
  Future<Map<String, dynamic>> inviteGuests(String eventId, List<Map<String, String>> guests) async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/events/$eventId/invite-guests'),
      headers: headers,
      body: jsonEncode(guests),
    ));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Failed to invite guests'};
    }
  }

  // Get Rewards
  Future<Map<String, dynamic>> getRewards() async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.get(
      Uri.parse('$baseUrl/api/v1/rewards/'),
      headers: headers,
    ));
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Failed to load rewards'};
    }
  }

  // Redeem Reward
  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _safeRequest(() => http.post(
      Uri.parse('$baseUrl/api/v1/rewards/$rewardId/redeem'),
      headers: headers,
    ));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Failed to redeem reward'};
    }
  }

  // Get Transactions (Activity)
  Future<Map<String, dynamic>> getTransactions() async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.get(
      Uri.parse('$baseUrl/api/v1/transactions/'),
      headers: headers,
    ));
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Failed to load activity'};
    }
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.put(
      Uri.parse('$baseUrl/api/v1/auth/profile'),
      headers: headers,
      body: jsonEncode(profileData),
    ));

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'error': data['detail'] ?? 'Failed to update profile'};
    }
  }

  // Delete User Account
  Future<Map<String, dynamic>> deleteAccount() async {
    final headers = await _getHeaders();
    final response = await _safeRequest(() => http.delete(
      Uri.parse('$baseUrl/api/v1/auth/account'),
      headers: headers,
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      String errMsg = 'Failed to delete account';
      try {
        final data = jsonDecode(response.body);
        errMsg = data['detail'] ?? errMsg;
      } catch (_) {}
      return {'success': false, 'error': errMsg};
    }
  }
}
