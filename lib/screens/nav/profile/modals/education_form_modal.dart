// lib/screens/nav/profile/modals/education_form_modal.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/educational_background_service.dart';

class EducationFormModal extends StatefulWidget {
  final String level;
  final Map<String, dynamic>? eduMap;
  final VoidCallback onSaveSuccess;

  const EducationFormModal({
    super.key,
    required this.level,
    required this.eduMap,
    required this.onSaveSuccess,
  });

  @override
  State<EducationFormModal> createState() => _EducationFormModalState();
}

class _EducationFormModalState extends State<EducationFormModal> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController schoolController;
  late TextEditingController courseController;
  late TextEditingController yearController;
  late TextEditingController honorsController;

  @override
  void initState() {
    super.initState();
    final eduMap = widget.eduMap;
    schoolController = TextEditingController(text: eduMap?['school_name'] ?? '');
    courseController = TextEditingController(text: eduMap?['course'] ?? '');

    // Handle year properly - don't show 0000 for empty years
    yearController = TextEditingController(
      text: (eduMap?['year_graduated'] != null &&
          eduMap!['year_graduated'].toString() != '0' &&
          eduMap['year_graduated'].toString() != '0000')
          ? eduMap['year_graduated'].toString()
          : '',
    );

    honorsController = TextEditingController(text: eduMap?['honors_received'] ?? '');
  }

  @override
  void dispose() {
    schoolController.dispose();
    courseController.dispose();
    yearController.dispose();
    honorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExistingRecord = widget.eduMap?['id'] != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit ${widget.level} Education',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isExistingRecord)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: schoolController,
                decoration: const InputDecoration(labelText: 'School'),
              ),
              TextFormField(
                controller: courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              TextFormField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Year Graduated'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final year = int.tryParse(value);
                    if (year == null) return 'Enter a valid year';
                    if (year < 1900 || year > DateTime.now().year + 5) {
                      return 'Enter a valid year between 1900-${DateTime.now().year + 5}';
                    }
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: honorsController,
                decoration: const InputDecoration(labelText: 'Honors'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEducation,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Education Record'),
          content: Text('Are you sure you want to delete your ${widget.level} education record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close form modal
                await _deleteEducation();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEducation() async {
    final id = widget.eduMap?['id'];
    if (id == null) return;

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
      }
    }
  }

  Future<void> _saveEducation() async {
    if (formKey.currentState!.validate()) {
      // Check if all fields are empty
      final allFieldsEmpty = schoolController.text.isEmpty &&
          courseController.text.isEmpty &&
          yearController.text.isEmpty &&
          honorsController.text.isEmpty;

      // Don't save if all fields are empty
      if (allFieldsEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to save.'),
            ),
          );
        }
        return;
      }

      // Prepare data - only include year if it's valid and non-zero
      final Map<String, dynamic> updateData = {
        'level': widget.level,
        'school_name': schoolController.text,
        'course': courseController.text,
        'honors_received': honorsController.text,
      };

      // Add year only if it's non-empty and valid
      if (yearController.text.isNotEmpty) {
        final year = int.tryParse(yearController.text);
        if (year != null && year > 0) {
          updateData['year_graduated'] = year.toString();
        }
      }

      bool success;
      if (widget.eduMap?['id'] == null) {
        success = await EducationalBackgroundService.storeEducationalBackground(updateData);
      } else {
        updateData['id'] = widget.eduMap!['id'];
        success = await EducationalBackgroundService.updateEducationalBackground(updateData);
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Education saved successfully!'
                : 'Save failed. Please try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) widget.onSaveSuccess();
      }
    }
  }
}