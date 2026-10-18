import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Kept so existing screens can still say what kind of page is loading (no longer drawn).
enum SkeletonLayout { home, list, cards, form }

/// Friendly loading state: the pulsing gold "R" plus a short message. If loading takes a
/// while (the server can take ~30s to wake up), the message changes to explain the wait.
class FriendlyLoader extends StatefulWidget {
  final String message;
  final SkeletonLayout layout;
  const FriendlyLoader({Key? key, this.message = 'Loading…', this.layout = SkeletonLayout.list}) : super(key: key);

  @override
  State<FriendlyLoader> createState() => _FriendlyLoaderState();
}

class _FriendlyLoaderState extends State<FriendlyLoader> {
  static const _slowMessages = [
    'Still working on it — this can take up to 30 seconds the first time.',
    'Almost there. Thanks for your patience!',
  ];

  Timer? _timer;
  int _stage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && _stage < _slowMessages.length) setState(() => _stage++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _stage == 0 ? widget.message : _slowMessages[_stage - 1];
    // The brand's gold "R", gently pulsing, with a short message underneath.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pageMargin * 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const BrandPulse(size: 88),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(message, key: ValueKey(message), textAlign: TextAlign.center, style: AppTextStyles.labelMedium),
          ),
        ]),
      ),
    );
  }
}

/// The full Reliiance Rewards logo (gold "R" and wordmark), for the splash and sign-in screens.
class BrandLogo extends StatelessWidget {
  final double width;
  const BrandLogo({Key? key, this.width = 260}) : super(key: key);

  static const asset = 'assets/images/logo_full.png';

  @override
  Widget build(BuildContext context) =>
      Image.asset(asset, width: width, fit: BoxFit.contain, semanticLabel: 'Reliiance Rewards');
}

/// The gold "R" from the Reliiance Rewards logo, breathing in and out — the app's loading mark.
class BrandPulse extends StatefulWidget {
  final double size;
  const BrandPulse({Key? key, this.size = 88}) : super(key: key);

  static const asset = 'assets/images/logo_r.png';

  @override
  State<BrandPulse> createState() => _BrandPulseState();
}

class _BrandPulseState extends State<BrandPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: 0.55 + 0.45 * _t.value,
        child: Transform.scale(scale: 0.92 + 0.08 * _t.value, child: child),
      ),
      child: Container(
        width: widget.size * 1.5,
        height: widget.size * 1.5,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primaryGold.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: 4)],
        ),
        child: Image.asset(
          BrandPulse.asset,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.star_rounded, color: AppColors.primaryGold, size: widget.size * 0.7),
        ),
      ),
    );
  }
}

/// Friendly "couldn't load" state with a retry button, used instead of an empty screen.
class LoadErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const LoadErrorView({Key? key, this.message = 'We couldn\'t load this right now.', required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        children: [
          const SizedBox(height: 80),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: UiColors.goldBg, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, color: AppColors.primaryGold, size: 32),
          ),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.h3.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text('Check your internet connection and try again.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          Center(child: SizedBox(width: 180, child: FilledAction(text: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry))),
        ],
      );
}
