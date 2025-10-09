// lib/screens/nav/cattle/widgets/event_fields/gives_birth_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../../constants/app_colors.dart';
import '../../../../../../services/cattle/cattle_service.dart';
import '../../../modals/calf_registration_dialog.dart';
import 'base_history_fields.dart';

class GivesBirthEventFields extends BaseEventFields {
  final String? cattleTag;
  final Map<String, dynamic>? temporaryCalfData;
  final VoidCallback? onEditCalfPressed;
  final Function(Map<String, dynamic>?) onCalfDataChanged;

  const GivesBirthEventFields({
    super.key,
    required super.controllers,
    this.cattleTag,
    this.temporaryCalfData,
    this.onEditCalfPressed,
    required this.onCalfDataChanged,
  });

  @override
  GivesBirthEventFieldsState createState() => GivesBirthEventFieldsState();
}

class GivesBirthEventFieldsState extends BaseEventFieldsState<GivesBirthEventFields> {
  Map<String, dynamic>? _newCalfData;
  final List<Map<String, dynamic>> _calves = [];

  @override
  bool needsBulls() => true;

  @override
  void initState() {
    super.initState();
    _newCalfData = widget.temporaryCalfData;
    if (_newCalfData != null) {
      _calves.add(_newCalfData!);
    }
    // Load existing calf data if we're in edit mode and have calf data
    _loadExistingCalfData();
    
    // Also check if there are multiple calves in the calf_tag controller
    final calfTagText = widget.controllers['calf_tag']?.text ?? '';
    if (calfTagText.isNotEmpty && calfTagText.contains(',')) {
      _loadMultipleExistingCalves(calfTagText);
    }
  }

  @override
  void onBullsLoaded() {
    print('DEBUG: GivesBirthEventFields onBullsLoaded called');
    // If semen_used has a value but bull_tag is empty, try to derive bull tag from semen label
    final semenText = widget.controllers['semen_used']?.text ?? '';
    final bullText = widget.controllers['bull_tag']?.text ?? '';
    print('DEBUG: Current semen: $semenText, bull: $bullText');
    
    if (semenText.isNotEmpty && bullText.isEmpty) {
      print('DEBUG: Extracting bull tag from semen in onBullsLoaded for Gives Birth');
      // Expected semen format examples:
      // - "TAG123 (Name) Semen"
      // - "TAG123 Semen"
      // - "TAG123"
      String extracted = semenText.trim();
      if (extracted.toLowerCase().endsWith('semen')) {
        extracted = extracted.substring(0, extracted.length - 5).trim();
      }
      int stop = extracted.indexOf(' ');
      int paren = extracted.indexOf('(');
      if (stop == -1 || (paren != -1 && paren < stop)) {
        stop = paren;
      }
      final bullTag = stop == -1 ? extracted : extracted.substring(0, stop).trim();
      print('DEBUG: Extracted bull tag for Gives Birth: $bullTag');
      if (bullTag.isNotEmpty) {
        widget.controllers['bull_tag']?.text = bullTag;
        print('DEBUG: Set bull_tag controller for Gives Birth to: $bullTag');
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void didUpdateWidget(GivesBirthEventFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.temporaryCalfData != oldWidget.temporaryCalfData) {
      setState(() {
        _newCalfData = widget.temporaryCalfData;
        // If we have new calf data, update the calves list
        if (_newCalfData != null) {
          _calves.clear();
          _calves.add(_newCalfData!);
        }
      });
    }
  }

  void _loadExistingCalfData() {
    // If we're in edit mode and have temporary calf data, it means there's an existing calf
    if (widget.temporaryCalfData != null && widget.temporaryCalfData!['isEditMode'] == true) {
      setState(() {
        _calves.clear();
        _calves.add(widget.temporaryCalfData!);
      });
    }
  }

  // Method to load multiple existing calves from a comma-separated tag string
  Future<void> _loadMultipleExistingCalves(String calfTagString) async {
    if (calfTagString.contains(',')) {
      // Multiple calves - split by comma and load each one
      final calfTags = calfTagString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
      print('Loading multiple calves: $calfTags');
      
      final List<Map<String, dynamic>> loadedCalves = [];
      
      for (final calfTag in calfTags) {
        try {
          final calf = await CattleService.getCattleByTag(calfTag);
          if (calf != null) {
            final calfData = {
              'tag_no': calf.tagNo,
              'sex': calf.sex,
              'registered': true,
              'isEditMode': true,
              'calfId': calf.id,
              'pendingOperation': 'update',
              'fullCalfData': {
                'id': calf.id,
                'tag_no': calf.tagNo,
                'sex': calf.sex,
                'date_of_birth': calf.dateOfBirth,
                'classification': calf.classification,
                'status': calf.status,
                'breed': calf.breed,
                'source': calf.source,
                'mother_tag': calf.motherTag,
                'father_tag': calf.fatherTag,
                'weight': calf.weight,
                'group_name': calf.groupName,
                'notes': calf.notes,
              },
            };
            loadedCalves.add(calfData);
            print('Loaded calf: ${calf.tagNo} with ID: ${calf.id}');
          }
        } catch (e) {
          print('Error loading calf $calfTag: $e');
        }
      }
      
      if (mounted && loadedCalves.isNotEmpty) {
        setState(() {
          _calves.clear();
          _calves.addAll(loadedCalves);
        });
        print('Loaded ${loadedCalves.length} existing calves');
      }
    }
  }


  Future<void> _openAddCalfDialog() async {
    final reserved = _calves.map((c) => (c['tag_no'] ?? '').toString()).where((t) => t.isNotEmpty).toList();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalfRegistrationDialog(
        motherTag: widget.cattleTag ?? '',
        fatherTag: widget.controllers['bull_tag']?.text ?? '',
        existingCalfData: null,
        reservedTags: reserved,
        isEditMode: false,
      ),
    );

    if (result != null) {
      final normalized = _normalizeCalfResult(result, isEdit: false);
      setState(() {
        final tag = normalized['tag_no'];
        final idx = _calves.indexWhere((c) => c['tag_no'] == tag);
        if (idx >= 0) {
          _calves[idx] = normalized;
        } else {
          _calves.add(normalized);
        }
        widget.controllers['calf_tag']?.text = normalized['tag_no'] ?? '';
      });
      widget.onCalfDataChanged(normalized);
    }
  }

  Future<void> _openEditCalfDialog(int index) async {
    final calfData = _calves[index];
    final reserved = _calves
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => (e.value['tag_no'] ?? '').toString())
        .where((t) => t.isNotEmpty)
        .toList();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalfRegistrationDialog(
        motherTag: widget.cattleTag ?? '',
        fatherTag: widget.controllers['bull_tag']?.text ?? '',
        existingCalfData: calfData['fullCalfData'] ?? calfData,
        reservedTags: reserved,
        isEditMode: true,
      ),
    );

    if (result != null) {
      final normalized = _normalizeCalfResult(result, isEdit: true);
      setState(() {
        _calves[index] = normalized;
        widget.controllers['calf_tag']?.text = normalized['tag_no'] ?? '';
      });
      widget.onCalfDataChanged(normalized);
    }
  }

  Map<String, dynamic> _normalizeCalfResult(Map<String, dynamic> input, {required bool isEdit}) {
    final motherTag = widget.cattleTag ?? '';
    final fatherTag = widget.controllers['bull_tag']?.text ?? '';

    // Ensure fullCalfData exists and contains required fields
    final full = Map<String, dynamic>.from(input['fullCalfData'] ?? input);
    full['tag_no'] = full['tag_no'] ?? input['tag_no'];
    full['name'] = full['name'] ?? input['name'];
    full['sex'] = full['sex'] ?? input['sex'];
    full['mother_tag'] = motherTag;
    full['father_tag'] = fatherTag;

    // For create operations, remove id to avoid unintended updates
    final pending = input['pendingOperation'] ?? (isEdit ? 'update' : 'create');
    if (pending == 'create') {
      full.remove('id');
    }

    return <String, dynamic>{
      'tag_no': full['tag_no'],
      'name': full['name'],
      'sex': full['sex'],
      'pendingOperation': pending,
      'isEditMode': isEdit,
      'fullCalfData': full,
      'calfId': full['id'],
    };
  }

  void _removeCalfAt(int index) {
    if (index >= 0 && index < _calves.length) {
      final calf = _calves[index];
      final isEditMode = calf['isEditMode'] == true;
      
      if (isEditMode) {
        // For existing calves, show confirmation dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  const Text('Delete Calf'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete this calf?'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tag: ${calf['tag_no'] ?? 'Not set'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (calf['name'] != null && calf['name'].toString().isNotEmpty)
                          Text('Name: ${calf['name']}'),
                        Text('Sex: ${calf['sex'] ?? 'Not set'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action will permanently delete the calf from the database.',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _performCalfDeletion(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      } else {
        // For new calves, just remove from list
        setState(() {
          _calves.removeAt(index);
          if (_calves.isEmpty) {
            _newCalfData = null;
            widget.controllers['calf_tag']?.text = '';
          }
        });
      }
    }
  }

  void _performCalfDeletion(int index) async {
    if (index >= 0 && index < _calves.length) {
      final calf = _calves[index];
      final calfId = calf['calfId'];
      
      if (calfId != null) {
        try {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Deleting calf ${calf['tag_no']}...'),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              duration: const Duration(seconds: 10),
            ),
          );

          // Delete the calf from database
          final success = await CattleService.deleteCattleInformation(calfId);
          
          // Clear loading snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
          }
          
          if (success) {
            // Remove from local list
            if (mounted) {
              setState(() {
                _calves.removeAt(index);
                if (_calves.isEmpty) {
                  _newCalfData = null;
                  widget.controllers['calf_tag']?.text = '';
                }
              });
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calf ${calf['tag_no']} deleted successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          } else {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete calf ${calf['tag_no']}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }
        } catch (e) {
          // Clear loading snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting calf: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      } else {
        // No calf ID, just remove from list
        setState(() {
          _calves.removeAt(index);
          if (_calves.isEmpty) {
            _newCalfData = null;
            widget.controllers['calf_tag']?.text = '';
          }
        });
      }
    }
  }

  List<Map<String, dynamic>> getCalves() => List<Map<String, dynamic>>.from(_calves);

  Widget _buildCalfRegistrationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.baby, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Calf Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _openAddCalfDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Calf', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
          if (_calves.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._calves.asMap().entries.map((entry) {
              final index = entry.key;
              final calf = entry.value;
              final isEditMode = calf['isEditMode'] == true;
              final isRegistered = calf['registered'] == true;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.lightGreen.withValues(alpha: 0.5)
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.label, 
                          color: AppColors.primary, 
                          size: 16
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tag: ${calf['tag_no'] ?? 'Not set'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: isEditMode ? 'Delete Calf' : 'Remove',
                          icon: Icon(
                            Icons.delete_forever, 
                            color: Colors.red.shade600, 
                            size: 18
                          ),
                          onPressed: () => _removeCalfAt(index),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: Icon(
                            Icons.edit, 
                            color: AppColors.primary, 
                            size: 18
                          ),
                          onPressed: () => _openEditCalfDialog(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (calf['name'] != null && calf['name'].toString().isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.signature, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Name: ${calf['name']}',
                              style: const TextStyle(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(
                          calf['sex'] == 'Male' ? Icons.male : Icons.female,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sex: ${calf['sex'] ?? 'Not set'}',
                            style: const TextStyle(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (isEditMode) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isRegistered ? Icons.check_circle : Icons.schedule,
                            color: isRegistered ? Colors.green : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isRegistered ? 'Already Registered' : 'Pending registration',
                              style: TextStyle(
                                color: isRegistered ? Colors.green.shade700 : Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildBullDropdown(),
        _buildCalfRegistrationField(),
        if (_calves.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total calves: ${_calves.length}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}