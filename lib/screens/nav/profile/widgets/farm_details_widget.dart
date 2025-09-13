// lib/screens/nav/profile/widgets/farm_details_widget.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/farm_details_service.dart';
import 'package:cattle_tracer_app/screens/nav/profile/modals/farm_details_modal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../constants/app_colors.dart';

class FarmDetailsWidget extends StatelessWidget {
  final bool isEditingMode;
  final VoidCallback onRefresh;

  const FarmDetailsWidget({
    super.key,
    required this.isEditingMode,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FarmDetailsService.getFarmDetails(),
      builder: (context, snapshot) {
        final farmDetails = snapshot.data;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _showFarmDetailsModal(context, farmDetails),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FontAwesomeIcons.seedling, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farm Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Farm information and classification',
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

  void _showFarmDetailsModal(BuildContext context, Map<String, dynamic>? farmDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FarmDetailsModal(
        farmDetails: farmDetails,
        isEditingMode: isEditingMode,
        onSaveSuccess: onRefresh,
      ),
    );
  }}
