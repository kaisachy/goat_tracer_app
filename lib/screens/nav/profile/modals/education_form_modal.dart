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
  late TextEditingController startYearController;
  late TextEditingController endYearController;
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
    // Initialize start/end year (avoid 0/0000)
    startYearController = TextEditingController(
      text: (eduMap?['start_year'] != null &&
          eduMap!['start_year'].toString().isNotEmpty &&
          eduMap['start_year'].toString() != '0' &&
          eduMap['start_year'].toString() != '0000')
          ? eduMap['start_year'].toString()
          : '',
    );
    endYearController = TextEditingController(
      text: (eduMap?['end_year'] != null &&
          eduMap!['end_year'].toString().isNotEmpty &&
          eduMap['end_year'].toString() != '0' &&
          eduMap['end_year'].toString() != '0000')
          ? eduMap['end_year'].toString()
          : '',
    );
  }

  @override
  void dispose() {
    schoolController.dispose();
    courseController.dispose();
    yearController.dispose();
    startYearController.dispose();
    endYearController.dispose();
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
                        AppColors.lightGreen.withValues(alpha: 0.3),
                        AppColors.vibrantGreen.withValues(alpha: 0.3),
                        AppColors.lightGreen.withValues(alpha: 0.3),
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

                if (widget.level.toLowerCase() != 'elementary')
                  _buildTextField(
                    controller: courseController,
                    label: 'Course/Program',
                    icon: Icons.menu_book_outlined,
                    hint: 'Enter your course or program',
                  ),

                const SizedBox(height: 20),

                // Start/End Year (year-only picker)
                Row(
                  children: [
                    Expanded(
                      child: _buildYearPickerField(
                        controller: startYearController,
                        label: 'Start Year',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildYearPickerField(
                        controller: endYearController,
                        label: 'End Year',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildYearPickerField(
                  controller: yearController,
                  label: 'Year Graduated',
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
                          side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
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
                          shadowColor: AppColors.primary.withValues(alpha: 0.2),
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
                                  color: Colors.white,
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
              color: AppColors.textSecondary.withValues(alpha: 0.6),
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
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
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

  // Removed unused _buildYearDropdown

  Widget _buildYearPickerField({
    required TextEditingController controller,
    required String label,
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
        InkWell(
          onTap: () async {
            final picked = await _pickYear(context, controller.text);
            if (picked != null) {
              controller.text = picked.toString();
              setState(() {});
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.vibrantGreen, size: 22),
              filled: true,
              fillColor: AppColors.pageBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            child: Text(
              controller.text.isEmpty ? 'Select year' : controller.text,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Future<int?> _pickYear(BuildContext context, String current) async {
    final now = DateTime.now();
    final initialYear = int.tryParse(current) ?? now.year;
    int? selectedYear = initialYear;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 340,
            height: 320,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Text('Select Year', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                Expanded(
                  child: YearPicker(
                    firstDate: DateTime(1900),
                    lastDate: DateTime(now.year),
                    selectedDate: DateTime(initialYear),
                    onChanged: (date) {
                      selectedYear = date.year;
                      Navigator.of(ctx).pop(selectedYear);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Clear'),
            ),
          ],
        );
      },
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
          startYearController.text.isEmpty &&
          endYearController.text.isEmpty;

      // Don't save if all fields are empty
      if (allFieldsEmpty) {
        if (!mounted) return;
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
        return;
      }

      setState(() => isLoading = true);

      // Prepare data - only include year if it's valid and non-zero
      final Map<String, dynamic> updateData = {
        'level': widget.level,
        'school_name': schoolController.text,
        // Only send course when level is not Elementary
        if (widget.level.toLowerCase() != 'elementary') 'course': courseController.text,
      };

      // Add year only if it's non-empty and valid
      if (yearController.text.isNotEmpty) {
        final year = int.tryParse(yearController.text);
        if (year != null && year > 0) {
          updateData['year_graduated'] = year.toString();
        }
      }

      // Add start/end year if valid
      if (startYearController.text.isNotEmpty) {
        final sy = int.tryParse(startYearController.text);
        if (sy != null && sy > 0) {
          updateData['start_year'] = sy.toString();
        }
      }
      if (endYearController.text.isNotEmpty) {
        final ey = int.tryParse(endYearController.text);
        if (ey != null && ey > 0) {
          updateData['end_year'] = ey.toString();
        }
      }

      bool success;
      if (widget.eduMap?['id'] == null) {
        success = await EducationalBackgroundService.storeEducationalBackground(updateData);
      } else {
        updateData['id'] = widget.eduMap!['id'];
        success = await EducationalBackgroundService.updateEducationalBackground(updateData);
      }

      if (!mounted) return;
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
