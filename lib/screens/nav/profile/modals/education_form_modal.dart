// lib/screens/nav/profile/modals/education_form_modal.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/educational_background_service.dart';
import '../../../../constants/app_colors.dart';

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
  bool isLoading = false;

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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isExistingRecord ? 'Edit' : 'Add'} ${widget.level}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Educational Background',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      if (isExistingRecord)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade600,
                              size: 24,
                            ),
                            onPressed: () => _showDeleteConfirmation(context),
                            tooltip: 'Delete Record',
                          ),
                        ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lightGreen.withOpacity(0.3),
                        AppColors.vibrantGreen.withOpacity(0.3),
                        AppColors.lightGreen.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Form Fields
                _buildTextField(
                  controller: schoolController,
                  label: 'School/Institution',
                  icon: Icons.school_outlined,
                  hint: 'Enter your school or institution name',
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: courseController,
                  label: 'Course/Program',
                  icon: Icons.menu_book_outlined,
                  hint: 'Enter your course or program',
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: yearController,
                  label: 'Year Graduated',
                  icon: Icons.calendar_today_outlined,
                  hint: 'e.g., 2023',
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

                const SizedBox(height: 20),

                _buildTextField(
                  controller: honorsController,
                  label: 'Honors & Awards',
                  icon: Icons.emoji_events_outlined,
                  hint: 'Any honors, awards, or distinctions',
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveEducation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'Save Education',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.vibrantGreen,
              size: 22,
            ),
            filled: true,
            fillColor: AppColors.pageBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.vibrantGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Record',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete your ${widget.level} education record? This action cannot be undone.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close form modal
                await _deleteEducation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEducation() async {
    final id = widget.eduMap?['id'];
    if (id == null) return;

    setState(() => isLoading = true);

    final success = await EducationalBackgroundService.deleteEducationalBackground(id);

    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Education record deleted successfully!'
                      : 'Failed to delete record. Please try again.',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: success ? AppColors.vibrantGreen : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
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
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'No data to save.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              backgroundColor: AppColors.textSecondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      setState(() => isLoading = true);

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
        setState(() => isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success
                        ? 'Education saved successfully!'
                        : 'Save failed. Please try again.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: success ? AppColors.vibrantGreen : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (success) widget.onSaveSuccess();
      }
    }
  }
}