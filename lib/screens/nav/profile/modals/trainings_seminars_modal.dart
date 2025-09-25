// lib/screens/nav/profile/modals/trainings_seminars_modal.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/services/profile/trainings_seminars_service.dart';
// Removed free-form form modal import since we now use fixed checkboxes

import '../../../../constants/app_colors.dart';

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
  final List<String> _options = const [
    'Beef Cattle Raising',
    'Dairy Cattle Raising',
    'Feedlot Fattening',
    'Silage Making',
    'Slaughtering & Cutting',
    'Meat Processing',
    'Cattle Enterprise Development',
    'Forage Production',
    'Health Management',
  ];

  final Set<String> _selectedTitles = <String>{};
  final Map<String, int> _existingTitleToId = <String, int>{};
  final Map<String, Map<String, dynamic>> _detailsByTitle = <String, Map<String, dynamic>>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  void _loadTrainings() {
    trainingFuture = TrainingsSeminarsService.getTrainingsAndSeminars();
    trainingFuture.then((list) {
      if (!mounted) return;
      _selectedTitles.clear();
      _existingTitleToId.clear();
      for (final item in list) {
        final dynamic rawTitle = item['title'];
        if (rawTitle is String && rawTitle.trim().isNotEmpty) {
          final String title = rawTitle.trim();
          _selectedTitles.add(title);
          final dynamic idVal = item['id'];
          if (idVal is int) {
            _existingTitleToId[title] = idVal;
          } else if (idVal is String) {
            final parsed = int.tryParse(idVal);
            if (parsed != null) _existingTitleToId[title] = parsed;
          }
          _detailsByTitle[title] = {
            'conducted_by': item['conducted_by'],
            'location': item['location'],
            'certificate_issued': (item['certificate_issued'] == true || item['certificate_issued'] == 1) ? 1 : 0,
          };
        }
      }
      setState(() {});
    });
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
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: AppColors.primary.withOpacity(0.2),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      label: Text(
                        _saving ? 'Saving...' : 'Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
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

                return ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final title = _options[index];
                    final bool checked = _selectedTitles.contains(title);
                    _detailsByTitle.putIfAbsent(title, () => {
                      'conducted_by': null,
                      'location': null,
                      'certificate_issued': 0,
                    });
                    final details = _detailsByTitle[title]!;

                    return Card(
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: checked,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          title: Row(
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: widget.isEditingMode
                                    ? (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedTitles.add(title);
                                          } else {
                                            _selectedTitles.remove(title);
                                          }
                                        });
                                      }
                                    : null,
                                activeColor: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            _buildLabeledTextField(
                              label: 'Conducted By',
                              value: details['conducted_by']?.toString() ?? '',
                              enabled: widget.isEditingMode && checked,
                              onChanged: (val) {
                                details['conducted_by'] = val.trim().isEmpty ? null : val.trim();
                              },
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledTextField(
                              label: 'Location',
                              value: details['location']?.toString() ?? '',
                              enabled: widget.isEditingMode && checked,
                              onChanged: (val) {
                                details['location'] = val.trim().isEmpty ? null : val.trim();
                              },
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  color: (details['certificate_issued'] == 1)
                                      ? AppColors.gold
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Certificate Issued',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                Checkbox(
                                  value: (details['certificate_issued'] == 1),
                                  onChanged: (widget.isEditingMode && checked)
                                      ? (val) {
                                          setState(() {
                                            details['certificate_issued'] = (val == true) ? 1 : 0;
                                          });
                                        }
                                      : null,
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildLabeledTextField({
    required String label,
    required String value,
    required bool enabled,
    required ValueChanged<String> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: enabled ? AppColors.vibrantGreen : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          enabled: enabled,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: enabled ? AppColors.pageBackground : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.vibrantGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSelection() async {
    setState(() {
      _saving = true;
    });

    try {
      // Compute differences
      final Set<String> current = Set<String>.from(_existingTitleToId.keys);
      final Set<String> desired = Set<String>.from(_selectedTitles);

      final toCreate = desired.difference(current);
      final toDelete = current.difference(desired);
      final toUpdate = desired.intersection(current);

      bool allOk = true;

      // Create new ones
      for (final title in toCreate) {
        final ok = await TrainingsSeminarsService.storeTrainingsAndSeminars({
          'title': title,
          'conducted_by': _detailsByTitle[title]?['conducted_by'],
          'location': _detailsByTitle[title]?['location'],
          'certificate_issued': 0,
        });
        if (!ok) allOk = false;
      }

      // Update existing selected ones with details
      for (final title in toUpdate) {
        final id = _existingTitleToId[title];
        if (id != null) {
          final ok = await TrainingsSeminarsService.updateTrainingsAndSeminars({
            'id': id,
            'title': title,
            'conducted_by': _detailsByTitle[title]?['conducted_by'],
            'location': _detailsByTitle[title]?['location'],
            'certificate_issued': (_detailsByTitle[title]?['certificate_issued'] == 1) ? 1 : 0,
          });
          if (!ok) allOk = false;
        }
      }

      // Delete removed ones
      for (final title in toDelete) {
        final id = _existingTitleToId[title];
        if (id != null) {
          final ok = await TrainingsSeminarsService.deleteTrainingsAndSeminars(id);
          if (!ok) allOk = false;
        }
      }

      if (!mounted) return;
      // Reload and notify
      setState(() {
        _loadTrainings();
      });
      widget.onSaveSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allOk ? 'Saved trainings selection.' : 'Some changes failed to save.'),
          backgroundColor: allOk ? Colors.green : Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}