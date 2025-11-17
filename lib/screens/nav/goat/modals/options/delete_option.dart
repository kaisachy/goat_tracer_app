// lib/screens/nav/goat/modals/options/delete_option.dart

import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/common/ui_helpers.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';

class DeleteOption {
  static void show(BuildContext context, {required Goat goat, VoidCallback? onGoatDeleted}) {
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
                  'Delete Goat',
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
                          _confirmDelete(context, goat: goat, onGoatDeleted: onGoatDeleted);
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

  static Future<void> _confirmDelete(BuildContext context, {required Goat goat, VoidCallback? onGoatDeleted}) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading snackbar
    scaffoldMessenger.clearSnackBars();
    final loadingSnackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Deleting goat...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.orange[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 30),
      elevation: 8,
    );
    
    scaffoldMessenger.showSnackBar(loadingSnackBar);

    try {
      final success = await GoatService.deletegoatInformation(goat.id);
      
      if (!context.mounted) return;

      // Immediately hide the loading snackbar - clearSnackBars is the most immediate method
      scaffoldMessenger.clearSnackBars();

      if (success) {
        // Trigger refresh immediately - this will call _fetchGoat() to refresh the screen
        if (onGoatDeleted != null) {
          onGoatDeleted();
        }
        
        // No success snackbar - just disappear immediately as requested
      } else {
        // Show error snackbar only on failure
        if (context.mounted) {
          UIHelpers.showEnhancedSnackbar(
            context,
            Icons.error_outline,
            'Failed to delete goat',
            Colors.red[600]!,
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      // Forcefully remove loading snackbar
      scaffoldMessenger.clearSnackBars();
      // Show error snackbar
      UIHelpers.showEnhancedSnackbar(
        context,
        Icons.error_outline,
        'Error deleting goat: ${e.toString()}',
        Colors.red[600]!,
        isSuccess: false,
      );
    }
  }
}
