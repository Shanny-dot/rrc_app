import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Extra colours used by the redesigned screens.
class UiColors {
  static const Color green = Color(0xFF5EE59B);
  static const Color greenBg = Color(0xFF13291D);
  static const Color blue = Color(0xFF7FB2FF);
  static const Color blueBg = Color(0xFF14233B);
  static const Color goldBg = Color(0xFF2B2213);
  static const Color red = Color(0xFFFF7A7A);
  static const Color redBg = Color(0xFF2E1616);
  static const Color border = Color(0xFF2A2A2A);
  static const Color muted = Color(0xFF6E6E6E);

  /// Tinted header colours for cards without a photo (events, rewards).
  static const List<List<Color>> tints = [
    [Color(0xFF1C2F22), Color(0xFF6EE7A0)], // green
    [Color(0xFF17283F), Color(0xFF8AB8FF)], // blue
    [Color(0xFF3A2C14), Color(0xFFFAB95B)], // gold
    [Color(0xFF2A1E36), Color(0xFFC59BFF)], // purple
    [Color(0xFF252525), Color(0xFFA0A0A0)], // grey
  ];

  static List<Color> tintFor(String seed) => tints[seed.hashCode.abs() % tints.length];
}

/// Small rounded status label, e.g. "Pending", "Sent", "Points added".
class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip(this.label, {Key? key}) : super(key: key);

  static (Color, Color) colorsFor(String label) {
    switch (label.toLowerCase()) {
      case 'points added':
      case 'approved':
      case 'settled':
      case 'joined the app':
        return (UiColors.green, UiColors.greenBg);
      case 'sent':
      case 'loan in progress':
      case 'contacted':
        return (UiColors.blue, UiColors.blueBg);
      case 'refunded':
      case 'points removed':
      case 'not proceeding':
        return (UiColors.red, UiColors.redBg);
      default:
        return (AppColors.primaryGold, UiColors.goldBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = colorsFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Pill used for points on event cards: gold for the main figure, grey for the secondary one.
class InfoPill extends StatelessWidget {
  final String text;
  final bool highlight;
  const InfoPill(this.text, {Key? key, this.highlight = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? UiColors.goldBg : AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? AppColors.primaryGold : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Gold section heading ("Personal details").
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(text, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w700)),
      );
}

/// A form field with its label above it.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const LabeledField({Key? key, required this.label, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

/// Card header for items without a photo: tinted block with a centred icon.
class TintedHeader extends StatelessWidget {
  final String seed;
  final IconData icon;
  final double height;
  final String? imageUrl;
  const TintedHeader({Key? key, required this.seed, required this.icon, this.height = 120, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tint = UiColors.tintFor(seed);
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: tint[0],
      child: Center(child: Icon(icon, color: tint[1], size: 34)),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
    );
  }
}

/// Outlined secondary button matching the designs ("Add to calendar", "Invite a friend").
class OutlineAction extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  const OutlineAction({Key? key, required this.text, this.onPressed, this.color = AppColors.textPrimary, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color == AppColors.textPrimary ? UiColors.border : color, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            ],
          ),
        ),
      );
}

/// Filled gold button with the designs' 14px radius.
class FilledAction extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  const FilledAction({Key? key, required this.text, this.onPressed, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGold,
            foregroundColor: AppColors.backgroundBase,
            disabledBackgroundColor: AppColors.inputFill,
            disabledForegroundColor: AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            ],
          ),
        ),
      );
}

void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(color: Colors.white)),
    backgroundColor: error ? AppColors.error : AppColors.success,
  ));
}
