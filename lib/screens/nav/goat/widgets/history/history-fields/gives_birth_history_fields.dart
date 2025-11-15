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
    // Load existing kid data if we're in edit mode and have kid data
    _loadExistingKidData();
    
    // Also check if there are multiple calves in the Kid_tag controller
    final kidTagText = widget.controllers['Kid_tag']?.text ?? '';
    if (kidTagText.isNotEmpty && kidTagText.contains(',')) {
      _loadMultipleExistingCalves(kidTagText);
    }
  }

  @override
  void onBucksLoaded() {
    debugPrint('DEBUG: GivesBirthEventFields onBucksLoaded called');
    // If semen_used has a value but Buck_tag is empty, try to derive Buck tag from semen label
    final semenText = widget.controllers['semen_used']?.text ?? '';
    final buckText = widget.controllers['Buck_tag']?.text ?? '';
    debugPrint('DEBUG: Current semen: $semenText, Buck: $buckText');
    
    if (semenText.isNotEmpty && buckText.isEmpty) {
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
      final buckTag = stop == -1 ? extracted : extracted.substring(0, stop).trim();
      debugPrint('DEBUG: Extracted Buck tag for Gives Birth: $buckTag');
      if (buckTag.isNotEmpty) {
        widget.controllers['Buck_tag']?.text = buckTag;
        debugPrint('DEBUG: Set Buck_tag controller for Gives Birth to: $buckTag');
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
        // If we have new kid data, update the calves list
        if (_newKidData != null) {
          _calves.clear();
          _calves.add(_newKidData!);
        }
      });
    }
  }

  void _loadExistingKidData() {
    // If we're in edit mode and have temporary kid data, it means there's an existing kid
    if (widget.temporaryKidData != null && widget.temporaryKidData!['isEditMode'] == true) {
      setState(() {
        _calves.clear();
        _calves.add(widget.temporaryKidData!);
      });
    }
  }

  // Method to load multiple existing calves from a comma-separated tag string
  Future<void> _loadMultipleExistingCalves(String kidTagString) async {
    if (kidTagString.contains(',')) {
      // Multiple calves - split by comma and load each one
      final kidTags = kidTagString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
      debugPrint('Loading multiple calves: $kidTags');
      
      final List<Map<String, dynamic>> loadedCalves = [];
      
      for (final kidTag in kidTags) {
        try {
          final kid = await GoatService.getGoatByTag(kidTag);
          if (kid != null) {
            final kidData = {
              'tag_no': kid.tagNo,
              'sex': kid.sex,
              'registered': true,
              'isEditMode': true,
              'kidId': kid.id,
              'pendingOperation': 'update',
              'fullKidData': {
                'id': kid.id,
                'tag_no': kid.tagNo,
                'sex': kid.sex,
                'date_of_birth': kid.dateOfBirth,
                'classification': kid.classification,
                'status': kid.status,
                'breed': kid.breed,
                'source': kid.source,
                'mother_tag': kid.motherTag,
                'father_tag': kid.fatherTag,
                'weight': kid.weight,
                'group_name': kid.groupName,
                'notes': kid.notes,
              },
            };
            loadedCalves.add(kidData);
            debugPrint('Loaded kid: ${kid.tagNo} with ID: ${kid.id}');
          }
        } catch (e) {
          debugPrint('Error loading kid $kidTag: $e');
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
    final kidData = _calves[index];
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
        existingKidData: kidData['fullKidData'] ?? kidData,
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
      'kidId': full['id'],
    };
  }

  void _removeKidAt(int index) {
    if (index >= 0 && index < _calves.length) {
      final kid = _calves[index];
      final isEditMode = kid['isEditMode'] == true;
      
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
                  const Text('Delete kid'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete this kid?'),
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
                          'Tag: ${kid['tag_no'] ?? 'Not set'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (kid['name'] != null && kid['name'].toString().isNotEmpty)
                          Text('Name: ${kid['name']}'),
                        Text('Sex: ${kid['sex'] ?? 'Not set'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action will permanently delete the kid from the database.',
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
      final kid = _calves[index];
      final kidId = kid['kidId'];
      
      if (kidId != null) {
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
                  Text('Deleting kid ${kid['tag_no']}...'),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              duration: const Duration(seconds: 10),
            ),
          );

          // Delete the kid from database
          final success = await GoatService.deletegoatInformation(kidId);
          
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
                  content: Text('kid ${kid['tag_no']} deleted successfully'),
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
                  content: Text('Failed to delete kid ${kid['tag_no']}'),
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
                content: Text('Error deleting kid: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      } else {
        // No kid ID, just remove from list
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
                  'kid Information',
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
                  label: const Text('Add kid', style: TextStyle(fontSize: 12)),
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
              final kid = entry.value;
              final isEditMode = kid['isEditMode'] == true;
              final isRegistered = kid['registered'] == true;
              
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
                            'Tag: ${kid['tag_no'] ?? 'Not set'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: isEditMode ? 'Delete kid' : 'Remove',
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
                    if (kid['name'] != null && kid['name'].toString().isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.signature, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Name: ${kid['name']}',
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
                          kid['sex'] == 'Male' ? Icons.male : Icons.female,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sex: ${kid['sex'] ?? 'Not set'}',
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