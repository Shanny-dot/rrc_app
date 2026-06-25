import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? (isPrimary ? AppColors.primaryGold : AppColors.backgroundBase),
          foregroundColor: textColor ?? (isPrimary ? AppColors.backgroundBase : AppColors.primaryGold),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
            side: isPrimary 
                ? BorderSide.none 
                : const BorderSide(color: AppColors.primaryGold, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? (isPrimary ? AppColors.backgroundBase : AppColors.primaryGold),
          ),
        ),
      ),
    );
  }
}
