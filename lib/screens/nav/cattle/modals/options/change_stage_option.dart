// lib/screens/nav/cattle/modals/options/change_stage_option.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/common/ui_helpers.dart';

class ChangeStageOption {
  // 🔧 MODIFIED: Defined separate, gender-specific stage lists
  static final List<String> _maleStages = ['Calf', 'Growers', 'Bull', 'Steer'];
  static final List<String> _femaleStages = ['Calf', 'Growers', 'Heifer', 'Cow'];
  static final List<String> _allStages = [
    'Calf', 'Growers', 'Heifer', 'Cow', 'Bull', 'Steer'
  ];

  static void show(BuildContext context, Cattle cattle, VoidCallback? onCattleUpdated) {
    // ✨ NEW: Dynamically select the list of stages based on sex
    List<String> stagesForSex;
    if (cattle.sex == 'Male') {
      stagesForSex = _maleStages;
    } else if (cattle.sex == 'Female') {
      stagesForSex = _femaleStages;
    } else {
      // Fallback for unknown or other sexes
      stagesForSex = _allStages;
    }

    // ✨ NEW: Ensure the initial selection is valid for the sex
    String selectedStage;
    if (cattle.classification.isNotEmpty && stagesForSex.contains(cattle.classification)) {
      selectedStage = cattle.classification;
    } else {
      selectedStage = stagesForSex.first;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to update the selected stage state
            void updateSelectedStage(String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedStage = newValue;
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 16,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  minWidth: 300,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildCurrentStageInfo(cattle),
                    const SizedBox(height: 20),
                    // 🔧 MODIFIED: Pass the dynamic list and the update function
                    _buildStageSelector(
                      stagesForSex,
                      selectedStage,
                      updateSelectedStage,
                    ),
                    const SizedBox(height: 24),
                    _buildActionButtons(
                      context,
                      cattle,
                      selectedStage,
                      onCattleUpdated,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            FontAwesomeIcons.arrowUpRightFromSquare,
            color: AppColors.lightGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Change Cattle Stage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildCurrentStageInfo(Cattle cattle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            cattle.sex == 'Male' ? Icons.male : (cattle.sex == 'Female' ? Icons.female : Icons.transgender),
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Current stage for this ',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins' // Ensure font matches
                ),
                children: [
                  TextSpan(
                    text: '${cattle.sex}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: cattle.classification.isEmpty
                        ? 'Not set'
                        : cattle.classification,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 MODIFIED: Function now accepts a list of stages and a callback
  static Widget _buildStageSelector(
      List<String> stages,
      String selectedStage,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select new stage:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStage,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Poppins', // Ensure font matches
                color: AppColors.textPrimary,
              ),
              // 🔧 MODIFIED: Use the passed 'stages' list
              items: stages.map((String stage) {
                final isSelected = stage == selectedStage;
                return DropdownMenuItem<String>(
                  value: stage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.lightGreen,
                            size: 18,
                          )
                        else
                        // Use an empty box to maintain alignment
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(
                          stage,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildActionButtons(
      BuildContext context,
      Cattle cattle,
      String selectedStage,
      VoidCallback? onCattleUpdated) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: selectedStage == cattle.classification
              ? null
              : () async {
            await _updateCattleStage(
                context, cattle, selectedStage, onCattleUpdated);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.save, size: 16),
              SizedBox(width: 6),
              Text(
                'Save',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _updateCattleStage(
      BuildContext context,
      Cattle cattle,
      String newStage,
      VoidCallback? onCattleUpdated) async {
    UIHelpers.showEnhancedLoadingDialog(
        context, 'Updating cattle stage...', Icons.update);

    try {
      final updateData = {
        'id': cattle.id,
        'classification': newStage,
      };

      final success = await CattleService.updateCattleInformation(updateData);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (success) {
        // Close the stage selection form modal
        if (!context.mounted) return;
        Navigator.pop(context);
        
        if (!context.mounted) return;
        UIHelpers.showEnhancedSnackbar(
          context,
          FontAwesomeIcons.arrowUpRightFromSquare,
          'Cattle stage updated to $newStage',
          AppColors.lightGreen,
          isSuccess: true,
        );

        // A small delay can feel smoother before the UI refresh
        Future.delayed(const Duration(milliseconds: 300), () {
          onCattleUpdated?.call();
        });
      } else {
        if (!context.mounted) return;
        UIHelpers.showErrorDialog(
          context,
          'Update Failed',
          'Failed to update cattle stage. Please check your connection and try again.',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!context.mounted) return;
      UIHelpers.showErrorDialog(
        context,
        'Update Error',
        'An error occurred while updating cattle stage: ${e.toString()}',
      );
    }
  }

  
}
