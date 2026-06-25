import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final bool isLocked;
  final TextInputType keyboardType;
  final String? initialValue;
  final TextAlign textAlign;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final bool obscureText;

  const CustomTextField({
    Key? key,
    required this.label,
    this.isRequired = false,
    this.isLocked = false,
    this.keyboardType = TextInputType.text,
    this.initialValue,
    this.textAlign = TextAlign.start,
    this.controller,
    this.onChanged,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*
        Text(
          isRequired ? '\$label *' : label,
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        */
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          initialValue: controller == null ? initialValue : null,
          readOnly: isLocked,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textAlign: textAlign,
          decoration: InputDecoration(
            hintText: isRequired ? '\$label *' : label,
            hintStyle: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.normal),
            suffixIcon: isLocked 
                ? const Icon(Icons.lock, color: AppColors.errorRed, size: 20)
                : null,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
          ),
        ),
      ],
    );
  }
}
