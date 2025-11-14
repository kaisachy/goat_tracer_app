// lib/screens/nav/profile/modals/educational_background_modal.dart
import 'package:flutter/material.dart';
import 'package:goat_tracer_app/services/profile/educational_background_service.dart';
import 'package:goat_tracer_app/screens/nav/profile/modals/education_form_modal.dart';

import '../../../../constants/app_colors.dart';

class EducationalBackgroundModal extends StatefulWidget {
  final bool isEditingMode;
  final VoidCallback onSaveSuccess;

  const EducationalBackgroundModal({
    super.key,
    required this.isEditingMode,
    required this.onSaveSuccess,
  });

  @override
  State<EducationalBackgroundModal> createState() => _EducationalBackgroundModalState();
}

class _EducationalBackgroundModalState extends State<EducationalBackgroundModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Educational Background',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: EducationalBackgroundService.getEducationalBackground(),
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
                        trailing: widget.isEditingMode
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
          // No need to call setState here as the parent modal will be rebuilt
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
        setState(() {}); // Refresh the modal content to show the deletion
      }
    }
  }
}
