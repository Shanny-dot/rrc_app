import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final bool isRequired;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.items,
    this.isRequired = false,
    this.value,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: isRequired ? '\$label *' : label,
        hintStyle: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.normal),
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
      value: value,
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(color: AppColors.primaryBlue)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
