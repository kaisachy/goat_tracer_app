// lib/screens/nav/goat/modals/options/delete_option.dart

import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/common/ui_helpers.dart';

class DeleteOption {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_outlined,
                    color: Colors.red[600],
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete goat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to permanently delete this goat? This action cannot be undone and all associated data will be lost.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_forever, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _confirmDelete(BuildContext context) {
    UIHelpers.showEnhancedSnackbar(
      context,
      Icons.delete_forever,
      'goat deleted successfully',
      Colors.red[600]!,
      isSuccess: true,
    );

    // Navigate back after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }
}
