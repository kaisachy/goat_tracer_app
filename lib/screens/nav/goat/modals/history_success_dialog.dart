// lib/screens/nav/goat/modals/event_success_dialog.dart

import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class SuccessDialog {
  static void show({
    required BuildContext context,
    required bool isEditing,
    required VoidCallback onContinue,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.vibrantGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.vibrantGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'History Record Updated!' : 'History Record Created!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isEditing
                  ? 'The goat event has been updated successfully.'
                  : 'New goat event has been created successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}