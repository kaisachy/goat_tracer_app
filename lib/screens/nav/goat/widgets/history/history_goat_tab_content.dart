// lib/screens/nav/goat/widgets/history/history_goat_tab_content.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/services/goat/goat_history_service.dart';
import 'package:goat_tracer_app/screens/nav/goat/widgets/history/history_search_filter_bar.dart';
import '../../goat_history_form_screen.dart';
import '../../modals/history_duplication_modal.dart';
import 'package:goat_tracer_app/utils/history_type_utils.dart';

class HistorygoatTabContent extends StatefulWidget {
  final Goat goat;
  final VoidCallback onAddEvent;

  const HistorygoatTabContent({
    super.key,
    required this.goat,
    required this.onAddEvent,
  });

  @override
  State<HistorygoatTabContent> createState() => _HistorygoatTabContentState();
}

class _HistorygoatTabContentState extends State<HistorygoatTabContent> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String selectedEventType = 'All';
  Set<int> expandedCards = <int>{};

  List<String> get eventTypes {
    // Comprehensive event types for female goat - includes all available event types
    final femaleEventTypes = [
      'All', 'Dry off', 'Sick', 'Treated', 'Breeding', 'Weighed', 'Kidding',
      'Vaccinated', 'Pregnant', 'Aborted', 'Deworming',
      'Hoof Trimming', 'Weaned', 'Mortality', 'Lost', 'Sold', 'Other',
    ];

    // Comprehensive event types for male goat - includes all available event types
    final maleEventTypes = [
      'All', 'Sick', 'Treated', 'Breeding', 'Weighed', 'Vaccinated', 'Deworming',
      'Hoof Trimming', 'Castrated', 'Weaned', 'Mortality', 'Lost', 'Sold', 'Other',
    ];

    // Check goat sex and return appropriate event types
    final sex = widget.goat.sex.toLowerCase();
    return sex == 'female' ? femaleEventTypes : maleEventTypes;
  }

  // List of event types that can be duplicated
  final List<String> _duplicatableEventTypes = [
    'dry off',
    'treated',
    'breeding',
    'vaccinated',
    'deworming',
    'hoof trimming',
    'mortality',
    'lost',
    'sold',
  ];

  @override
  void initState() {
    super.initState();
    _loadgoatEvents();
  }

  Future<void> _loadgoatEvents() async {
    try {
      setState(() => isLoading = true);
      
      // Use the proper method to get history by Goat Tag
      final goatEvents = await GoatHistoryService.getgoatHistoryByTag(widget.goat.tagNo);

      // Ensure we only keep events that belong to the current goat
      final filteredEvents = _filterEventsForCurrentGoat(goatEvents);

      // Remove duplicates and delete them from database
      final uniqueEvents = await _removeDuplicateEventsFromDB(filteredEvents);

      // Sort history by date to find the latest one
      uniqueEvents.sort((a, b) {
        final dateA = DateTime.tryParse(a['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Descending order (latest first)
      });

      if (mounted) {
        setState(() {
          events = uniqueEvents;
          isLoading = false;
          error = null;

          // Auto-expand the latest history record (index 0 after sorting)
          if (events.isNotEmpty) {
            expandedCards.add(0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load history: $e';
          isLoading = false;
        });
      }
    }
  }

// Helper method to remove duplicate history records and delete them from database
  Future<List<Map<String, dynamic>>> _removeDuplicateEventsFromDB(List<Map<String, dynamic>> events) async {
    final List<Map<String, dynamic>> uniqueEvents = [];
    final List<Map<String, dynamic>> duplicatesToDelete = [];
    int deletedCount = 0;

    for (final event in events) {
      final existingEventIndex = uniqueEvents.indexWhere((existingEvent) =>
          _areEventsIdentical(event, existingEvent));

      if (existingEventIndex == -1) {
        // No duplicate found, add to unique event
        uniqueEvents.add(event);
      } else {
        // Duplicate found - decide which one to keep and which to delete
        final existingEvent = uniqueEvents[existingEventIndex];
        final currentEventDate = DateTime.tryParse(event['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        final existingEventDate = DateTime.tryParse(existingEvent['history_date'] ?? '1900-01-01') ?? DateTime(1900);

        // Keep the more recent event, or the one with higher ID if dates are same
        if (currentEventDate.isAfter(existingEventDate) ||
            (currentEventDate == existingEventDate && (event['id'] ?? 0) > (existingEvent['id'] ?? 0))) {
          // Current event is newer/better, replace existing and mark old for deletion
          duplicatesToDelete.add(existingEvent);
          uniqueEvents[existingEventIndex] = event;
        } else {
          // Existing event is newer/better, mark current for deletion
          duplicatesToDelete.add(event);
        }
      }
    }

    // Delete duplicates from database
    if (duplicatesToDelete.isNotEmpty) {
      try {
        for (final duplicate in duplicatesToDelete) {
          final eventId = duplicate['id'];
          if (eventId != null) {
            final success = await GoatHistoryService.deletegoatHistory(eventId);
            if (success) {
              deletedCount++;
            } else {
              debugPrint('Failed to delete duplicate event with ID: $eventId');
            }
          }
        }

        // Show notification about deleted duplicates
        if (mounted && deletedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed $deletedCount duplicate history record${deletedCount > 1 ? 's' : ''} from database'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting duplicate event: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Some duplicate history record could not be removed from database'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }

    return uniqueEvents;
  }

// Helper method to check if two history records are identical
  bool _areEventsIdentical(Map<String, dynamic> event1, Map<String, dynamic> event2) {
    // Get the history type to determine which fields to compare
    final historyType1 = (event1['history_type'] ?? '').toString().toLowerCase();
    final historyType2 = (event2['history_type'] ?? '').toString().toLowerCase();

    // If history types are different, they're not identical
    if (historyType1 != historyType2) return false;

    // Compare basic fields that are always relevant
    if (!_compareFieldValues(event1['history_date'], event2['history_date'])) return false;
    if (!_compareFieldValues(event1['goat_tag'], event2['goat_tag'])) return false;
    if (!_compareFieldValues(event1['notes'], event2['notes'])) return false;

    // Compare history-specific fields based on history type
    switch (historyType1) {
      case 'dry off':
      // Only basic fields matter for dry off
        return true;

      case 'sick':
        return _compareFieldValues(event1['disease_type'], event2['disease_type']);

      case 'treated':
        return _compareFieldValues(event1['disease_type'], event2['disease_type']) &&
            _compareFieldValues(event1['diagnosis'], event2['diagnosis']) &&
            _compareFieldValues(event1['technician'], event2['technician']) &&
            _compareFieldValues(event1['medicine_given'], event2['medicine_given']);

      case 'breeding':
        return _compareFieldValues(event1['semen_used'], event2['semen_used']) &&
            _compareFieldValues(event1['technician'], event2['technician']) &&
            _compareFieldValues(event1['estimated_return_date'], event2['estimated_return_date']);

      case 'weighed':
        return _compareFieldValues(event1['weighed_result'], event2['weighed_result']);

      case 'kidding':
        return _compareFieldValues(event1['Buck_tag'], event2['Buck_tag']) &&
            _compareFieldValues(event1['Kid_tag'], event2['Kid_tag']);

      case 'vaccinated':
        return _compareFieldValues(event1['medicine_given'], event2['medicine_given']) &&
            _compareFieldValues(event1['technician'], event2['technician']);

      case 'pregnant':
        return _compareFieldValues(event1['breeding_date'], event2['breeding_date']) &&
            _compareFieldValues(event1['expected_delivery_date'], event2['expected_delivery_date']) &&
            _compareFieldValues(event1['Buck_tag'], event2['Buck_tag']);

      case 'aborted':
      // Only basic fields matter for aborted
        return true;

      case 'deworming':
        return _compareFieldValues(event1['medicine_given'], event2['medicine_given']);

      case 'hoof trimming':
      // Only basic fields matter for hoof trimming
        return true;

      case 'castrated':
        return _compareFieldValues(event1['technician'], event2['technician']);

      case 'weaned':
      // Only basic fields matter for weaned
        return true;

      case 'mortality':
        return _compareFieldValues(event1['cause_of_death'], event2['cause_of_death']);

      case 'sold':
        return _compareFieldValues(event1['sold_amount'], event2['sold_amount']) &&
            _compareFieldValues(event1['buyer'], event2['buyer']);

      case 'lost':
        return _compareFieldValues(event1['last_known_location'], event2['last_known_location']);

      case 'other':
      default:
      // For 'other' history records, compare all potentially relevant fields
        return _compareFieldValues(event1['Buck_tag'], event2['Buck_tag']) &&
            _compareFieldValues(event1['Kid_tag'], event2['Kid_tag']) &&
            _compareFieldValues(event1['technician'], event2['technician']) &&
            _compareFieldValues(event1['sickness_symptoms'], event2['sickness_symptoms']) &&
            _compareFieldValues(event1['diagnosis'], event2['diagnosis']) &&
            _compareFieldValues(event1['medicine_given'], event2['medicine_given']) &&
            _compareFieldValues(event1['semen_used'], event2['semen_used']) &&
            _compareFieldValues(event1['estimated_return_date'], event2['estimated_return_date']) &&
            _compareFieldValues(event1['weighed_result'], event2['weighed_result']) &&
            _compareFieldValues(event1['breeding_date'], event2['breeding_date']) &&
            _compareFieldValues(event1['expected_delivery_date'], event2['expected_delivery_date']) &&
            _compareFieldValues(event1['sold_amount'], event2['sold_amount']) &&
            _compareFieldValues(event1['buyer'], event2['buyer']) &&
            _compareFieldValues(event1['last_known_location'], event2['last_known_location']);
    }
  }

// Helper method to compare field values, treating null, empty, and 'N/A' as equivalent
  bool _compareFieldValues(dynamic value1, dynamic value2) {
    final normalizedValue1 = _normalizeFieldValue(value1);
    final normalizedValue2 = _normalizeFieldValue(value2);

    return normalizedValue1 == normalizedValue2;
  }

// Helper method to normalize field values for comparison
  String? _normalizeFieldValue(dynamic value) {
    if (value == null) return null;

    final stringValue = value.toString().trim();

    // Treat empty strings and 'N/A' as null
    if (stringValue.isEmpty || stringValue.toLowerCase() == 'n/a') {
      return null;
    }

    return stringValue.toLowerCase();
  }

  Future<void> _refreshEvents() async => await _loadgoatEvents();
  
  // Public method to refresh events (called from parent widget)
  Future<void> refresh() => _refreshEvents();

  List<Map<String, dynamic>> get _filteredEvents {
    return events.where((event) {
      final type = (event['history_type'] ?? '').toString().toLowerCase();
      final notes = (event['notes'] ?? '').toString().toLowerCase();
      final diagnosis = (event['diagnosis'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      final matchesSearch = type.contains(query) ||
          notes.contains(query) ||
          diagnosis.contains(query);

      final matchesFilter = selectedEventType == 'All' ||
          type == selectedEventType.toLowerCase();

      // Show all events regardless of goat sex or type (archived goat should see everything)
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() => searchQuery = query);
  }

  void _onFilterChanged(String filter) {
    setState(() => selectedEventType = filter);
  }

  void _onClearFilter() {
    setState(() => selectedEventType = 'All');
  }

  // Check if an event type can be duplicated
  bool _canDuplicateEvent(String eventType) {
    return _duplicatableEventTypes.contains(eventType.toLowerCase());
  }

  bool _isAutoGeneratedBuckBreeding(Map<String, dynamic> event) {
    final eventType = (event['history_type'] ?? '').toString().toLowerCase();
    if (eventType != 'breeding') return false;
    final notes = (event['notes'] ?? '').toString().toLowerCase();
    return notes.startsWith('breeding with');
  }

  void _showEventMenu(BuildContext context, Map<String, dynamic> event, int index) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final eventType = event['history_type']?.toString() ?? '';
    final eventTypeLower = eventType.toLowerCase();
    final isAutoBuckBreeding = _isAutoGeneratedBuckBreeding(event);
    final canDuplicate = eventTypeLower != 'vaccinated' &&
        !isAutoBuckBreeding &&
        _canDuplicateEvent(eventType);
    final canEdit = eventTypeLower != 'vaccinated' && !isAutoBuckBreeding;

    showMenu(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        if (canDuplicate)
          PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Text('Duplicate History Record'),
              ],
            ),
          ),
        if (canEdit)
        if (canEdit)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: AppColors.vibrantGreen, size: 20),
                const SizedBox(width: 12),
                const Text('Edit History Record'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (value == 'duplicate') {
          _duplicateEvent(event);
        } else if (value == 'edit') {
          _editEvent(event);
        } else if (value == 'delete') {
          _deleteEvent(event);
        }
      }
    });
  }

  void _duplicateEvent(Map<String, dynamic> event) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return HistoryDuplicationModal(originalEvent: event);
        },
      );

      // If duplication was successful, refresh the event list
      if (result == true) {
        await _refreshEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening duplication modal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _editEvent(Map<String, dynamic> event) async {
    try {
      // Create a goatEvent object from the event data
      final goatEvent = GoatHistoryRecord(
        id: event['id'] ?? 0,
        userId: event['user_id'] ?? 0,
        goatTag: event['goat_tag']?.toString() ?? '',
        buckTag: event['buck_tag']?.toString() ?? event['Buck_tag']?.toString(),
        kidTag: event['kid_tag']?.toString() ?? event['Kid_tag']?.toString(),
        historyType: event['history_type']?.toString() ?? '',
        historyDate: event['history_date']?.toString() ?? '',
        sicknessSymptoms: event['sickness_symptoms']?.toString(),
        diagnosis: event['diagnosis']?.toString(),
        technician: event['technician']?.toString(),
        medicineGiven: event['medicine_given']?.toString(),
        semenUsed: event['semen_used']?.toString(),
        estimatedReturnDate: event['estimated_return_date']?.toString(),
        weighedResult: event['weighed_result'] != null
            ? double.tryParse(event['weighed_result'].toString())
            : null,
        breedingDate: event['breeding_date']?.toString(),
        expectedDeliveryDate: event['expected_delivery_date']?.toString(),
        notes: event['notes']?.toString(),
        lastKnownLocation: event['last_known_location']?.toString(),
        soldAmount: event['sold_amount'] != null
            ? double.tryParse(event['sold_amount'].toString())
            : null,
        buyer: event['buyer']?.toString(),
        diseaseType: event['disease_type']?.toString(),
        diseaseTypeOther: event['disease_type_other']?.toString(),
      );

      // Navigate to edit screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoatHistoryFormScreen(
            historyRecord: goatEvent,
            goatTag: widget.goat.tagNo,
          ),
        ),
      );

      // If edit was successful, refresh the event list
      if (result == true) {
        await _refreshEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('History record updated successfully!'),
              backgroundColor: AppColors.vibrantGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening edit screen: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _deleteEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Widget buildInfoRow(IconData icon, String label, String value) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final historyType = (event['history_type'] ?? 'History').toString();
        final historyDate = _formatDate(event['history_date']);

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(
                      bottom: BorderSide(color: Colors.red.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delete History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'This action cannot be undone',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Removing this history record will permanently erase it from the timeline.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildInfoRow(Icons.timeline_rounded, 'History Type', historyType),
                            buildInfoRow(Icons.tag_rounded, 'Goat Tag', widget.goat.tagNo),
                            buildInfoRow(Icons.calendar_today_rounded, 'Date', historyDate),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _performDelete(event);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            shadowColor: Colors.red.shade200,
                          ),
                          child: const Text('Delete Record'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performDelete(Map<String, dynamic> event) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Deleting history record...'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 10), // Longer duration for loading
          ),
        );
      }

      // Call the delete API
      final success = await GoatHistoryService.deletegoatHistory(event['id']);

      // Clear any existing snackbars
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (success) {
        // Refresh the event list
        await _refreshEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('History record "${event['history_type']}" deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete history record "${event['history_type']}"'),
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
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting history record: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      child: Column(
        children: [
          HistorySearchFilterBar(
            initialSearchQuery: searchQuery,
            initialEventType: selectedEventType,
            eventTypes: eventTypes,
            onSearchChanged: _onSearchChanged,
            onFilterChanged: _onFilterChanged,
            onClearFilter: _onClearFilter,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshEvents,
              color: AppColors.vibrantGreen,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.vibrantGreen))
                  : error != null
                  ? _buildErrorState()
                  : _filteredEvents.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _filteredEvents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildEventAccordion(_filteredEvents[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEventAccordion(Map<String, dynamic> event, int index) {
    final eventType = event['history_type'] ?? 'Unknown';
    final eventDate = event['history_date'];
    final eventColor = HistoryTypeUtils.getHistoryColor(eventType);
    final details = _getEventDetails(event);
    final isExpanded = expandedCards.contains(index);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: eventColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: eventColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header - Always visible (clickable)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedCards.remove(index);
                } else {
                  expandedCards.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: eventColor.withValues(alpha: 0.3)),
                    ),
                    child: _buildHistoryIcon(eventType, eventColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: eventColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(eventDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          onPressed: () => _showEventMenu(context, event, index),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          tooltip: 'More options',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: eventColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expandable Details section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded && details.isNotEmpty ? null : 0,
            child: isExpanded && details.isNotEmpty
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: eventColor.withValues(alpha: 0.2),
                    margin: const EdgeInsets.only(bottom: 16),
                  ),
                  ...details.asMap().entries.map((entry) {
                    final index = entry.key;
                    final detail = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildDetailRow(detail.key, detail.value),
                      ],
                    );
                  }),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryIcon(String historyType, Color color) {
    final imagePath = HistoryTypeUtils.getHistoryImagePath(historyType);
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: 24);
        },
      );
    } else {
      return Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: 24);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  String? _normalizeEventValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'n/a') {
        return null;
      }
      return trimmed;
    }
    final stringValue = value.toString().trim();
    if (stringValue.isEmpty || stringValue.toLowerCase() == 'n/a') {
      return null;
    }
    return stringValue;
  }

  List<Map<String, dynamic>> _filterEventsForCurrentGoat(List<Map<String, dynamic>> events) {
    final targetTag = _normalizeEventValue(widget.goat.tagNo);
    if (targetTag == null) return [];

    return events.where((event) {
      final eventTag = _getEventFieldValue(
        event,
        ['goat_tag', 'Goat_tag', 'goatTag', 'GoatTag', 'tag_no', 'tagNo'],
      );
      if (eventTag == null) return false;

      return eventTag.toLowerCase() == targetTag.toLowerCase();
    }).toList();
  }

  String? _getEventFieldValue(
    Map<String, dynamic> event,
    List<String> candidateKeys,
  ) {
    if (event.isEmpty) return null;

    final normalized = <String, dynamic>{};
    event.forEach((key, value) {
      normalized[key.toString().toLowerCase()] = value;
    });

    for (final key in candidateKeys) {
      dynamic raw;
      if (event.containsKey(key)) {
        raw = event[key];
      } else {
        raw = normalized[key.toLowerCase()];
      }

      final normalizedValue = _normalizeEventValue(raw);
      if (normalizedValue != null) {
        return normalizedValue;
      }
    }
    return null;
  }

  List<String> _extractKidTags(Map<String, dynamic> event) {
    final tags = <String>[];

    void addTag(dynamic value) {
      final normalizedTag = _normalizeEventValue(value);
      if (normalizedTag != null && normalizedTag.isNotEmpty) {
        tags.add(normalizedTag);
      }
    }

    void collectFromEntry(dynamic entry) {
      if (entry is Map<String, dynamic>) {
        final tag = _getEventFieldValue(
          entry,
          ['Kid_tag', 'kid_tag', 'KidTag', 'kidTag', 'tag', 'Tag', 'tag_no', 'tagNo'],
        );
        if (tag != null) {
          tags.add(tag);
        }
      } else if (entry is Map) {
        collectFromEntry(
          entry.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      } else if (entry is Iterable) {
        for (final nested in entry) {
          collectFromEntry(nested);
        }
      } else if (entry is String) {
        addTag(entry);
      }
    }

    final dynamic kidDataRaw = event['Kid_data'] ?? event['kid_data'];
    if (kidDataRaw is String && kidDataRaw.trim().isNotEmpty) {
      final raw = kidDataRaw.trim();
      try {
        final decoded = jsonDecode(raw);
        collectFromEntry(decoded);
      } catch (_) {
        for (final chunk in raw.split(',')) {
          addTag(chunk);
        }
      }
    } else if (kidDataRaw is Iterable) {
      collectFromEntry(kidDataRaw);
    } else if (kidDataRaw is Map) {
      collectFromEntry(kidDataRaw);
    }

    if (tags.isEmpty) {
      final fallback = _getEventFieldValue(
        event,
        ['Kid_tag', 'kid_tag', 'KidTag', 'kidTag', 'Kid_tags', 'kid_tags'],
      );
      if (fallback != null) {
        if (fallback.contains(',')) {
          for (final chunk in fallback.split(',')) {
            addTag(chunk);
          }
        } else {
          addTag(fallback);
        }
      }
    }

    final deduped = <String>{};
    for (final tag in tags) {
      final normalized = tag.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalized.isNotEmpty) {
        deduped.add(normalized);
      }
    }

    return deduped.toList();
  }

  List<MapEntry<String, String>> _getEventDetails(Map<String, dynamic> event) {
    final eventType = (event['history_type'] ?? '').toString().toLowerCase();
    final Map<String, String?> relevantDetails = {};

    // Always show notes if available
    if (event['notes'] != null && event['notes'].toString().isNotEmpty && event['notes'] != 'N/A') {
      relevantDetails['Notes'] = event['notes'].toString();
    }

    // Add event-specific fields based on event type
    switch (eventType) {
      case 'sick':
        if (event['disease_type'] != null && event['disease_type'].toString().isNotEmpty && event['disease_type'] != 'N/A') {
          relevantDetails['Type of Disease'] = event['disease_type'].toString();
        }
        break;
      case 'dry off':
      // No additional fields for dry off
        break;

      case 'treated':
        if (event['disease_type'] != null && event['disease_type'].toString().isNotEmpty && event['disease_type'] != 'N/A') {
          relevantDetails['Type of Disease'] = event['disease_type'].toString();
        }
        if (event['diagnosis'] != null && event['diagnosis'].toString().isNotEmpty && event['diagnosis'] != 'N/A') {
          relevantDetails['Diagnosis'] = event['diagnosis'].toString();
        }
        if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
          relevantDetails['Technician'] = event['technician'].toString();
        }
        if (event['medicine_given'] != null && event['medicine_given'].toString().isNotEmpty && event['medicine_given'] != 'N/A') {
          relevantDetails['Medicine Given'] = event['medicine_given'].toString();
        }
        break;

      case 'breeding':
        // Check breeding type to determine which fields to show
        final breedingType = event['breeding_type']?.toString().toLowerCase();
        
        if (breedingType == 'artificial_insemination') {
          // For AI breeding, show semen and technician
          if (event['semen_used'] != null && event['semen_used'].toString().isNotEmpty && event['semen_used'] != 'N/A') {
            relevantDetails['Semen Used'] = event['semen_used'].toString();
          }
          if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
            relevantDetails['Technician'] = event['technician'].toString();
          }
        } else if (breedingType == 'natural_breeding') {
          // For natural breeding, show Buck tag only when viewing a female (Doe/Doeling) profile
          final goatSex = widget.goat.sex.toLowerCase();
          if (goatSex == 'female') {
            if (event['Buck_tag'] != null && event['Buck_tag'].toString().isNotEmpty && event['Buck_tag'] != 'N/A') {
              relevantDetails['Buck'] = event['Buck_tag'].toString();
            }
          }
        } else {
          // Fallback for history without breeding_type (backward compatibility)
          final hasSemen = event['semen_used'] != null && event['semen_used'].toString().isNotEmpty && event['semen_used'] != 'N/A';
          if (hasSemen) {
            // If semen is present, prefer showing semen and not Buck
            relevantDetails['Semen Used'] = event['semen_used'].toString();
          }
          if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
            relevantDetails['Technician'] = event['technician'].toString();
          }
          // Only show Buck when semen is not available and viewing a female profile
          final goatSex = widget.goat.sex.toLowerCase();
          if (goatSex == 'female') {
            if (!hasSemen && event['Buck_tag'] != null && event['Buck_tag'].toString().isNotEmpty && event['Buck_tag'] != 'N/A') {
              relevantDetails['Buck'] = event['Buck_tag'].toString();
            }
          }
        }
        
        // Show estimated return to heat date for female goat
        final goatSex = widget.goat.sex.toLowerCase();
        if (goatSex == 'female' && event['estimated_return_date'] != null && event['estimated_return_date'].toString().isNotEmpty && event['estimated_return_date'] != 'N/A') {
          relevantDetails['Return to Heat'] = _formatDate(event['estimated_return_date']);
        }
        break;

      case 'weighed':
        if (event['weighed_result'] != null && event['weighed_result'].toString().isNotEmpty && event['weighed_result'] != 'N/A') {
          relevantDetails['Weight (kg)'] = event['weighed_result'].toString();
        }
        break;

      case 'kidding':
        final buckTag = _getEventFieldValue(
          event,
          [
            'Buck_tag',
            'buck_tag',
            'BuckTag',
            'buckTag',
            'partner_tag',
            'partnerTag',
            'sire_tag',
            'Sire_tag',
          ],
        );
        if (buckTag != null) {
          relevantDetails['Buck Tag (Father)'] = buckTag;
        }

        final kidTags = _extractKidTags(event);
        if (kidTags.isNotEmpty) {
          relevantDetails[kidTags.length > 1 ? 'Kid Tags' : 'Kid Tag'] = kidTags.join(', ');
          relevantDetails['Litter Size'] = '${kidTags.length}';
        } else {
          relevantDetails['Kid Tag'] = '—';
          relevantDetails['Litter Size'] = '0';
        }
        break;

      case 'vaccinated':
        if (event['medicine_given'] != null && event['medicine_given'].toString().isNotEmpty && event['medicine_given'] != 'N/A') {
          relevantDetails['Vaccine Given'] = event['medicine_given'].toString();
        }
        if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
          relevantDetails['Technician'] = event['technician'].toString();
        }
        break;

      case 'pregnant':
        if (event['breeding_date'] != null && event['breeding_date'].toString().isNotEmpty && event['breeding_date'] != 'N/A') {
          relevantDetails['Breeding Date'] = _formatDate(event['breeding_date']);
        }
        if (event['expected_delivery_date'] != null && event['expected_delivery_date'].toString().isNotEmpty && event['expected_delivery_date'] != 'N/A') {
          relevantDetails['Expected Delivery'] = _formatDate(event['expected_delivery_date']);
        }
        if (event['Buck_tag'] != null && event['Buck_tag'].toString().isNotEmpty && event['Buck_tag'] != 'N/A') {
          relevantDetails['Buck Tag (Father)'] = event['Buck_tag'].toString();
        }
        break;

      case 'aborted':
      // No additional fields for aborted
        break;

      case 'deworming':
        if (event['medicine_given'] != null && event['medicine_given'].toString().isNotEmpty && event['medicine_given'] != 'N/A') {
          relevantDetails['Deworming Medicine'] = event['medicine_given'].toString();
        }
        break;

      case 'hoof trimming':
      // No additional fields for hoof trimming
        break;

      case 'castrated':
        if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
          relevantDetails['Technician'] = event['technician'].toString();
        }
        break;

      case 'weaned':
      // No additional fields for weaned
        break;

      case 'mortality':
        if (event['cause_of_death'] != null && event['cause_of_death'].toString().isNotEmpty && event['cause_of_death'] != 'N/A') {
          relevantDetails['Cause of Death'] = event['cause_of_death'].toString();
        }
        break;

      case 'lost':
        if (event['last_known_location'] != null && event['last_known_location'].toString().isNotEmpty && event['last_known_location'] != 'N/A') {
          relevantDetails['Last Known Location'] = event['last_known_location'].toString();
        }
        break;

      case 'sold':
        if (event['sold_amount'] != null && event['sold_amount'].toString().isNotEmpty && event['sold_amount'] != 'N/A') {
          relevantDetails['Sold Amount'] = '₱${event['sold_amount'].toString()}';
        }
        if (event['buyer'] != null && event['buyer'].toString().isNotEmpty && event['buyer'] != 'N/A') {
          relevantDetails['Seller'] = event['buyer'].toString();
        }
        break;

      case 'other':
      // For 'other' history records, only show notes (no additional details)
        break;
      default:
        // For any other history types, show basic information
        break;
    }

    return relevantDetails.entries
        .map((entry) => MapEntry(entry.key, entry.value!))
        .toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEmptyState() {
    final bool isFiltering = searchQuery.isNotEmpty || selectedEventType != 'All';

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.lightGreen.withValues(alpha: 0.1),
                      AppColors.vibrantGreen.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  isFiltering ? Icons.search_off_rounded : Icons.event_note_rounded,
                  size: 60,
                  color: AppColors.lightGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFiltering ? 'No Results Found' : 'No History Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFiltering
                    ? 'Try adjusting your search or filter\nto find what you\'re looking for.'
                    : 'No history records have been recorded for this goat yet.\nTap "Add History Record" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Icon(Icons.error_outline_rounded,
                    size: 64, color: Colors.red.shade400),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _refreshEvents,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
