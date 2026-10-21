import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

const _kTourSeenKey = 'welcome_tour_seen';

class _TourPage {
  final IconData icon;
  final String title;
  final String body;
  const _TourPage(this.icon, this.title, this.body);
}

const _pages = [
  _TourPage(Icons.workspace_premium_outlined, 'Welcome to Reliiance Rewards',
      'Discover exclusive rewards, experiences and benefits designed to give you more from Reliiance. Here\'s how it works.'),
  _TourPage(Icons.stars_rounded, 'Earn points',
      'Collect points when friends you refer join, when you attend Reliiance events, and with surprise bonuses along the way.'),
  _TourPage(Icons.person_add_alt_1_rounded, 'Refer in a tap',
      'Share your personal code by SMS, WhatsApp or email from the Referrals tab, then follow each friend\'s progress right here.'),
  _TourPage(Icons.card_giftcard_rounded, 'Redeem rewards',
      'Swap your points for experiences, gift cards and more in the Rewards tab. We\'ll let you know when your reward is on its way.'),
];

/// Three-to-four screen introduction shown once to new members (and replayable from Help).
class WelcomeTourScreen extends StatefulWidget {
  const WelcomeTourScreen({Key? key}) : super(key: key);

  /// Shows the tour if this member hasn't seen it and joined recently. Existing members
  /// who update the app aren't interrupted; they can still open it from Help.
  static Future<void> showIfNew(BuildContext context, Map<String, dynamic>? profile) async {
    final storage = ApiService().storage;
    try {
      if (await storage.read(key: _kTourSeenKey) != null) return;
      final joined = DateTime.tryParse((profile?['created_at'] ?? '').toString());
      final isNew = joined == null || DateTime.now().difference(joined).inDays <= 14;
      await storage.write(key: _kTourSeenKey, value: DateTime.now().toIso8601String());
      if (!isNew || !context.mounted) return;
    } catch (_) {
      return;
    }
    await Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => const WelcomeTourScreen()));
  }

  @override
  State<WelcomeTourScreen> createState() => _WelcomeTourScreenState();
}

class _WelcomeTourScreenState extends State<WelcomeTourScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      Navigator.pop(context);
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(last ? '' : 'Skip', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: UiColors.goldBg,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.primaryGold.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: 4)],
                          ),
                          child: Icon(p.icon, color: AppColors.primaryGold, size: 60),
                        ),
                        const SizedBox(height: 40),
                        Text(p.title, textAlign: TextAlign.center, style: AppTextStyles.h2),
                        const SizedBox(height: 14),
                        Text(p.body, textAlign: TextAlign.center, style: AppTextStyles.bodyLarge.copyWith(height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryGold : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 28, AppDimens.pageMargin, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledAction(text: last ? 'Get started' : 'Next', onPressed: _next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
