// lib/screens/nav/profile/widgets/personal_information_widget.dart
import 'package:flutter/material.dart';
import 'package:goat_tracer_app/screens/nav/profile/modals/personal_information_modal.dart';

import '../../../../constants/app_colors.dart';

class PersonalInformationWidget extends StatelessWidget {
  final bool isEditingMode;
  final VoidCallback onRefresh;

  const PersonalInformationWidget({
    super.key,
    required this.isEditingMode,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showPersonalInfoModal(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Basic details and contact info',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PersonalInformationModal(
        isEditingMode: isEditingMode,
        onSaveSuccess: onRefresh,
      ),
    );
  }
}
