import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:play_install_referrer/play_install_referrer.dart';
import 'api_service.dart';

/// The referral code of the member who invited this person, so sign-up links them without
/// typing it. Found (in order) from:
///  1. a personal invite link that opened the app: reliancerewards://join/CODE
///  2. Google Play's install referrer (Android, first launch after installing from the link)
///  3. the backend, which remembers invite links opened on this network in the last 48 hours
class InviteCode {
  static const _storeKey = 'pending_invite_code';
  static const _referrerCheckedKey = 'install_referrer_checked';
  static final _codeRe = RegExp(r'^[A-Z0-9]{4,8}$');

  static String? _code;
  static bool _fromLink = false;
  static StreamSubscription<Uri>? _sub;

  /// Called when an invite link arrives while the app is open.
  static void Function(String code)? onLinkWhileRunning;

  static String? _clean(String? raw) {
    final c = (raw ?? '').trim().toUpperCase();
    return _codeRe.hasMatch(c) ? c : null;
  }

  /// "reliancerewards://join/ABCD1234" or "https://…/join/ABCD1234"
  static String? codeFromUri(Uri uri) {
    final segments = [if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments];
    final i = segments.indexOf('join');
    return i >= 0 && i + 1 < segments.length ? _clean(segments[i + 1]) : _clean(uri.queryParameters['code']);
  }

  /// "rrc_code=ABCD1234" (the referrer the invite page adds to the Google Play link)
  static String? codeFromReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    try {
      return _clean(Uri.splitQueryString(Uri.decodeComponent(referrer))['rrc_code']);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _save(String code) async {
    _code = code;
    try {
      await ApiService().storage.write(key: _storeKey, value: code);
    } catch (_) {}
  }

  /// Starts listening for invite links. Call once at app start.
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      final links = AppLinks();
      final initial = await links.getInitialLink();
      final code = initial == null ? null : codeFromUri(initial);
      if (code != null) {
        _fromLink = true;
        await _save(code);
      }
      _sub ??= links.uriLinkStream.listen((uri) async {
        final c = codeFromUri(uri);
        if (c == null) return;
        await _save(c);
        onLinkWhileRunning?.call(c);
      });
    } catch (e) {
      debugPrint('Invite link error: $e');
    }
  }

  /// True when the app was opened from an invite link (the splash then shows sign-up).
  static bool get openedFromLink => _fromLink;

  /// The code to pre-fill on sign-up, or null.
  static Future<String?> find() async {
    if (_code != null) return _code;
    final storage = ApiService().storage;
    try {
      final stored = _clean(await storage.read(key: _storeKey));
      if (stored != null) return _code = stored;
    } catch (_) {}

    if (!kIsWeb && Platform.isAndroid) {
      try {
        if (await storage.read(key: _referrerCheckedKey) == null) {
          await storage.write(key: _referrerCheckedKey, value: 'true');
          final details = await PlayInstallReferrer.installReferrer;
          final c = codeFromReferrer(details.installReferrer);
          if (c != null) {
            await _save(c);
            return c;
          }
        }
      } catch (e) {
        debugPrint('Install referrer error: $e');
      }
    }

    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/api/v1/referrals/pending-invite'))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final c = _clean((jsonDecode(res.body) as Map)['code']?.toString());
        if (c != null) {
          await _save(c);
          return c;
        }
      }
    } catch (_) {}
    return null;
  }

  /// The code already found (no network), for social sign-in.
  static String? get current => _code;

  /// The member's account now exists; don't attach the code to anything else.
  static Future<void> clear() async {
    _code = null;
    _fromLink = false;
    try {
      await ApiService().storage.delete(key: _storeKey);
    } catch (_) {}
  }
}
