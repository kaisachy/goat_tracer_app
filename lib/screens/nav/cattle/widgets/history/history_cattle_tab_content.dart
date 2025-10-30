// lib/screens/nav/cattle/widgets/history/history_cattle_tab_content.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_history_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/history/history_search_filter_bar.dart';
import '../../cattle_history_form_screen.dart';
import '../../modals/history_duplication_modal.dart';
import 'package:cattle_tracer_app/utils/history_type_utils.dart';

class HistoryCattleTabContent extends StatefulWidget {
  final Cattle cattle;
  final VoidCallback onAddEvent;

  const HistoryCattleTabContent({
    super.key,
    required this.cattle,
    required this.onAddEvent,
  });

  @override
  State<HistoryCattleTabContent> createState() => _HistoryCattleTabContentState();
}

class _HistoryCattleTabContentState extends State<HistoryCattleTabContent> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String selectedEventType = 'All';
  Set<int> expandedCards = <int>{};

  List<String> get eventTypes {
    // Comprehensive event types for female cattle - includes all available event types
    final femaleEventTypes = [
      'All', 'Dry off', 'Sick', 'Treated', 'Breeding', 'Weighed', 'Gives Birth',
      'Vaccinated', 'Pregnant', 'Aborted Pregnancy', 'Deworming',
      'Hoof Trimming', 'Weaned', 'Mortality', 'Lost', 'Sold', 'Other',
    ];

    // Comprehensive event types for male cattle - includes all available event types
    final maleEventTypes = [
      'All', 'Sick', 'Treated', 'Breeding', 'Weighed', 'Vaccinated', 'Deworming',
      'Hoof Trimming', 'Castrated', 'Weaned', 'Mortality', 'Lost', 'Sold', 'Other',
    ];

    // Check cattle sex and return appropriate event types
    final sex = widget.cattle.sex.toLowerCase();
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
    _loadCattleEvents();
  }

  Future<void> _loadCattleEvents() async {
    try {
      setState(() => isLoading = true);
      
      // Use the proper method to get history by cattle tag
      final cattleEvents = await CattleHistoryService.getCattleHistoryByTag(widget.cattle.tagNo);

      // Remove duplicates and delete them from database
      final uniqueEvents = await _removeDuplicateEventsFromDB(cattleEvents);

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
            final success = await CattleHistoryService.deleteCattleHistory(eventId);
            if (success) {
              deletedCount++;
            } else {
              print('Failed to delete duplicate event with ID: $eventId');
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
        print('Error deleting duplicate event: $e');
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
    if (!_compareFieldValues(event1['cattle_tag'], event2['cattle_tag'])) return false;
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

      case 'gives birth':
        return _compareFieldValues(event1['bull_tag'], event2['bull_tag']) &&
            _compareFieldValues(event1['calf_tag'], event2['calf_tag']);

      case 'vaccinated':
        return _compareFieldValues(event1['medicine_given'], event2['medicine_given']) &&
            _compareFieldValues(event1['technician'], event2['technician']);

      case 'pregnant':
        return _compareFieldValues(event1['breeding_date'], event2['breeding_date']) &&
            _compareFieldValues(event1['expected_delivery_date'], event2['expected_delivery_date']) &&
            _compareFieldValues(event1['bull_tag'], event2['bull_tag']);

      case 'aborted pregnancy':
      // Only basic fields matter for aborted pregnancy
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
        return _compareFieldValues(event1['bull_tag'], event2['bull_tag']) &&
            _compareFieldValues(event1['calf_tag'], event2['calf_tag']) &&
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

  Future<void> _refreshEvents() async => await _loadCattleEvents();
  
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

      // Additional filter: only show event that are valid for the cattle's sex
      final sex = widget.cattle.sex.toLowerCase();
      final validEventTypes = sex == 'female'
          ? ['dry off', 'sick', 'treated', 'breeding', 'weighed', 'gives birth', 'vaccinated',
        'pregnant', 'aborted pregnancy', 'deworming', 'hoof trimming', 'mortality', 'lost', 'sold', 'other']
          : ['sick', 'treated', 'breeding', 'weighed', 'vaccinated', 'deworming', 'hoof trimming',
        'castrated', 'weaned', 'mortality', 'lost', 'sold', 'other'];

      final matchesSex = validEventTypes.contains(type);

      return matchesSearch && matchesFilter && matchesSex;
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
    final canDuplicate = eventTypeLower != 'vaccinated' && _canDuplicateEvent(eventType);

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
        if (eventTypeLower != 'vaccinated')
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
      // Create a CattleEvent object from the event data
      final cattleEvent = CattleHistoryRecord(
        id: event['id'] ?? 0,
        userId: event['user_id'] ?? 0,
        cattleTag: event['cattle_tag']?.toString() ?? '',
        bullTag: event['bull_tag']?.toString(),
        calfTag: event['calf_tag']?.toString(),
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
      );

      // Navigate to edit screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CattleHistoryFormScreen(
            historyRecord: cattleEvent,
            cattleTag: widget.cattle.tagNo,
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
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade400),
              const SizedBox(width: 8),
              const Text('Delete History Record'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this history record?'),
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
                      '${event['history_type']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Date: ${_formatDate(event['history_date'])}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
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
                _performDelete(event);
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
      final success = await CattleHistoryService.deleteCattleHistory(event['id']);

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
            color: eventColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: eventColor.withOpacity(0.2)),
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
                      color: eventColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: eventColor.withOpacity(0.3)),
                    ),
                    child: Icon(HistoryTypeUtils.getHistoryIcon(eventType), color: eventColor, size: 24),
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
            height: isExpanded && details.isNotEmpty && eventType.toLowerCase() != 'other' ? null : 0,
            child: isExpanded && details.isNotEmpty && eventType.toLowerCase() != 'other'
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
                    color: eventColor.withOpacity(0.2),
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
              color: AppColors.textPrimary.withOpacity(0.7),
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
          // For natural breeding, show bull tag only when viewing a female (cow/heifer) profile
          final cattleSex = widget.cattle.sex.toLowerCase();
          if (cattleSex == 'female') {
            if (event['bull_tag'] != null && event['bull_tag'].toString().isNotEmpty && event['bull_tag'] != 'N/A') {
              relevantDetails['Bull'] = event['bull_tag'].toString();
            }
          }
        } else {
          // Fallback for history without breeding_type (backward compatibility)
          final hasSemen = event['semen_used'] != null && event['semen_used'].toString().isNotEmpty && event['semen_used'] != 'N/A';
          if (hasSemen) {
            // If semen is present, prefer showing semen and not Bull
            relevantDetails['Semen Used'] = event['semen_used'].toString();
          }
          if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
            relevantDetails['Technician'] = event['technician'].toString();
          }
          // Only show Bull when semen is not available and viewing a female profile
          final cattleSex = widget.cattle.sex.toLowerCase();
          if (cattleSex == 'female') {
            if (!hasSemen && event['bull_tag'] != null && event['bull_tag'].toString().isNotEmpty && event['bull_tag'] != 'N/A') {
              relevantDetails['Bull'] = event['bull_tag'].toString();
            }
          }
        }
        
        // Show estimated return to heat date for female cattle
        final cattleSex = widget.cattle.sex.toLowerCase();
        if (cattleSex == 'female' && event['estimated_return_date'] != null && event['estimated_return_date'].toString().isNotEmpty && event['estimated_return_date'] != 'N/A') {
          relevantDetails['Return to Heat'] = _formatDate(event['estimated_return_date']);
        }
        break;

      case 'weighed':
        if (event['weighed_result'] != null && event['weighed_result'].toString().isNotEmpty && event['weighed_result'] != 'N/A') {
          relevantDetails['Weight (kg)'] = event['weighed_result'].toString();
        }
        break;

      case 'gives birth':
        if (event['bull_tag'] != null && event['bull_tag'].toString().isNotEmpty && event['bull_tag'] != 'N/A') {
          relevantDetails['Bull Tag (Father)'] = event['bull_tag'].toString();
        }
        
        // Handle calf tags and calculate litter size
        final calfTagValue = event['calf_tag']?.toString();
        if (calfTagValue != null && calfTagValue.isNotEmpty && calfTagValue != 'N/A') {
          if (calfTagValue.contains(',')) {
            // Multiple calves - split by comma and count
            final calfTags = calfTagValue.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
            relevantDetails['Calf Tags'] = calfTags.join(', ');
            relevantDetails['Litter Size'] = '${calfTags.length}';
          } else {
            // Single calf
            relevantDetails['Calf Tag'] = calfTagValue;
            relevantDetails['Litter Size'] = '1';
          }
        } else {
          // No calf tags found - show 0 litter size
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
        if (event['bull_tag'] != null && event['bull_tag'].toString().isNotEmpty && event['bull_tag'] != 'N/A') {
          relevantDetails['Bull Tag (Father)'] = event['bull_tag'].toString();
        }
        break;

      case 'aborted pregnancy':
      // No additional fields for aborted pregnancy
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
          relevantDetails['Buyer'] = event['buyer'].toString();
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
                      AppColors.lightGreen.withOpacity(0.1),
                      AppColors.vibrantGreen.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGreen.withOpacity(0.2)),
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
                    : 'No history records have been recorded for this cattle yet.\nTap "Add History Record" to get started.',
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