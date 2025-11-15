// lib/screens/nav/goat/modals/options/change_status_option.dart

import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/common/ui_helpers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChangeStatusOption {
  // 🔧 MODIFIED: Defined separate status lists
  static final List<String> _allStatuses = [
    'Healthy',
    'Sick',
    'Breeding',
    'Lactating',
    'Pregnant',
    'Lactating & Pregnant',
    'Sold',
    'Mortality',
    'Lost',
  ];

  static final List<String> _maleStatuses = [
    'Healthy',
    'Sick',
    'Breeding',
    'Sold',
    'Mortality',
    'Lost',
  ];

  static void show(BuildContext context, Goat goat, VoidCallback? onGoatUpdated) {
    // ✨ NEW: Dynamically select the list of statuses based on sex
    final List<String> statusesForSex =
    goat.sex == 'Male' ? _maleStatuses : _allStatuses;

    // ✨ NEW: Ensure the initial selection is valid for the sex
    String selectedStatus;
    if (goat.status.isNotEmpty && statusesForSex.contains(goat.status)) {
      selectedStatus = goat.status;
    } else {
      selectedStatus = statusesForSex.first; // Default to 'Healthy'
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to update the selected status state
            void updateSelectedStatus(String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedStatus = newValue;
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
                    _buildCurrentStatusInfo(goat),
                    const SizedBox(height: 20),
                    // 🔧 MODIFIED: Pass the dynamic list and update function
                    _buildStatusSelector(
                      statusesForSex,
                      selectedStatus,
                      updateSelectedStatus,
                    ),
                    const SizedBox(height: 24),
                    _buildActionButtons(
                      context,
                      goat,
                      selectedStatus,
                      onGoatUpdated,
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
            color: AppColors.vibrantGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.swap_horiz,
            color: AppColors.vibrantGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Change goat Status',
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

  static Widget _buildCurrentStatusInfo(Goat goat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          _getStatusIcon(goat.status),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Current status for this ',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins' // Ensure font matches
                ),
                children: [
                  TextSpan(
                    text: '${goat.sex}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: goat.status.isEmpty ? 'Not set' : goat.status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _getStatusIcon(goat.status).color,
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

  // 🔧 MODIFIED: Function now accepts a list of statuses and a callback
  static Widget _buildStatusSelector(
      List<String> statuses,
      String selectedStatus,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select new status:',
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
              value: selectedStatus,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins' // Ensure font matches
              ),
              // 🔧 MODIFIED: Use the passed 'statuses' list
              items: statuses.map((String status) {
                final isSelected = status == selectedStatus;
                return DropdownMenuItem<String>(
                  value: status,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        _getStatusIcon(status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            status,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.vibrantGreen,
                            size: 18,
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
      Goat goat,
      String selectedStatus,
      VoidCallback? onGoatUpdated,
      ) {
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
          onPressed: selectedStatus == goat.status
              ? null
              : () async {
            await _updateGoatStatus(
                context, goat, selectedStatus, onGoatUpdated);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.vibrantGreen,
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

  static Icon _getStatusIcon(String status) {
    IconData iconData;
    Color iconColor;

    switch (status.toLowerCase()) {
      case 'healthy':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'sick':
        iconData = FontAwesomeIcons.virus;
        iconColor = Colors.red;
        break;
      case 'pregnant':
        iconData = Icons.pregnant_woman_rounded;
        iconColor = Colors.purple;
        break;
      case 'breeding':
        iconData = Icons.favorite_rounded;
        iconColor = Colors.pink;
        break;
      case 'lactating':
        iconData = FontAwesomeIcons.jugDetergent;
        iconColor = Colors.cyan;
        break;
      case 'lactating & pregnant':
        iconData = Icons.double_arrow_rounded;
        iconColor = Colors.deepPurple;
        break;
      case 'sold':
        iconData = FontAwesomeIcons.moneyBill;
        iconColor = AppColors.gold;
        break;
      case 'mortality':
        iconData = FontAwesomeIcons.bookSkull;
        iconColor = Colors.redAccent;
        break;
      case 'lost':
        iconData = FontAwesomeIcons.magnifyingGlass;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.circle_outlined;
        iconColor = Colors.grey;
    }

    return Icon(iconData, size: 18, color: iconColor);
  }

  static Future<void> _updateGoatStatus(
      BuildContext context,
      Goat goat,
      String newStatus,
      VoidCallback? onGoatUpdated,
      ) async {
    UIHelpers.showEnhancedLoadingDialog(
        context, 'Updating goat status...', Icons.sync);

    try {
      final updateData = {
        'id': goat.id,
        'status': newStatus,
      };

      final success = await GoatService.updateGoatInformation(updateData);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (success) {
        // Close the status selection form modal
        if (!context.mounted) return;
        Navigator.pop(context);
        
        if (!context.mounted) return;
        UIHelpers.showEnhancedSnackbar(
          context,
          Icons.swap_horiz,
          'goat status updated to $newStatus',
          AppColors.vibrantGreen,
          isSuccess: true,
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          onGoatUpdated?.call();
        });
      } else {
        if (!context.mounted) return;
        UIHelpers.showErrorDialog(
          context,
          'Update Failed',
          'Failed to update goat status. Please check your connection and try again.',
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
        'An error occurred while updating goat status: ${e.toString()}',
      );
    }
  }
}
