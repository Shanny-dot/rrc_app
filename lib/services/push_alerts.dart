import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../firebase_options.dart';
import 'api_service.dart';

/// Phone alerts (Firebase Cloud Messaging). The backend decides what to send and respects the
/// member's choices on the Notifications settings screen.
class PushAlerts {
  static const _askedKey = 'push_permission_asked';
  static bool _initialised = false;
  static StreamSubscription<String>? _tokenSub;
  static RemoteMessage? _pendingOpen;

  /// Called when the member taps an alert (app in background) — set by main.dart.
  static void Function(Map<String, dynamic> data)? onOpen;

  /// Called for alerts that arrive while the app is open — set by main.dart.
  static void Function(String title, String body, Map<String, dynamic> data)? onForeground;

  static Future<void> init() async {
    if (_initialised || kIsWeb) return;
    try {
      final info = await PackageInfo.fromPlatform();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.forPlatform(info.packageName));
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) onForeground?.call(n.title ?? '', n.body ?? '', m.data);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen?.call(m.data));
      // Opened from an alert while the app wasn't running: handled once Home is showing.
      _pendingOpen = await FirebaseMessaging.instance.getInitialMessage();
      _initialised = true;
    } catch (e) {
      debugPrint('Push setup error: $e');
    }
  }

  /// The alert that launched the app, if any (returned once).
  static Map<String, dynamic>? takeLaunchAlert() {
    final m = _pendingOpen;
    _pendingOpen = null;
    return m?.data;
  }

  /// Asks for permission the first time (signed-in members only) and registers this phone.
  static Future<void> register({bool askIfNeeded = true}) async {
    if (!_initialised) await init();
    if (!_initialised) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final storage = ApiService().storage;
      var settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined && askIfNeeded &&
          await storage.read(key: _askedKey) == null) {
        await storage.write(key: _askedKey, value: 'true');
        settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      }
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await ApiService().updateFcmToken(token);
      _tokenSub ??= messaging.onTokenRefresh.listen((t) => ApiService().updateFcmToken(t));
    } catch (e) {
      debugPrint('Push register error: $e');
    }
  }

  /// Whether the phone lets this app show alerts.
  static Future<bool> systemAllowed() async {
    if (!_initialised) await init();
    if (!_initialised) return false;
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      return s.authorizationStatus == AuthorizationStatus.authorized || s.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Ask again from the Notifications screen (the phone may only show its prompt once).
  static Future<bool> requestAgain() async {
    if (!_initialised) await init();
    if (!_initialised) return false;
    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      await register(askIfNeeded: false);
    } catch (_) {}
    return systemAllowed();
  }
}
