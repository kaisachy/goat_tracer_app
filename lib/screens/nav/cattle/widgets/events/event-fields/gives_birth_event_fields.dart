// lib/screens/nav/cattle/widgets/event_fields/gives_birth_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../../constants/app_colors.dart';
import '../../../modals/calf_registration_dialog.dart';
import 'base_event_fields.dart';

class GivesBirthEventFields extends BaseEventFields {
  final String? cattleTag;
  final Map<String, dynamic>? temporaryCalfData;
  final VoidCallback? onEditCalfPressed;
  final Function(Map<String, dynamic>?) onCalfDataChanged;

  const GivesBirthEventFields({
    super.key,
    required super.controllers,
    this.cattleTag,
    this.temporaryCalfData,
    this.onEditCalfPressed,
    required this.onCalfDataChanged,
  });

  @override
  GivesBirthEventFieldsState createState() => GivesBirthEventFieldsState();
}

class GivesBirthEventFieldsState extends BaseEventFieldsState<GivesBirthEventFields> {
  Map<String, dynamic>? _newCalfData;

  @override
  bool needsBulls() => true;

  @override
  void initState() {
    super.initState();
    _newCalfData = widget.temporaryCalfData;
  }

  @override
  void didUpdateWidget(GivesBirthEventFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.temporaryCalfData != oldWidget.temporaryCalfData) {
      setState(() {
        _newCalfData = widget.temporaryCalfData;
      });
    }
  }

  Future<void> _showCalfRegistrationDialog() async {
    // Use the callback from parent if provided (for edit mode)
    if (widget.onEditCalfPressed != null) {
      widget.onEditCalfPressed!();
      return; // Parent will handle opening the dialog
    }

    // Fallback - open dialog directly if no callback provided
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalfRegistrationDialog(
        motherTag: widget.cattleTag ?? '',
        fatherTag: widget.controllers['bull_tag']?.text ?? '',
        existingCalfData: _newCalfData?['fullCalfData'] ?? _newCalfData,
        isEditMode: _newCalfData != null,
      ),
    );

    if (result != null) {
      setState(() {
        _newCalfData = result;
        widget.controllers['calf_tag']?.text = result['tag_no'] ?? '';
      });
      widget.onCalfDataChanged(result);
    }
  }

  Widget _buildCalfRegistrationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.lightGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.baby, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Calf Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _showCalfRegistrationDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    _newCalfData == null ? 'Add Calf' : 'Edit Calf',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
          if (_newCalfData != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightGreen.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.label, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tag: ${_newCalfData!['tag_no'] ?? 'Not set'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_newCalfData!['name'] != null && _newCalfData!['name'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.signature, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Name: ${_newCalfData!['name']}',
                            style: const TextStyle(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        _newCalfData!['gender'] == 'Male' ? Icons.male : Icons.female,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gender: ${_newCalfData!['gender'] ?? 'Not set'}',
                          style: const TextStyle(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildBullDropdown(),
        _buildCalfRegistrationField(),
      ],
    );
  }
}