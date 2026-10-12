import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'api_service.dart';

/// Checks the installed version against the backend's version settings on launch.
/// Below min_version → blocking update screen. Below latest_version → optional prompt.
/// Fails open: if the check can't complete, the app opens normally.
class VersionGate {
  final bool forceUpdate;
  final bool updateAvailable;
  final String storeUrl;
  final String message;
  final String installed;

  const VersionGate._(this.forceUpdate, this.updateAvailable, this.storeUrl, this.message, this.installed);
  static const VersionGate open = VersionGate._(false, false, '', '', '');

  /// Compares dotted versions: returns <0 if a < b, 0 if equal, >0 if a > b.
  static int compare(String a, String b) {
    List<int> parts(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (int i = 0; i < 3; i++) {
      final xi = i < x.length ? x[i] : 0, yi = i < y.length ? y[i] : 0;
      if (xi != yi) return xi - yi;
    }
    return 0;
  }

  static Future<VersionGate> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/api/v1/app/version'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return open;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final installed = info.version;
      final minV = (data['min_version'] ?? '0.0.0').toString();
      final latestV = (data['latest_version'] ?? '0.0.0').toString();
      final url = ((Platform.isIOS ? data['ios_store_url'] : data['android_store_url']) ?? '').toString();
      return VersionGate._(
        compare(installed, minV) < 0,
        compare(installed, latestV) < 0,
        url,
        (data['message'] ?? '').toString(),
        installed,
      );
    } catch (e) {
      debugPrint('Version check skipped: $e');
      return open;
    }
  }

  Future<void> openStore() async {
    if (storeUrl.isEmpty) return;
    try {
      await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open store: $e');
    }
  }

  /// Optional "Update available" dialog. Resolves when the member chooses.
  Future<void> showOptionalPrompt(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Update available'),
        content: Text(message.isNotEmpty ? message : 'A new version of Reliance Rewards is ready with improvements to events, rewards and referrals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later', style: TextStyle(color: AppColors.textSecondary))),
          if (storeUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openStore();
              },
              child: const Text('Update', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Blocking screen shown when the installed version is below the minimum.
class UpdateRequiredScreen extends StatelessWidget {
  final VersionGate gate;
  const UpdateRequiredScreen({Key? key, required this.gate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(color: UiColors.goldBg, shape: BoxShape.circle),
                  child: const Icon(Icons.system_update_rounded, color: AppColors.primaryGold, size: 40),
                ),
                const SizedBox(height: 24),
                Text('Update required', style: AppTextStyles.h2),
                const SizedBox(height: 12),
                Text(
                  gate.message.isNotEmpty
                      ? gate.message
                      : 'This version of Reliance Rewards is no longer supported. Please update to keep earning and redeeming points.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 32),
                if (gate.storeUrl.isNotEmpty)
                  SizedBox(width: double.infinity, child: FilledAction(text: 'Update now', onPressed: gate.openStore))
                else
                  Text('Open the ${Platform.isIOS ? 'App Store' : 'Play Store'} to update.', style: AppTextStyles.labelMedium),
                const SizedBox(height: 16),
                Text('Installed version ${gate.installed}', style: AppTextStyles.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
