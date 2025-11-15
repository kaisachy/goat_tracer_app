// lib/screens/nav/goat/widgets/event_styled_text_field.dart

import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';

class HistoryStyledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isNumber;
  final int maxLines;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final void Function(String)? onChanged;

  const HistoryStyledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isNumber = false,
    this.maxLines = 1,
    this.hint,
    this.icon,
    this.validator,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: AppColors.lightGreen, size: 20) : null,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade50 : AppColors.lightGreen.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColors.vibrantGreen,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.red[400]!,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16,
          ),
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }
}