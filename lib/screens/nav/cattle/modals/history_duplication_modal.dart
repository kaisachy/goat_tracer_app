// lib/screens/nav/cattle/modals/event_duplication_modal.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/cattle.dart';
import '../../../../services/cattle/cattle_service.dart';
import '../../../../services/cattle/cattle_history_service.dart';

class HistoryDuplicationModal extends StatefulWidget {
  final Map<String, dynamic> originalEvent;

  const HistoryDuplicationModal({
    super.key,
    required this.originalEvent,
  });

  @override
  State<HistoryDuplicationModal> createState() => _HistoryDuplicationModalState();
}

class _HistoryDuplicationModalState extends State<HistoryDuplicationModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventDateController = TextEditingController();

  List<Cattle> _allCattle = [];
  List<Cattle> _availableCattle = [];
  final Set<String> _selectedCattleTags = <String>{};
  bool _isLoading = true;
  bool _isDuplicating = false;
  bool _selectAll = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeEventDate();
    _loadAvailableCattle();
  }

  @override
  void dispose() {
    _eventDateController.dispose();
    super.dispose();
  }

  void _initializeEventDate() {
    // Set today's date as default
    final today = DateTime.now();
    final formattedDate = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    _eventDateController.text = formattedDate;
  }

  Future<void> _loadAvailableCattle() async {
    try {
      setState(() => _isLoading = true);

      final allCattle = await CattleService.getAllCattle();
      final originalEventType = widget.originalEvent['history_type']?.toString().toLowerCase() ?? '';
      final originalCattleTag = widget.originalEvent['cattle_tag']?.toString() ?? '';

      print('Debug: Loading cattle for event type: $originalEventType');
      print('Debug: Total cattle loaded: ${allCattle.length}');

      // Filter cattle based on event type, sex, classification, and status
      final availableCattle = allCattle.where((cattle) {
        // Check if cattle is healthy
        if (cattle.status.toLowerCase() != 'healthy') {
          print('Debug: Skipping ${cattle.tagNo} - status: ${cattle.status}');
          return false;
        }

        // Skip the original cattle
        if (cattle.tagNo.trim().toLowerCase() == originalCattleTag.trim().toLowerCase()) {
          print('Debug: Skipping ${cattle.tagNo} - original cattle');
          return false;
        }

        // Check sex compatibility
        if (!_isEventTypeValidForGender(originalEventType, cattle.sex)) {
          print('Debug: Skipping ${cattle.tagNo} - sex incompatible: ${cattle.sex}');
          return false;
        }

        // Check classification compatibility for breeding event
        if (!_isEventTypeValidForClassification(originalEventType, cattle.classification)) {
          print('Debug: Skipping ${cattle.tagNo} - classification incompatible: ${cattle.classification}');
          return false;
        }

        print('Debug: Including ${cattle.tagNo} - sex: ${cattle.sex}, classification: ${cattle.classification}');
        return true;
      }).toList();

      // Sort cattle by tag number
      availableCattle.sort((a, b) => a.tagNo.compareTo(b.tagNo));

      print('Debug: Available cattle after filtering: ${availableCattle.length}');

      setState(() {
        _allCattle = availableCattle;
        _availableCattle = availableCattle;
        _isLoading = false;
      });
    } catch (e) {
      print('Debug: Error loading cattle: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Failed to load cattle: $e');
      }
    }
  }

  bool _isEventTypeValidForGender(String eventType, String sex) {
    final sexLower = sex.toLowerCase();

    switch (eventType) {
      case 'dry off':
      case 'breeding':
        return sexLower == 'female';
      case 'treated':
      case 'vaccinated':
      case 'deworming':
      case 'hoof trimming':
        return true; // Valid for both sexs
      default:
        return true;
    }
  }

  bool _isEventTypeValidForClassification(String eventType, String classification) {
    final classificationLower = classification.toLowerCase();

    switch (eventType) {
      case 'breeding':
        // For breeding event, only allow Bull, Heifer, Cow (matching PHP logic)
        final allowedClassifications = ['bull', 'heifer', 'cow'];
        return allowedClassifications.contains(classificationLower);

      case 'dry off':
        // Dry off is only for Cow (matching PHP logic)
        return classificationLower == 'cow';

      case 'gives birth':
        // Gives Birth is only for Heifer and Cow (matching PHP logic)
        final allowedForGivesBirth = ['heifer', 'cow'];
        return allowedForGivesBirth.contains(classificationLower);

      case 'pregnant':
        // Pregnant is only for Heifer and Cow (matching PHP logic)
        final allowedForPregnant = ['heifer', 'cow'];
        return allowedForPregnant.contains(classificationLower);

      case 'aborted pregnancy':
        // Aborted Pregnancy is only for Heifer and Cow (matching PHP logic)
        final allowedForAborted = ['heifer', 'cow'];
        return allowedForAborted.contains(classificationLower);

      case 'castrated':
        // Castrated is only for Calf (matching PHP logic)
        return classificationLower == 'calf';

      case 'weaned':
        // Weaned is only for Calf (matching PHP logic)
        return classificationLower == 'calf';

      case 'sold':
        // Sold is not available for Calf (matching PHP logic)
        return classificationLower != 'calf';

      case 'treated':
      case 'weighed':
      case 'vaccinated':
      case 'deworming':
      case 'hoof trimming':
      case 'mortality':
      case 'lost':
      case 'other':
      default:
        // Other history are valid for all classifications
        return true;
    }
  }

  void _filterCattle(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _availableCattle = _allCattle;
      } else {
        _availableCattle = _allCattle.where((cattle) {
          final tagNo = cattle.tagNo.toLowerCase();
          final queryLower = query.toLowerCase();
          return tagNo.contains(queryLower);
        }).toList();
      }

      // Update select all state based on filtered results
      if (_availableCattle.isNotEmpty) {
        _selectAll = _availableCattle.every((cattle) => _selectedCattleTags.contains(cattle.tagNo));
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        // Clear selection for visible cattle
        for (final cattle in _availableCattle) {
          _selectedCattleTags.remove(cattle.tagNo);
        }
        _selectAll = false;
      } else {
        // Select all visible cattle
        for (final cattle in _availableCattle) {
          _selectedCattleTags.add(cattle.tagNo);
        }
        _selectAll = true;
      }
    });
  }

  void _clearAllSelection() {
    setState(() {
      _selectedCattleTags.clear();
      _selectAll = false;
    });
  }

  void _toggleCattleSelection(String tagNo) {
    setState(() {
      if (_selectedCattleTags.contains(tagNo)) {
        _selectedCattleTags.remove(tagNo);
      } else {
        _selectedCattleTags.add(tagNo);
      }

      // Update select all state
      if (_availableCattle.isNotEmpty) {
        _selectAll = _availableCattle.every((cattle) => _selectedCattleTags.contains(cattle.tagNo));
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _eventDateController.text = formattedDate;
      });
    }
  }

  Future<void> _duplicateEvents() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCattleTags.isEmpty) {
      _showErrorSnackBar('Please select at least one cattle to duplicate the event to.');
      return;
    }

    setState(() => _isDuplicating = true);

    try {
      int successCount = 0;
      int failedCount = 0;
      final List<String> failedTags = [];

      for (final cattleTag in _selectedCattleTags) {
        try {
            final eventData = {
            'cattle_tag': cattleTag,
            'bull_tag': widget.originalEvent['bull_tag'],
            'calf_tag': widget.originalEvent['calf_tag'],
            'history_type': widget.originalEvent['history_type'],
            'history_date': _eventDateController.text,
              'disease_type': widget.originalEvent['disease_type'],
            'diagnosis': widget.originalEvent['diagnosis'],
            'technician': widget.originalEvent['technician'],
            'medicine_given': widget.originalEvent['medicine_given'],
            'semen_used': widget.originalEvent['semen_used'],
            'estimated_return_date': widget.originalEvent['estimated_return_date'],
            'weighed_result': widget.originalEvent['weighed_result'],
            'breeding_date': widget.originalEvent['breeding_date'],
            'expected_delivery_date': widget.originalEvent['expected_delivery_date'],
            'notes': widget.originalEvent['notes'],
          };

          final success = await CattleHistoryService.storeCattleHistory(eventData);
          if (success) {
            successCount++;
          } else {
            failedCount++;
            failedTags.add(cattleTag);
          }
        } catch (e) {
          failedCount++;
          failedTags.add(cattleTag);
          print('Debug: Error duplicating event for $cattleTag: $e');
        }
      }

      if (mounted) {
        if (successCount > 0) {
          _showSuccessSnackBar(
              'Successfully duplicated event to $successCount cattle${failedCount > 0 ? '. Failed for $failedCount cattle: ${failedTags.join(', ')}' : '.'}'
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          _showErrorSnackBar('Failed to duplicate event to any cattle.');
        }
      }
    } catch (e) {
      print('Debug: Error in _duplicateEvents: $e');
      if (mounted) {
        _showErrorSnackBar('Error duplicating event: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDuplicating = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.vibrantGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getEventDescription(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'breeding':
        return 'Only showing Bull, Growers, Heifer, and Cow classifications';
      case 'dry off':
        return 'Only showing female cattle (Heifer, Cow)';
      default:
        return 'Showing all compatible cattle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventType = widget.originalEvent['history_type']?.toString() ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.vibrantGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.copy,
                      color: AppColors.vibrantGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duplicate Event',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Event Date Field
              TextFormField(
                controller: _eventDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'History Date',
                  prefixIcon: const Icon(FontAwesomeIcons.calendarDays, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onPressed: _selectDate,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an event date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Search and Controls
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search cattle by tag...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.lightGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: _filterCattle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'select_all',
                        child: Row(
                          children: [
                            Icon(Icons.select_all, color: AppColors.vibrantGreen, size: 20),
                            const SizedBox(width: 8),
                            const Text('Select All Visible'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, color: Colors.orange.shade600, size: 20),
                            const SizedBox(width: 8),
                            const Text('Clear All'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'select_all') {
                        _toggleSelectAll();
                      } else if (value == 'clear_all') {
                        _clearAllSelection();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selection Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.vibrantGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedCattleTags.length} of ${_availableCattle.length} cattle selected',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cattle List
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: AppColors.vibrantGreen),
                )
                    : _availableCattle.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isEmpty
                            ? Icons.pets_outlined
                            : Icons.search_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No compatible cattle found'
                            : 'No cattle match your search',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEventDescription(eventType),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    itemCount: _availableCattle.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final cattle = _availableCattle[index];
                      final isSelected = _selectedCattleTags.contains(cattle.tagNo);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleCattleSelection(cattle.tagNo),
                        title: Text(
                          cattle.tagNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cattle.sex} • ${cattle.classification} • ${cattle.status}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        activeColor: AppColors.vibrantGreen,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        dense: true,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDuplicating ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.lightGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isDuplicating || _selectedCattleTags.isEmpty
                          ? null
                          : _duplicateEvents,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vibrantGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      // Use a conditional expression to show either the loading indicator or the text
                      child: _isDuplicating
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Duplicate (${_selectedCattleTags.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}