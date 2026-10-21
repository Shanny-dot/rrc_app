import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Public Google/Facebook sign-in IDs from assets/config/social.json.
/// Empty values mean that provider isn't set up yet (its button is hidden).
class SocialConfig {
  final String googleWebClientId;
  final String googleIosClientId;
  final String facebookAppId;
  final String facebookClientToken;

  const SocialConfig._(this.googleWebClientId, this.googleIosClientId, this.facebookAppId, this.facebookClientToken);

  static bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Google needs the Web client ID everywhere, plus the iOS client ID on iPhones.
  bool get googleReady => googleWebClientId.isNotEmpty && (!_isIOS || googleIosClientId.isNotEmpty);
  bool get facebookReady => facebookAppId.isNotEmpty && facebookClientToken.isNotEmpty;

  static SocialConfig? _cached;

  /// Already-loaded settings (null until [load] has run), for building buttons.
  static SocialConfig? get current => _cached;

  static Future<SocialConfig> load() async {
    if (_cached != null) return _cached!;
    try {
      final data = jsonDecode(await rootBundle.loadString('assets/config/social.json')) as Map<String, dynamic>;
      String v(String k) => (data[k] ?? '').toString().trim();
      _cached = SocialConfig._(v('google_web_client_id'), v('google_ios_client_id'), v('facebook_app_id'), v('facebook_client_token'));
    } catch (e) {
      debugPrint('Social config not loaded: $e');
      _cached = const SocialConfig._('', '', '', '');
    }
    return _cached!;
  }

  static const notReadyMessage = 'This sign-in option is being set up. Please use email for now.';
}
