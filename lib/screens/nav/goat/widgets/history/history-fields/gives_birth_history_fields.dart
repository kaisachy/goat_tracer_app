// lib/screens/nav/goat/widgets/event_fields/gives_birth_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../../constants/app_colors.dart';
import '../../../../../../services/goat/goat_service.dart';
import '../../../modals/Kid_registration_dialog.dart';
import 'base_history_fields.dart';

class GivesBirthEventFields extends BaseEventFields {
  final String? goatTag;
  final Map<String, dynamic>? temporaryKidData;
  final VoidCallback? onEditKidPressed;
  final Function(Map<String, dynamic>?) onKidDataChanged;

  const GivesBirthEventFields({
    super.key,
    required super.controllers,
    this.goatTag,
    this.temporaryKidData,
    this.onEditKidPressed,
    required this.onKidDataChanged,
  });

  @override
  GivesBirthEventFieldsState createState() => GivesBirthEventFieldsState();
}

class GivesBirthEventFieldsState extends BaseEventFieldsState<GivesBirthEventFields> {
  Map<String, dynamic>? _newKidData;
  final List<Map<String, dynamic>> _calves = [];

  @override
  bool needsBucks() => true;

  @override
  void initState() {
    super.initState();
    _newKidData = widget.temporaryKidData;
    if (_newKidData != null) {
      _calves.add(_newKidData!);
    }
    // Load existing Kid data if we're in edit mode and have Kid data
    _loadExistingKidData();
    
    // Also check if there are multiple calves in the Kid_tag controller
    final KidTagText = widget.controllers['Kid_tag']?.text ?? '';
    if (KidTagText.isNotEmpty && KidTagText.contains(',')) {
      _loadMultipleExistingCalves(KidTagText);
    }
  }

  @override
  void onBucksLoaded() {
    debugPrint('DEBUG: GivesBirthEventFields onBucksLoaded called');
    // If semen_used has a value but Buck_tag is empty, try to derive Buck tag from semen label
    final semenText = widget.controllers['semen_used']?.text ?? '';
    final BuckText = widget.controllers['Buck_tag']?.text ?? '';
    debugPrint('DEBUG: Current semen: $semenText, Buck: $BuckText');
    
    if (semenText.isNotEmpty && BuckText.isEmpty) {
      debugPrint('DEBUG: Extracting Buck tag from semen in onBucksLoaded for Gives Birth');
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
      final BuckTag = stop == -1 ? extracted : extracted.substring(0, stop).trim();
      debugPrint('DEBUG: Extracted Buck tag for Gives Birth: $BuckTag');
      if (BuckTag.isNotEmpty) {
        widget.controllers['Buck_tag']?.text = BuckTag;
        debugPrint('DEBUG: Set Buck_tag controller for Gives Birth to: $BuckTag');
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void didUpdateWidget(GivesBirthEventFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.temporaryKidData != oldWidget.temporaryKidData) {
      setState(() {
        _newKidData = widget.temporaryKidData;
        // If we have new Kid data, update the calves list
        if (_newKidData != null) {
          _calves.clear();
          _calves.add(_newKidData!);
        }
      });
    }
  }

  void _loadExistingKidData() {
    // If we're in edit mode and have temporary Kid data, it means there's an existing Kid
    if (widget.temporaryKidData != null && widget.temporaryKidData!['isEditMode'] == true) {
      setState(() {
        _calves.clear();
        _calves.add(widget.temporaryKidData!);
      });
    }
  }

  // Method to load multiple existing calves from a comma-separated tag string
  Future<void> _loadMultipleExistingCalves(String KidTagString) async {
    if (KidTagString.contains(',')) {
      // Multiple calves - split by comma and load each one
      final KidTags = KidTagString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
      debugPrint('Loading multiple calves: $KidTags');
      
      final List<Map<String, dynamic>> loadedCalves = [];
      
      for (final KidTag in KidTags) {
        try {
          final Kid = await GoatService.getGoatByTag(KidTag);
          if (Kid != null) {
            final KidData = {
              'tag_no': Kid.tagNo,
              'sex': Kid.sex,
              'registered': true,
              'isEditMode': true,
              'KidId': Kid.id,
              'pendingOperation': 'update',
              'fullKidData': {
                'id': Kid.id,
                'tag_no': Kid.tagNo,
                'sex': Kid.sex,
                'date_of_birth': Kid.dateOfBirth,
                'classification': Kid.classification,
                'status': Kid.status,
                'breed': Kid.breed,
                'source': Kid.source,
                'mother_tag': Kid.motherTag,
                'father_tag': Kid.fatherTag,
                'weight': Kid.weight,
                'group_name': Kid.groupName,
                'notes': Kid.notes,
              },
            };
            loadedCalves.add(KidData);
            debugPrint('Loaded Kid: ${Kid.tagNo} with ID: ${Kid.id}');
          }
        } catch (e) {
          debugPrint('Error loading Kid $KidTag: $e');
        }
      }
      
      if (mounted && loadedCalves.isNotEmpty) {
        setState(() {
          _calves.clear();
          _calves.addAll(loadedCalves);
        });
        debugPrint('Loaded ${loadedCalves.length} existing calves');
      }
    }
  }


  Future<void> _openAddKidDialog() async {
    final reserved = _calves.map((c) => (c['tag_no'] ?? '').toString()).where((t) => t.isNotEmpty).toList();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => KidRegistrationDialog(
        motherTag: widget.goatTag ?? '',
        fatherTag: widget.controllers['Buck_tag']?.text ?? '',
        existingKidData: null,
        reservedTags: reserved,
        isEditMode: false,
      ),
    );

    if (result != null) {
      final normalized = _normalizeKidResult(result, isEdit: false);
      setState(() {
        final tag = normalized['tag_no'];
        final idx = _calves.indexWhere((c) => c['tag_no'] == tag);
        if (idx >= 0) {
          _calves[idx] = normalized;
        } else {
          _calves.add(normalized);
        }
        widget.controllers['Kid_tag']?.text = normalized['tag_no'] ?? '';
      });
      widget.onKidDataChanged(normalized);
    }
  }

  Future<void> _openEditKidDialog(int index) async {
    final KidData = _calves[index];
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
      builder: (context) => KidRegistrationDialog(
        motherTag: widget.goatTag ?? '',
        fatherTag: widget.controllers['Buck_tag']?.text ?? '',
        existingKidData: KidData['fullKidData'] ?? KidData,
        reservedTags: reserved,
        isEditMode: true,
      ),
    );

    if (result != null) {
      final normalized = _normalizeKidResult(result, isEdit: true);
      setState(() {
        _calves[index] = normalized;
        widget.controllers['Kid_tag']?.text = normalized['tag_no'] ?? '';
      });
      widget.onKidDataChanged(normalized);
    }
  }

  Map<String, dynamic> _normalizeKidResult(Map<String, dynamic> input, {required bool isEdit}) {
    final motherTag = widget.goatTag ?? '';
    final fatherTag = widget.controllers['Buck_tag']?.text ?? '';

    // Ensure fullKidData exists and contains required fields
    final full = Map<String, dynamic>.from(input['fullKidData'] ?? input);
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
      'fullKidData': full,
      'KidId': full['id'],
    };
  }

  void _removeKidAt(int index) {
    if (index >= 0 && index < _calves.length) {
      final Kid = _calves[index];
      final isEditMode = Kid['isEditMode'] == true;
      
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
                  const Text('Delete Kid'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete this Kid?'),
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
                          'Tag: ${Kid['tag_no'] ?? 'Not set'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (Kid['name'] != null && Kid['name'].toString().isNotEmpty)
                          Text('Name: ${Kid['name']}'),
                        Text('Sex: ${Kid['sex'] ?? 'Not set'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action will permanently delete the Kid from the database.',
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
                    _performKidDeletion(index);
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
            _newKidData = null;
            widget.controllers['Kid_tag']?.text = '';
          }
        });
      }
    }
  }

  void _performKidDeletion(int index) async {
    if (index >= 0 && index < _calves.length) {
      final Kid = _calves[index];
      final KidId = Kid['KidId'];
      
      if (KidId != null) {
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
                  Text('Deleting Kid ${Kid['tag_no']}...'),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              duration: const Duration(seconds: 10),
            ),
          );

          // Delete the Kid from database
          final success = await GoatService.deletegoatInformation(KidId);
          
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
                  _newKidData = null;
                  widget.controllers['Kid_tag']?.text = '';
                }
              });
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kid ${Kid['tag_no']} deleted successfully'),
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
                  content: Text('Failed to delete Kid ${Kid['tag_no']}'),
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
                content: Text('Error deleting Kid: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      } else {
        // No Kid ID, just remove from list
        setState(() {
          _calves.removeAt(index);
          if (_calves.isEmpty) {
            _newKidData = null;
            widget.controllers['Kid_tag']?.text = '';
          }
        });
      }
    }
  }

  List<Map<String, dynamic>> getCalves() => List<Map<String, dynamic>>.from(_calves);

  Widget _buildKidRegistrationField() {
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
                  'Kid Information',
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
                  onPressed: _openAddKidDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Kid', style: TextStyle(fontSize: 12)),
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
              final Kid = entry.value;
              final isEditMode = Kid['isEditMode'] == true;
              final isRegistered = Kid['registered'] == true;
              
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
                            'Tag: ${Kid['tag_no'] ?? 'Not set'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: isEditMode ? 'Delete Kid' : 'Remove',
                          icon: Icon(
                            Icons.delete_forever, 
                            color: Colors.red.shade600, 
                            size: 18
                          ),
                          onPressed: () => _removeKidAt(index),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: Icon(
                            Icons.edit, 
                            color: AppColors.primary, 
                            size: 18
                          ),
                          onPressed: () => _openEditKidDialog(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (Kid['name'] != null && Kid['name'].toString().isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.signature, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Name: ${Kid['name']}',
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
                          Kid['sex'] == 'Male' ? Icons.male : Icons.female,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sex: ${Kid['sex'] ?? 'Not set'}',
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
        buildBuckDropdown(),
        _buildKidRegistrationField(),
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