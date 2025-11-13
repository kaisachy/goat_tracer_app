// lib/screens/nav/profile/widgets/educational_background_widget.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/educational_background_service.dart';
import 'package:cattle_tracer_app/screens/nav/profile/modals/educational_background_modal.dart';

import '../../../../constants/app_colors.dart';

class EducationalBackgroundWidget extends StatelessWidget {
  final bool isEditingMode;
  final VoidCallback onRefresh;

  const EducationalBackgroundWidget({
    super.key,
    required this.isEditingMode,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: EducationalBackgroundService.getEducationalBackground(),
      builder: (context, snapshot) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _showEducationModal(context),
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
                    child: const Icon(Icons.school, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Educational Background',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Academic achievements',
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
      },
    );
  }

  void _showEducationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EducationalBackgroundModal(
        isEditingMode: isEditingMode,
        onSaveSuccess: onRefresh,
      ),
    );
  }
}
