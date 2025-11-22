// lib/screens/nav/profile/modals/educational_background_modal.dart
import 'package:flutter/material.dart';
import 'package:goat_tracer_app/services/profile/educational_background_service.dart';
import 'package:goat_tracer_app/screens/nav/profile/modals/education_form_modal.dart';

import '../../../../constants/app_colors.dart';

class EducationalBackgroundModal extends StatefulWidget {
  final bool isEditingMode;
  final VoidCallback onSaveSuccess;
  final VoidCallback onToggleEditMode;

  const EducationalBackgroundModal({
    super.key,
    required this.isEditingMode,
    required this.onSaveSuccess,
    required this.onToggleEditMode,
  });

  @override
  State<EducationalBackgroundModal> createState() => _EducationalBackgroundModalState();
}

class _EducationalBackgroundModalState extends State<EducationalBackgroundModal> {
  bool _localEditingMode = false;
  late Future<List<Map<String, dynamic>>> _educationFuture;

  @override
  void initState() {
    super.initState();
    _localEditingMode = widget.isEditingMode;
    _educationFuture = EducationalBackgroundService.getEducationalBackground();
  }

  void _reloadEducationData() {
    setState(() {
      _educationFuture = EducationalBackgroundService.getEducationalBackground();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop && _localEditingMode) {
          // Exit edit mode when modal is closed
          widget.onToggleEditMode();
        }
      },
      child: Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _educationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final educationList = snapshot.data ?? [];
                const levels = ['Elementary', 'Secondary', 'Vocational', 'College', 'Graduate'];

                return ListView.builder(
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    final eduMap = educationList.firstWhere(
                          (edu) => (edu['level'] as String?)?.toLowerCase() == level.toLowerCase(),
                      orElse: () => {},
                    );

                    // Handle year display properly
                    String? yearDisplay;
                    if (eduMap.isNotEmpty && eduMap['year_graduated'] != null) {
                      final year = eduMap['year_graduated'].toString();
                      if (year.isNotEmpty && year != '0' && year != '0000') {
                        yearDisplay = 'Graduated: $year';
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.lightGreen.withValues(alpha: 0.2),
                          child: const Icon(Icons.school, color: AppColors.primary),
                        ),
                        title: Text(level, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: eduMap.isNotEmpty
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eduMap['school_name'] ?? 'N/A'),
                            if (yearDisplay != null) Text(yearDisplay),
                          ],
                        )
                            : const Text('Not specified'),
                        trailing: _localEditingMode
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // MODIFIED: Delete icon is now first
                            if (eduMap.isNotEmpty && eduMap['id'] != null)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(context, eduMap, level),
                                tooltip: 'Delete',
                              ),
                            // MODIFIED: Edit icon is now second
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                // Pop this modal before showing the form modal
                                Navigator.pop(context);
                                _showEducationFormModal(context, level: level, eduMap: eduMap);
                              },
                              tooltip: eduMap.isNotEmpty ? 'Edit' : 'Add',
                            ),
                          ],
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.school,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Educational Background',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _localEditingMode ? 'Edit your education records' : 'View your academic achievements',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: _localEditingMode ? 'Exit Edit Mode' : 'Edit',
          child: GestureDetector(
            onTap: () {
              setState(() {
                _localEditingMode = !_localEditingMode;
              });
              widget.onToggleEditMode();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _localEditingMode ? Colors.green : AppColors.accent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _localEditingMode ? Icons.check_rounded : Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEducationFormModal(BuildContext context, {
    required String level,
    Map<String, dynamic>? eduMap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EducationFormModal(
        level: level,
        eduMap: eduMap,
        onSaveSuccess: () {
          widget.onSaveSuccess();
          _reloadEducationData(); // Reload data to show updated information
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> eduMap, String level) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete $level Record'),
          content: const Text('Are you sure you want to delete this education record? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                await _deleteEducation(eduMap['id']);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEducation(int id) async {
    final success = await EducationalBackgroundService.deleteEducationalBackground(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Education record deleted successfully!'
              : 'Failed to delete record. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        widget.onSaveSuccess();
        _reloadEducationData(); // Reload data to show the deletion
      }
    }
  }
}
