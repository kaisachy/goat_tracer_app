// lib/screens/nav/profile/modals/trainings_seminars_form_modal.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/trainings_seminars_service.dart';
import '../../../../constants/app_colors.dart';

class TrainingsSeminarsFormModal extends StatefulWidget {
  final Map<String, dynamic>? trainingMap;
  final VoidCallback onSaveSuccess;

  const TrainingsSeminarsFormModal({
    super.key,
    required this.trainingMap,
    required this.onSaveSuccess,
  });

  @override
  State<TrainingsSeminarsFormModal> createState() => _TrainingsSeminarsFormModalState();
}

class _TrainingsSeminarsFormModalState extends State<TrainingsSeminarsFormModal> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController conductedByController;
  late TextEditingController locationController;

  DateTime? dateFrom;
  DateTime? dateTo;
  bool certificateIssued = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final training = widget.trainingMap;

    titleController = TextEditingController(text: training?['title'] ?? '');
    conductedByController = TextEditingController(text: training?['conducted_by'] ?? '');
    locationController = TextEditingController(text: training?['location'] ?? '');

    dateFrom = DateTime.tryParse(training?['date_from'] ?? '');
    dateTo = DateTime.tryParse(training?['date_to'] ?? '');

    if (training != null) {
      final certificateValue = training['certificate_issued'];
      if (certificateValue is bool) {
        certificateIssued = certificateValue;
      } else if (certificateValue is int) {
        certificateIssued = certificateValue == 1;
      } else if (certificateValue is String) {
        certificateIssued = ['true', '1', 'yes', 'issued'].contains(certificateValue.toLowerCase());
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    conductedByController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.trainingMap != null;

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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: AppColors.vibrantGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Training' : 'Add Training',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Training & Seminar Details',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
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
                  controller: titleController,
                  label: 'Training Title',
                  icon: Icons.title,
                  hint: 'Enter the training or seminar title',
                  isRequired: true,
                  validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: conductedByController,
                  label: 'Conducted By',
                  icon: Icons.person_outline,
                  hint: 'Organization or instructor name',
                ),

                const SizedBox(height: 20),

                // Date Selection Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            label: 'Start Date',
                            date: dateFrom,
                            icon: Icons.event_outlined,
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateButton(
                            label: 'End Date',
                            date: dateTo,
                            icon: Icons.event_available_outlined,
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: locationController,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                  hint: 'Training venue or location',
                ),

                const SizedBox(height: 20),

                // Certificate Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: certificateIssued
                              ? AppColors.gold.withValues(alpha: 0.2)
                              : AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          color: certificateIssued
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Certificate Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Was a certificate issued for this training?',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: certificateIssued,
                          onChanged: (val) {
                            setState(() {
                              certificateIssued = val ?? false;
                            });
                          },
                          activeColor: AppColors.vibrantGreen,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        onPressed: isLoading ? null : _saveTraining,
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
                            : Text(
                                isEditing ? 'Save Changes' : 'Add Training',
                                style: const TextStyle(
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
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
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

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.vibrantGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date == null
                  ? 'Select date'
                  : _formatDate(date),
              style: TextStyle(
                fontSize: 16,
                color: date == null
                    ? AppColors.textSecondary.withValues(alpha: 0.6)
                    : AppColors.textPrimary,
                fontWeight: date == null ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFromDate ? dateFrom : dateTo) ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.vibrantGreen,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          dateFrom = picked;
          // If end date is before start date, reset it
          if (dateTo != null && dateTo!.isBefore(picked)) {
            dateTo = null;
          }
        } else {
          dateTo = picked;
        }
      });
    }
  }

  Future<void> _saveTraining() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final data = {
        'title': titleController.text,
        'conducted_by': conductedByController.text.trim().isNotEmpty ? conductedByController.text.trim() : null,
        'location': locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
        'date_from': dateFrom?.toIso8601String().split('T')[0],
        'date_to': dateTo?.toIso8601String().split('T')[0],
        'certificate_issued': certificateIssued ? 1 : 0,
      };

      bool success = false;
      if (widget.trainingMap != null) {
        data['id'] = widget.trainingMap!['id'];
        success = await TrainingsSeminarsService.updateTrainingsAndSeminars(data);
      } else {
        success = await TrainingsSeminarsService.storeTrainingsAndSeminars(data);
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
                      ? 'Training saved successfully!'
                      : 'Failed to save training.',
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
}
