import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isTextLink;

  const GoldButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isTextLink = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isTextLink) {
      return TextButton(
        onPressed: onPressed,
        child: Text(text, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : AppColors.primaryGold,
          foregroundColor: isSecondary ? AppColors.primaryGold : AppColors.backgroundBase,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
            side: isSecondary 
                ? const BorderSide(color: AppColors.primaryGold, width: 1.5)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSecondary ? AppColors.primaryGold : AppColors.backgroundBase,
          ),
        ),
      ),
    );
  }
}

class DarkTextField extends StatelessWidget {
  final String hint;
  final bool isLocked;
  final TextInputType keyboardType;
  final String? initialValue;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextAlign textAlign;
  final TextEditingController? controller;
  final bool obscureText;
  final void Function(String)? onChanged;

  const DarkTextField({
    Key? key,
    required this.hint,
    this.isLocked = false,
    this.keyboardType = TextInputType.text,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.textAlign = TextAlign.start,
    this.controller,
    this.obscureText = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      readOnly: isLocked,
      keyboardType: keyboardType,
      textAlign: textAlign,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium,
        prefixIcon: prefixIcon,
        suffixIcon: isLocked 
            ? const Icon(Icons.lock_rounded, color: AppColors.primaryGold, size: 20)
            : suffixIcon,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
        ),
      ),
    );
  }
}

class PointsBadge extends StatelessWidget {
  final String points;
  final bool isLarge;

  const PointsBadge({Key? key, required this.points, this.isLarge = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 16 : 10, vertical: isLarge ? 8 : 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: isLarge ? 18 : 14, color: AppColors.primaryGold),
          const SizedBox(width: 4),
          Text(
            points,
            style: TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
              fontSize: isLarge ? 16 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
