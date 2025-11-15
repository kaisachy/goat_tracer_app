// lib/screens/nav/goat/modals/event_duplication_modal.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/goat.dart';
import '../../../../services/goat/goat_service.dart';
import '../../../../services/goat/goat_history_service.dart';

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

  List<Goat> _allGoat = [];
  List<Goat> _availableGoat = [];
  final Set<String> _selectedGoatTags = <String>{};
  bool _isLoading = true;
  bool _isDuplicating = false;
  bool _selectAll = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeEventDate();
    _loadAvailablegoat();
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

  Future<void> _loadAvailablegoat() async {
    try {
      setState(() => _isLoading = true);

      final allGoats = await GoatService.getAllGoats();
      final originalEventType = widget.originalEvent['history_type']?.toString().toLowerCase() ?? '';
      final originalgoatTag = widget.originalEvent['goat_tag']?.toString() ?? '';

      debugPrint('Debug: Loading goat for event type: $originalEventType');
      debugPrint('Debug: Total goat loaded: ${allGoats.length}');

      // Filter goat based on event type, sex, classification, and status
      final availableGoat = allGoats.where((goat) {
        // Check if goat is healthy
        if (goat.status.toLowerCase() != 'healthy') {
          debugPrint('Debug: Skipping ${goat.tagNo} - status: ${goat.status}');
          return false;
        }

        // Skip the original goat
        if (goat.tagNo.trim().toLowerCase() == originalgoatTag.trim().toLowerCase()) {
          debugPrint('Debug: Skipping ${goat.tagNo} - original goat');
          return false;
        }

        // Check sex compatibility
        if (!_isEventTypeValidForGender(originalEventType, goat.sex)) {
          debugPrint('Debug: Skipping ${goat.tagNo} - sex incompatible: ${goat.sex}');
          return false;
        }

        // Check classification compatibility for breeding event
        if (!_isEventTypeValidForClassification(originalEventType, goat.classification)) {
          debugPrint('Debug: Skipping ${goat.tagNo} - classification incompatible: ${goat.classification}');
          return false;
        }

        debugPrint('Debug: Including ${goat.tagNo} - sex: ${goat.sex}, classification: ${goat.classification}');
        return true;
      }).toList();

      // Sort goat by tag number
      availableGoat.sort((a, b) => a.tagNo.compareTo(b.tagNo));

      debugPrint('Debug: Available goat after filtering: ${availableGoat.length}');

      setState(() {
        _allGoat = availableGoat;
        _availableGoat = availableGoat;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Debug: Error loading goat: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Failed to load goat: $e');
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
        // For breeding event, only allow Buck, Doeling, Doe (matching PHP logic)
        final allowedClassifications = ['Buck', 'Doeling', 'Doe'];
        return allowedClassifications.contains(classificationLower);

      case 'dry off':
        // Dry off is only for Doe (matching PHP logic)
        return classificationLower == 'Doe';

      case 'gives birth':
        // Gives Birth is only for Doeling and Doe (matching PHP logic)
        final allowedForGivesBirth = ['Doeling', 'Doe'];
        return allowedForGivesBirth.contains(classificationLower);

      case 'pregnant':
        // Pregnant is only for Doeling and Doe (matching PHP logic)
        final allowedForPregnant = ['Doeling', 'Doe'];
        return allowedForPregnant.contains(classificationLower);

      case 'aborted pregnancy':
        // Aborted Pregnancy is only for Doeling and Doe (matching PHP logic)
        final allowedForAborted = ['Doeling', 'Doe'];
        return allowedForAborted.contains(classificationLower);

      case 'castrated':
        // Castrated is only for Kid (matching PHP logic)
        return classificationLower == 'Kid';

      case 'weaned':
        // Weaned is only for Kid (matching PHP logic)
        return classificationLower == 'Kid';

      case 'sold':
        // Sold is not available for Kid (matching PHP logic)
        return classificationLower != 'Kid';

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

  void _filterGoat(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _availableGoat = _allGoat;
      } else {
        _availableGoat = _allGoat.where((goat) {
          final tagNo = goat.tagNo.toLowerCase();
          final queryLower = query.toLowerCase();
          return tagNo.contains(queryLower);
        }).toList();
      }

      // Update select all state based on filtered results
      if (_availableGoat.isNotEmpty) {
        _selectAll = _availableGoat.every((goat) => _selectedGoatTags.contains(goat.tagNo));
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        // Clear selection for visible goat
        for (final goat in _availableGoat) {
          _selectedGoatTags.remove(goat.tagNo);
        }
        _selectAll = false;
      } else {
        // Select all visible goat
        for (final goat in _availableGoat) {
          _selectedGoatTags.add(goat.tagNo);
        }
        _selectAll = true;
      }
    });
  }

  void _clearAllSelection() {
    setState(() {
      _selectedGoatTags.clear();
      _selectAll = false;
    });
  }

  void _togglegoatSelection(String tagNo) {
    setState(() {
      if (_selectedGoatTags.contains(tagNo)) {
        _selectedGoatTags.remove(tagNo);
      } else {
        _selectedGoatTags.add(tagNo);
      }

      // Update select all state
      if (_availableGoat.isNotEmpty) {
        _selectAll = _availableGoat.every((goat) => _selectedGoatTags.contains(goat.tagNo));
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
    if (_selectedGoatTags.isEmpty) {
      _showErrorSnackBar('Please select at least one goat to duplicate the event to.');
      return;
    }

    setState(() => _isDuplicating = true);

    try {
      int successCount = 0;
      int failedCount = 0;
      final List<String> failedTags = [];

      for (final goatTag in _selectedGoatTags) {
        try {
            final eventData = {
            'goat_tag': goatTag,
            'Buck_tag': widget.originalEvent['Buck_tag'],
            'Kid_tag': widget.originalEvent['Kid_tag'],
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

          final success = await GoatHistoryService.storegoatHistory(eventData);
          if (success) {
            successCount++;
          } else {
            failedCount++;
            failedTags.add(goatTag);
          }
        } catch (e) {
          failedCount++;
          failedTags.add(goatTag);
          debugPrint('Debug: Error duplicating event for $goatTag: $e');
        }
      }

      if (mounted) {
        if (successCount > 0) {
          _showSuccessSnackBar(
              'Successfully duplicated event to $successCount goat${failedCount > 0 ? '. Failed for $failedCount goat: ${failedTags.join(', ')}' : '.'}'
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          _showErrorSnackBar('Failed to duplicate event to any goat.');
        }
      }
    } catch (e) {
      debugPrint('Debug: Error in _duplicateEvents: $e');
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
        return 'Only showing Buck, Growers, Doeling, and Doe classifications';
      case 'dry off':
        return 'Only showing female goat (Doeling, Doe)';
      default:
        return 'Showing all compatible goat';
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
                      color: AppColors.vibrantGreen.withValues(alpha: 0.1),
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
                        hintText: 'Search goat by tag...',
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
                      onChanged: _filterGoat,
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
                  color: AppColors.lightGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.vibrantGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedGoatTags.length} of ${_availableGoat.length} goat selected',
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

              // goat List
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: AppColors.vibrantGreen),
                )
                    : _availableGoat.isEmpty
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
                            ? 'No compatible goat found'
                            : 'No goat match your search',
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
                    itemCount: _availableGoat.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final goat = _availableGoat[index];
                      final isSelected = _selectedGoatTags.contains(goat.tagNo);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _togglegoatSelection(goat.tagNo),
                        title: Text(
                          goat.tagNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${goat.sex} • ${goat.classification} • ${goat.status}',
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
                      onPressed: _isDuplicating || _selectedGoatTags.isEmpty
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
                        'Duplicate (${_selectedGoatTags.length})',
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
