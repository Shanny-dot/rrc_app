import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/push_alerts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading.dart';
import '../../widgets/ui_kit.dart';

/// Choose which phone alerts to get. Every alert also appears in the app's Updates list.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const _options = [
    ('points', Icons.stars_rounded, 'Points added', 'Referral rewards, event points and bonuses'),
    ('referrals', Icons.people_outline_rounded, 'Referral progress', 'When a friend you referred moves to the next stage'),
    ('rewards', Icons.card_giftcard_outlined, 'Rewards', 'When a reward is approved or on its way'),
    ('events', Icons.calendar_today_outlined, 'Event reminders', 'The day before events you\'re going to, and thank-yous'),
    ('expiry', Icons.hourglass_bottom_rounded, 'Points expiring', 'A heads-up before points expire'),
    ('loan', Icons.home_work_outlined, 'Loan check-ins', 'A yearly reminder to check your loan is still competitive'),
  ];

  final _api = ApiService();
  Map<String, bool>? _prefs;
  bool _systemAllowed = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final res = await _api.getNotificationPrefs();
    final allowed = await PushAlerts.systemAllowed();
    if (!mounted) return;
    setState(() {
      _systemAllowed = allowed;
      if (res['success'] == true && res['data'] is Map) {
        _prefs = (res['data'] as Map).map((k, v) => MapEntry(k.toString(), v == true));
      } else {
        _failed = true;
      }
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final previous = Map<String, bool>.from(_prefs!);
    setState(() => _prefs![key] = value);
    final res = await _api.updateNotificationPrefs({key: value});
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() => _prefs = previous);
      showToast(context, 'Couldn\'t save that change. Please try again.', error: true);
    }
  }

  Future<void> _turnOnSystem() async {
    final allowed = await PushAlerts.requestAgain();
    if (!mounted) return;
    setState(() => _systemAllowed = allowed);
    if (!allowed) {
      showToast(context, 'Alerts are off for this app in your phone\'s Settings → Notifications.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _failed
          ? LoadErrorView(message: 'We couldn\'t load your settings.', onRetry: _load)
          : _prefs == null
              ? const FriendlyLoader(message: 'Loading your settings…')
              : ListView(
                  padding: const EdgeInsets.all(AppDimens.pageMargin),
                  children: [
                    if (!_systemAllowed) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: UiColors.goldBg,
                          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Phone alerts are off', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Turn them on to hear about points, referrals and events straight away.', style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 12),
                          OutlineAction(text: 'Turn on alerts', icon: Icons.notifications_active_outlined, color: AppColors.primaryGold, onPressed: _turnOnSystem),
                        ]),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text('Choose what we alert you about. Everything still shows in Updates in the app.', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 14),
                    ..._options.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                            child: SwitchListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
                              secondary: Icon(o.$2, color: AppColors.primaryGold),
                              title: Text(o.$3, style: AppTextStyles.labelLarge),
                              subtitle: Text(o.$4, style: AppTextStyles.labelSmall),
                              value: _prefs![o.$1] ?? true,
                              activeThumbColor: AppColors.primaryGold,
                              onChanged: (v) => _toggle(o.$1, v),
                            ),
                          ),
                        )),
                  ],
                ),
    );
  }
}
