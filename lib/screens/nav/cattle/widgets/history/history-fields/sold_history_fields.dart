// lib/screens/nav/cattle/widgets/event_fields/sold_event_fields.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';
import '../history_styled_text_field.dart';

class SoldEventFields extends BaseEventFields {
  const SoldEventFields({
    super.key,
    required super.controllers,
  });

  @override
  SoldEventFieldsState createState() => SoldEventFieldsState();
}

class SoldEventFieldsState extends BaseEventFieldsState<SoldEventFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: TextFormField(
            controller: widget.controllers['sold_amount'] ?? TextEditingController(),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _NumberInputFormatter(),
            ],
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Sale Amount',
              hintText: 'Enter the amount received from the sale',
              prefixIcon: Icon(FontAwesomeIcons.pesoSign, color: Colors.green, size: 20),
              labelStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Sale amount is required';
              }
              // Remove commas and validate that it's a valid number
              final cleanValue = value.replaceAll(',', '');
              final amount = double.tryParse(cleanValue);
              if (amount == null || amount < 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        HistoryStyledTextField(
          label: 'Buyer',
          controller: widget.controllers['buyer'] ?? TextEditingController(),
          hint: 'Enter buyer name or information',
          icon: FontAwesomeIcons.user,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Buyer information is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _NumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // If empty, return as is
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Convert to number and format with commas
    int number = int.parse(newText);
    String formatted = _formatNumber(number);
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
  String _formatNumber(int number) {
    String numberStr = number.toString();
    String result = '';
    
    for (int i = 0; i < numberStr.length; i++) {
      if (i > 0 && (numberStr.length - i) % 3 == 0) {
        result += ',';
      }
      result += numberStr[i];
    }
    
    return result;
  }
}

