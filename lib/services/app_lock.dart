import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Optional Face ID / fingerprint lock. The member's sign-in token stays in secure storage;
/// when the lock is on, opening the app (or returning after a few minutes away) asks for
/// Face ID, fingerprint or the phone's passcode before showing their account.
class AppLock {
  static const _enabledKey = 'biometric_lock_enabled';
  static const _offeredKey = 'biometric_lock_offered';
  static const relockAfter = Duration(minutes: 2);

  static final _auth = LocalAuthentication();
  static bool _authenticating = false;

  static Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// "Face ID" on iPhones with it, otherwise "fingerprint" (or a neutral name).
  static Future<String> label() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (Platform.isIOS && types.contains(BiometricType.face)) return 'Face ID';
      if (Platform.isIOS) return 'Touch ID';
      if (types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong)) return 'fingerprint';
      if (types.contains(BiometricType.face)) return 'face unlock';
    } catch (_) {}
    return 'biometrics';
  }

  static Future<bool> isEnabled() async {
    try {
      return await ApiService().storage.read(key: _enabledKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    try {
      await ApiService().storage.write(key: _enabledKey, value: enabled ? 'true' : 'false');
    } catch (_) {}
  }

  static Future<bool> authenticate(String reason) async {
    if (_authenticating) return false;
    _authenticating = true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    } finally {
      _authenticating = false;
    }
  }

  static bool get isAuthenticating => _authenticating;

  /// Asks once, after sign-in, whether the member wants to use Face ID / fingerprint.
  static Future<void> offerOnce(BuildContext context) async {
    try {
      final storage = ApiService().storage;
      if (await storage.read(key: _offeredKey) != null || await isEnabled() || !await isAvailable()) return;
      await storage.write(key: _offeredKey, value: 'true');
    } catch (_) {
      return;
    }
    final name = await label();
    if (!context.mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Use $name?', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Keep your points safe and open the app quickly with $name. You can change this any time in your profile.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn on', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (yes == true && await authenticate('Confirm it\'s you to turn on $name')) {
      await setEnabled(true);
      if (context.mounted) showToast(context, '$name is on.');
    }
  }
}

/// Full-screen lock shown before the member's account. Prompts straight away; if they
/// cancel, they can try again or sign in with their password instead.
class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback onUsePassword;
  const AppLockScreen({Key? key, required this.onUnlocked, required this.onUsePassword}) : super(key: key);

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _label = 'Face ID';

  @override
  void initState() {
    super.initState();
    AppLock.label().then((l) {
      if (mounted) setState(() => _label = l);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (await AppLock.authenticate('Unlock Reliance Rewards')) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.pageMargin),
            child: Column(
              children: [
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/rrc_logo.png', width: 96, height: 96, fit: BoxFit.cover),
                ),
                const SizedBox(height: 28),
                Text('Welcome back', style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text('Unlock with $_label to see your points.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledAction(
                    text: 'Unlock with $_label',
                    icon: _label == 'Face ID' ? Icons.face_retouching_natural : Icons.fingerprint_rounded,
                    onPressed: _unlock,
                  ),
                ),
                TextButton(
                  onPressed: widget.onUsePassword,
                  child: Text('Use password instead', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
