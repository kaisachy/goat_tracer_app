// lib/screens/nav/cattle/modals/options/archive_option.dart

import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/common/ui_helpers.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_history_form_screen.dart';

class ArchiveOption {
  static void show(BuildContext context, {required Cattle cattle, VoidCallback? onCattleUpdated}) {
    _showArchiveOptions(context, cattle: cattle, onCattleUpdated: onCattleUpdated);
  }

  static void _showArchiveOptions(BuildContext context, {required Cattle cattle, VoidCallback? onCattleUpdated}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Archive Reason',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select why you want to archive this cattle',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildArchiveOption(
              context,
              icon: Icons.sell_outlined,
              title: 'Sold',
              subtitle: 'Cattle has been sold',
              color: AppColors.gold,
              onTap: () {
                Navigator.pop(context);
                _archiveAsSold(context, cattle: cattle, onCattleUpdated: onCattleUpdated);
              },
            ),
            _buildArchiveOption(
              context,
              icon: Icons.dangerous_outlined,
              title: 'Deceased',
              subtitle: 'Cattle has passed away',
              color: Colors.red[600]!,
              onTap: () {
                Navigator.pop(context);
                _archiveAsDeceased(context, cattle: cattle, onCattleUpdated: onCattleUpdated);
              },
            ),
            _buildArchiveOption(
              context,
              icon: Icons.location_off_outlined,
              title: 'Lost',
              subtitle: 'Cattle is missing or lost',
              color: Colors.orange[600]!,
              onTap: () {
                Navigator.pop(context);
                _archiveAsLost(context, cattle: cattle, onCattleUpdated: onCattleUpdated);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildArchiveOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _archiveAsSold(BuildContext context, {required Cattle cattle, VoidCallback? onCattleUpdated}) async {
    // Navigate to event form with "Sold" pre-selected
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CattleHistoryFormScreen(
          cattleTag: cattle.tagNo,
          initialHistoryType: 'Sold',
        ),
      ),
    );

    // If event was successfully created, archive the cattle
    if (result == true) {
      try {
        final success = await CattleService.archiveCattle(cattle.id, 'Sold');
        
        if (success) {
          UIHelpers.showEnhancedSnackbar(
            context,
            Icons.sell,
            'Sold event created and cattle archived',
            AppColors.gold,
            isSuccess: true,
          );
          onCattleUpdated?.call();
        } else {
          UIHelpers.showEnhancedSnackbar(
            context,
            Icons.error,
            'Event created but failed to archive cattle',
            Colors.red[600]!,
            isSuccess: false,
          );
        }
      } catch (e) {
        UIHelpers.showEnhancedSnackbar(
          context,
          Icons.error,
          'Error archiving cattle: $e',
          Colors.red[600]!,
          isSuccess: false,
        );
      }
    }
  }

  static void _archiveAsDeceased(BuildContext context, {required Cattle cattle, VoidCallback? onCattleUpdated}) async {
    // Navigate to event form with "Deceased" pre-selected
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CattleHistoryFormScreen(
          cattleTag: cattle.tagNo,
          initialHistoryType: 'Deceased',
        ),
      ),
    );

    // If event was successfully created, archive the cattle
    if (result == true) {
      try {
        final success = await CattleService.archiveCattle(cattle.id, 'Deceased');
        
        if (success) {
          UIHelpers.showEnhancedSnackbar(
            context,
            Icons.dangerous,
            'Deceased event created and cattle archived',
            Colors.red[600]!,
            isSuccess: true,
          );
          onCattleUpdated?.call();
        } else {
          UIHelpers.showEnhancedSnackbar(
            context,
            Icons.error,
            'Event created but failed to archive cattle',
            Colors.red[600]!,
            isSuccess: false,
          );
        }
      } catch (e) {
        UIHelpers.showEnhancedSnackbar(
          context,
          Icons.error,
          'Error archiving cattle: $e',
          Colors.red[600]!,
          isSuccess: false,
        );
      }
    }
  }

  static void _archiveAsLost(BuildContext context, {required Cattle cattle, VoidCallback? onCattleUpdated}) async {
    // Navigate to event form with "Lost" pre-selected
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CattleHistoryFormScreen(
          cattleTag: cattle.tagNo,
          initialHistoryType: 'Lost',
        ),
      ),
    );

    // If event was successfully created, archive the cattle
    if (result == true) {
      try {
        final success = await CattleService.archiveCattle(cattle.id, 'Lost');
        
        if (success) {
          UIHelpers.showEnhancedSnackbar(
            context,
            Icons.location_off,
            'Lost event created and cattle archived',
            Colors.orange[600]!,
            isSuccess: true,
          );
          onCattleUpdated?.call();
        } else {
          UIHelpers.showEnhancedSnackbar(
            context,
            Icons.error,
            'Event created but failed to archive cattle',
            Colors.red[600]!,
            isSuccess: false,
          );
        }
      } catch (e) {
        UIHelpers.showEnhancedSnackbar(
          context,
          Icons.error,
          'Error archiving cattle: $e',
          Colors.red[600]!,
          isSuccess: false,
        );
      }
    }
  }
}