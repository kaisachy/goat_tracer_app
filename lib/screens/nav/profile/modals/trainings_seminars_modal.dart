// lib/screens/nav/profile/modals/trainings_seminars_modal.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/trainings_seminars_service.dart';
import 'package:cattle_tracer_app/screens/nav/profile/modals/trainings_seminars_form_modal.dart';

class TrainingsSeminarsModal extends StatefulWidget {
  final bool isEditingMode;
  final VoidCallback onSaveSuccess;

  const TrainingsSeminarsModal({
    super.key,
    required this.isEditingMode,
    required this.onSaveSuccess,
  });

  @override
  State<TrainingsSeminarsModal> createState() => _TrainingsSeminarsModalState();
}

class _TrainingsSeminarsModalState extends State<TrainingsSeminarsModal> {
  late Future<List<Map<String, dynamic>>> trainingFuture;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  void _loadTrainings() {
    trainingFuture = TrainingsSeminarsService.getTrainingsAndSeminars();
  }

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
                'Trainings & Seminars',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (widget.isEditingMode)
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showTrainingFormModal();
                      },
                      icon: const Icon(Icons.add),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: trainingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final trainingList = snapshot.data ?? [];

                if (trainingList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No trainings added yet'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: trainingList.length,
                  itemBuilder: (context, index) {
                    final training = trainingList[index];
                    final certificateIssued = training['certificate_issued'] == true ||
                        training['certificate_issued'] == 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[600],
                          child: const Icon(Icons.workspace_premium, color: Colors.white),
                        ),
                        title: Text(
                          training['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(training['conducted_by'] ?? 'N/A'),
                            Text(training['location'] ?? 'N/A'),
                            if (certificateIssued)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 12, color: Colors.green[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Certified',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: widget.isEditingMode
                            ? SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit',
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showTrainingFormModal(trainingMap: training);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _deleteTraining(training, index),
                              ),
                            ],
                          ),
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

  void _showTrainingFormModal({Map<String, dynamic>? trainingMap}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TrainingsSeminarsFormModal(
        trainingMap: trainingMap,
        onSaveSuccess: () {
          setState(() {
            _loadTrainings();
          });
          widget.onSaveSuccess();
        },
      ),
    );
  }

  Future<void> _deleteTraining(Map<String, dynamic> training, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this training/seminar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await TrainingsSeminarsService.deleteTrainingsAndSeminars(training['id']);
      if (context.mounted) {
        if (success) {
          // Refresh the list
          setState(() {
            _loadTrainings();
          });
          widget.onSaveSuccess();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Training deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete training.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}