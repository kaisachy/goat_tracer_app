// lib/screens/nav/profile/modals/trainings_seminars_form_modal.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/trainings_seminars_service.dart';

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
              Text(
                isEditing ? 'Edit Training & Seminar' : 'Add Training & Seminar',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
              ),
              TextFormField(
                controller: conductedByController,
                decoration: const InputDecoration(labelText: 'Conducted By'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dateFrom ?? DateTime.now(),
                          firstDate: DateTime(1980),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => dateFrom = picked);
                        }
                      },
                      label: Text(
                        dateFrom == null
                            ? 'Date From'
                            : dateFrom!.toLocal().toString().split(' ')[0],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dateTo ?? dateFrom ?? DateTime.now(),
                          firstDate: dateFrom ?? DateTime(1980),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => dateTo = picked);
                        }
                      },
                      label: Text(
                        dateTo == null
                            ? 'Date To'
                            : dateTo!.toLocal().toString().split(' ')[0],
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              Row(
                children: [
                  Checkbox(
                    value: certificateIssued,
                    onChanged: (val) {
                      setState(() {
                        certificateIssued = val ?? false;
                      });
                    },
                  ),
                  const Text('Certificate Issued'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTraining,
                  child: Text(isEditing ? 'Save Changes' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTraining() async {
    if (formKey.currentState!.validate()) {
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

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Training saved successfully!'
                : 'Failed to save training.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          widget.onSaveSuccess();
        }
      }
    }
  }
}