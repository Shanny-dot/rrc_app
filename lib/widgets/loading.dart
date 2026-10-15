import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Placeholder layouts shown while a screen loads, shaped like the content that's coming.
enum SkeletonLayout { home, list, cards, form }

/// Friendly loading state: pulsing placeholders in the shape of the screen, plus a short
/// message. If loading takes a while (the server can take ~30s to wake up), the message
/// changes to explain the wait instead of leaving the member staring at a spinner.
class FriendlyLoader extends StatefulWidget {
  final String message;
  final SkeletonLayout layout;
  const FriendlyLoader({Key? key, this.message = 'Loading…', this.layout = SkeletonLayout.list}) : super(key: key);

  @override
  State<FriendlyLoader> createState() => _FriendlyLoaderState();
}

class _FriendlyLoaderState extends State<FriendlyLoader> with SingleTickerProviderStateMixin {
  static const _slowMessages = [
    'Still working on it — this can take up to 30 seconds the first time.',
    'Almost there. Thanks for your patience!',
  ];

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _stage == 0 ? widget.message : _slowMessages[_stage - 1];
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 16, AppDimens.pageMargin, 24),
      children: [
        Row(children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGold)),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(message, key: ValueKey(message), style: AppTextStyles.labelMedium),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        FadeTransition(
          opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
          child: _skeleton(widget.layout),
        ),
      ],
    );
  }

  Widget _skeleton(SkeletonLayout layout) {
    switch (layout) {
      case SkeletonLayout.home:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            _Block(width: 48, height: 48, radius: 24),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Block(width: 90, height: 12),
              SizedBox(height: 8),
              _Block(width: 130, height: 18),
            ]),
          ]),
          const SizedBox(height: 20),
          const _Block(height: 170, radius: 20),
          const SizedBox(height: 16),
          const Row(children: [
            Expanded(child: _Block(height: 92)),
            SizedBox(width: 12),
            Expanded(child: _Block(height: 92)),
            SizedBox(width: 12),
            Expanded(child: _Block(height: 92)),
          ]),
          const SizedBox(height: 28),
          const _Block(width: 140, height: 18),
          const SizedBox(height: 14),
          for (int i = 0; i < 3; i++) ...[const _Block(height: 72), const SizedBox(height: 12)],
        ]);
      case SkeletonLayout.cards:
        return Column(children: [
          for (int i = 0; i < 3; i++) ...[const _Block(height: 200), const SizedBox(height: 16)],
        ]);
      case SkeletonLayout.form:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (int i = 0; i < 5; i++) ...[
            const _Block(width: 110, height: 12),
            const SizedBox(height: 8),
            const _Block(height: 56, radius: 10),
            const SizedBox(height: 16),
          ],
        ]);
      case SkeletonLayout.list:
        return Column(children: [
          for (int i = 0; i < 6; i++) ...[const _Block(height: 76), const SizedBox(height: 12)],
        ]);
    }
  }
}

class _Block extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _Block({this.width, required this.height, this.radius = AppDimens.radiusCard});

  @override
  Widget build(BuildContext context) => Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(radius)),
      );
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
