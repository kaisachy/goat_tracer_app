// lib/screens/nav/profile/modals/trainings_seminars_modal.dart
import 'package:flutter/material.dart';
import 'package:goat_tracer_app/services/profile/trainings_seminars_service.dart';
// Removed free-form form modal import since we now use fixed checkboxes

import '../../../../constants/app_colors.dart';

class TrainingsSeminarsModal extends StatefulWidget {
  final bool isEditingMode;
  final VoidCallback onSaveSuccess;
  final VoidCallback onToggleEditMode;

  const TrainingsSeminarsModal({
    super.key,
    required this.isEditingMode,
    required this.onSaveSuccess,
    required this.onToggleEditMode,
  });

  @override
  State<TrainingsSeminarsModal> createState() => _TrainingsSeminarsModalState();
}

class _TrainingsSeminarsModalState extends State<TrainingsSeminarsModal> {
  late Future<List<Map<String, dynamic>>> trainingFuture;
  bool _localEditingMode = false;
  final List<String> _options = const [
    'Meat Goat Raising',
    'Dairy Goat Raising',
    'Feedlot Fattening',
    'Silage Making',
    'Slaughtering & Cutting',
    'Meat Processing',
    'Goat Enterprise Development',
    'Forage Production',
    'Health Management',
    'FLS for Goat',
  ];

  final Set<String> _selectedTitles = <String>{};
  final Map<String, int> _existingTitleToId = <String, int>{};
  final Map<String, Map<String, dynamic>> _detailsByTitle = <String, Map<String, dynamic>>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _localEditingMode = widget.isEditingMode;
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
                                onChanged: _localEditingMode
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                                _buildLabeledTextField(
                              label: 'Conducted By',
                              value: details['conducted_by']?.toString() ?? '',
                              enabled: _localEditingMode && checked,
                              onChanged: (val) {
                                details['conducted_by'] = val.trim().isEmpty ? null : val.trim();
                              },
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledTextField(
                              label: 'Location',
                              value: details['location']?.toString() ?? '',
                              enabled: _localEditingMode && checked,
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
                                  onChanged: (_localEditingMode && checked)
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
            Icons.workspace_premium,
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
                'Trainings & Seminars',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _localEditingMode ? 'Edit your training records' : 'View your professional development',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: _localEditingMode ? 'Save & Exit Edit Mode' : 'Edit',
          child: GestureDetector(
            onTap: () async {
              if (_localEditingMode) {
                // Save when exiting edit mode
                await _saveSelection();
              } else {
                // Enter edit mode
                setState(() {
                  _localEditingMode = true;
                });
                widget.onToggleEditMode();
              }
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
              child: _localEditingMode && _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
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
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
      if (allOk) {
        _loadTrainings(); // This updates trainingFuture and calls setState internally
        setState(() {
          _localEditingMode = false;
        });
        widget.onToggleEditMode();
      }
      
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
