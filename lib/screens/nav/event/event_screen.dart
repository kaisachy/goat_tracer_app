// lib/screens/nav/event/events_screen.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_event_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/events/event_search_filter_bar.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_event_form_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/event_duplication_modal.dart';
import 'package:cattle_tracer_app/utils/event_type_utils.dart';
import '../../../models/cattle.dart';
import 'cattle_selection_modal.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List<Map<String, dynamic>> allEvents = [];
  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String selectedEventType = 'All';
  Set<int> expandedCards = <int>{};

  // All possible event types
  List<String> get eventTypes {
    return [
      'All', 'Dry off', 'Treated', 'Breeding', 'Weighed', 'Gives Birth',
      'Vaccinated', 'Pregnant', 'Aborted Pregnancy', 'Deworming',
      'Hoof Trimming', 'Castrated', 'Weaned', 'Other',
    ];
  }

  // List of event types that can be duplicated
  final List<String> _duplicatableEventTypes = [
    'dry off',
    'treated',
    'breeding',
    'vaccinated',
    'deworming',
    'hoof trimming',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllCattleEvents();
  }

  Future<void> _loadAllCattleEvents() async {
    try {
      setState(() => isLoading = true);
      final events = await CattleEventService.getCattleEvent();

      // Remove duplicates and delete them from database
      final uniqueEvents = await _removeDuplicateEventsFromDB(events);

      // Sort events by date to show latest first
      uniqueEvents.sort((a, b) {
        final dateA = DateTime.tryParse(a['event_date'] ?? '1900-01-01') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['event_date'] ?? '1900-01-01') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Descending order (latest first)
      });

      if (mounted) {
        setState(() {
          allEvents = uniqueEvents;
          isLoading = false;
          error = null;

          // Auto-expand the latest event (index 0 after sorting)
          if (allEvents.isNotEmpty) {
            expandedCards.add(0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load events: $e';
          isLoading = false;
        });
      }
    }
  }

  // Helper method to remove duplicate events and delete them from database
  Future<List<Map<String, dynamic>>> _removeDuplicateEventsFromDB(List<Map<String, dynamic>> events) async {
    final List<Map<String, dynamic>> uniqueEvents = [];
    final List<Map<String, dynamic>> duplicatesToDelete = [];
    int deletedCount = 0;

    for (final event in events) {
      final existingEventIndex = uniqueEvents.indexWhere((existingEvent) =>
          _areEventsIdentical(event, existingEvent));

      if (existingEventIndex == -1) {
        // No duplicate found, add to unique events
        uniqueEvents.add(event);
      } else {
        // Duplicate found - decide which one to keep and which to delete
        final existingEvent = uniqueEvents[existingEventIndex];
        final currentEventDate = DateTime.tryParse(event['event_date'] ?? '1900-01-01') ?? DateTime(1900);
        final existingEventDate = DateTime.tryParse(existingEvent['event_date'] ?? '1900-01-01') ?? DateTime(1900);

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
            final success = await CattleEventService.deleteCattleEvent(eventId);
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
              content: Text('Removed $deletedCount duplicate event${deletedCount > 1 ? 's' : ''} from database'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        print('Error deleting duplicate events: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Some duplicate events could not be removed from database'),
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

  // Helper method to check if two events are identical
  bool _areEventsIdentical(Map<String, dynamic> event1, Map<String, dynamic> event2) {
    // Get the event type to determine which fields to compare
    final eventType1 = (event1['event_type'] ?? '').toString().toLowerCase();
    final eventType2 = (event2['event_type'] ?? '').toString().toLowerCase();

    // If event types are different, they're not identical
    if (eventType1 != eventType2) return false;

    // Compare basic fields that are always relevant
    if (!_compareFieldValues(event1['event_date'], event2['event_date'])) return false;
    if (!_compareFieldValues(event1['cattle_tag'], event2['cattle_tag'])) return false;
    if (!_compareFieldValues(event1['notes'], event2['notes'])) return false;

    // Compare event-specific fields based on event type
    switch (eventType1) {
      case 'dry off':
      case 'aborted pregnancy':
      case 'hoof trimming':
      case 'weaned':
        return true;

      case 'treated':
        return _compareFieldValues(event1['sickness_symptoms'], event2['sickness_symptoms']) &&
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

      case 'deworming':
        return _compareFieldValues(event1['medicine_given'], event2['medicine_given']);

      case 'castrated':
        return _compareFieldValues(event1['technician'], event2['technician']);

      case 'other':
      default:
      // For 'other' events, compare all potentially relevant fields
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
            _compareFieldValues(event1['expected_delivery_date'], event2['expected_delivery_date']);
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
    if (stringValue.isEmpty || stringValue.toLowerCase() == 'n/a') {
      return null;
    }
    return stringValue.toLowerCase();
  }

  Future<void> _refreshEvents() async => await _loadAllCattleEvents();

  List<Map<String, dynamic>> get _filteredEvents {
    return allEvents.where((event) {
      final type = (event['event_type'] ?? '').toString().toLowerCase();
      final notes = (event['notes'] ?? '').toString().toLowerCase();
      final diagnosis = (event['diagnosis'] ?? '').toString().toLowerCase();
      final cattleTag = (event['cattle_tag'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      final matchesSearch = type.contains(query) ||
          notes.contains(query) ||
          diagnosis.contains(query) ||
          cattleTag.contains(query);

      final matchesFilter = selectedEventType == 'All' ||
          type == selectedEventType.toLowerCase();

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

    final eventType = event['event_type']?.toString() ?? '';
    final canDuplicate = _canDuplicateEvent(eventType);

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
                const Text('Duplicate Event'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, color: AppColors.vibrantGreen, size: 20),
              const SizedBox(width: 12),
              const Text('Edit Event'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 12),
              Text('Delete Event', style: TextStyle(color: Colors.red.shade400)),
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
          return EventDuplicationModal(originalEvent: event);
        },
      );

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
      final cattleEvent = CattleEvent(
        id: event['id'] ?? 0,
        cattleTag: event['cattle_tag']?.toString() ?? '',
        bullTag: event['bull_tag']?.toString(),
        calfTag: event['calf_tag']?.toString(),
        eventType: event['event_type']?.toString() ?? '',
        eventDate: event['event_date']?.toString() ?? '',
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
      );

      // Navigate to edit screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CattleEventFormScreen(
            event: cattleEvent,
            cattleTag: event['cattle_tag']?.toString() ?? '',
          ),
        ),
      );

      if (result == true) {
        await _refreshEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Event updated successfully!'),
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
              const Text('Delete Event'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this event?'),
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
                      '${event['event_type']} - ${event['cattle_tag']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Date: ${_formatDate(event['event_date'])}',
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
                const Text('Deleting event...'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      final success = await CattleEventService.deleteCattleEvent(event['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (success) {
        await _refreshEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event['event_type']}" deleted successfully'),
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
              content: Text('Failed to delete event "${event['event_type']}"'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

// Replace your existing _onAddEvent method with this updated version
  void _onAddEvent() async {
    try {
      // First, show cattle selection modal
      final selectedCattleTag = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const CattleSelectionModal();
        },
      );

      // If user cancelled or no cattle was selected, return
      if (selectedCattleTag == null) return;

      // Navigate to the event form with the selected cattle tag
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CattleEventFormScreen(
            cattleTag: selectedCattleTag,
          ),
        ),
      );

      // Handle the result from the form
      if (result == true && mounted) {
        await _refreshEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Event added successfully!'),
              ],
            ),
            backgroundColor: AppColors.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error adding event: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            EventSearchFilterBar(
              initialSearchQuery: searchQuery,
              initialEventType: selectedEventType,
              eventTypes: eventTypes,
              onSearchChanged: _onSearchChanged,
              onFilterChanged: _onFilterChanged,
              onClearFilter: _onClearFilter,
            ),
            const SizedBox(height: 16),
            _buildEventsSummary(),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddEvent,
        backgroundColor: AppColors.vibrantGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Event',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEventsSummary() {
    if (allEvents.isEmpty) return const SizedBox.shrink();

    final totalEvents = allEvents.length;
    final filteredCount = _filteredEvents.length;
    final recentEvent = allEvents.isNotEmpty
        ? allEvents.reduce((a, b) =>
    DateTime.parse(a['event_date'] ?? '1900-01-01')
        .isAfter(DateTime.parse(b['event_date'] ?? '1900-01-01')) ? a : b)
        : null;

    // Get unique cattle count
    final uniqueCattleTags = allEvents
        .map((event) => event['cattle_tag']?.toString() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.event_note_rounded,
              label: 'Total Events',
              value: '$totalEvents',
              color: AppColors.vibrantGreen,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.filter_list_rounded,
              label: 'Showing',
              value: '$filteredCount',
              color: AppColors.lightGreen,
            ),
          ),
          if (recentEvent != null) ...[
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            Expanded(
              child: _buildSummaryItem(
                icon: Icons.schedule_rounded,
                label: 'Latest',
                value: _formatDate(recentEvent['event_date']),
                color: Colors.blue.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEventAccordion(Map<String, dynamic> event, int index) {
    final eventType = event['event_type'] ?? 'Unknown';
    final eventDate = event['event_date'];
    final cattleTag = event['cattle_tag']?.toString() ?? 'Unknown';
    final eventColor = EventTypeUtils.getEventColor(eventType);
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
                gradient: LinearGradient(
                  colors: [
                    eventColor.withOpacity(0.1),
                    eventColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                    child: Icon(EventTypeUtils.getEventIcon(eventType), color: eventColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                eventType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: eventColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                cattleTag,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
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
                      if (details.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: eventColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${details.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: eventColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
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
                color: Colors.grey.shade50,
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
                  }).toList(),
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
    final eventType = (event['event_type'] ?? '').toString().toLowerCase();
    final Map<String, String?> relevantDetails = {};

    // Always show notes if available
    if (event['notes'] != null && event['notes'].toString().isNotEmpty && event['notes'] != 'N/A') {
      relevantDetails['Notes'] = event['notes'].toString();
    }

    // Add event-specific fields based on event type
    switch (eventType) {
      case 'dry off':
      case 'aborted pregnancy':
      case 'hoof trimming':
      case 'weaned':
      // No additional fields for these event types
        break;

      case 'treated':
        if (event['sickness_symptoms'] != null && event['sickness_symptoms'].toString().isNotEmpty && event['sickness_symptoms'] != 'N/A') {
          relevantDetails['Symptoms'] = event['sickness_symptoms'].toString();
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
        if (event['semen_used'] != null && event['semen_used'].toString().isNotEmpty && event['semen_used'] != 'N/A') {
          relevantDetails['Semen Used'] = event['semen_used'].toString();
        }
        if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
          relevantDetails['Technician'] = event['technician'].toString();
        }
        if (event['estimated_return_date'] != null && event['estimated_return_date'].toString().isNotEmpty && event['estimated_return_date'] != 'N/A') {
          relevantDetails['Est. Return to Heat'] = _formatDate(event['estimated_return_date']);
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
        if (event['calf_tag'] != null && event['calf_tag'].toString().isNotEmpty && event['calf_tag'] != 'N/A') {
          relevantDetails['Calf Tag'] = event['calf_tag'].toString();
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

      case 'deworming':
        if (event['medicine_given'] != null && event['medicine_given'].toString().isNotEmpty && event['medicine_given'] != 'N/A') {
          relevantDetails['Deworming Medicine'] = event['medicine_given'].toString();
        }
        break;

      case 'castrated':
        if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
          relevantDetails['Technician'] = event['technician'].toString();
        }
        break;

      case 'other':
      default:
      // For 'other' events, show all available fields that have data
        if (event['bull_tag'] != null && event['bull_tag'].toString().isNotEmpty && event['bull_tag'] != 'N/A') {
          relevantDetails['Bull Tag'] = event['bull_tag'].toString();
        }
        if (event['calf_tag'] != null && event['calf_tag'].toString().isNotEmpty && event['calf_tag'] != 'N/A') {
          relevantDetails['Calf Tag'] = event['calf_tag'].toString();
        }
        if (event['technician'] != null && event['technician'].toString().isNotEmpty && event['technician'] != 'N/A') {
          relevantDetails['Technician'] = event['technician'].toString();
        }
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
                isFiltering ? 'No Results Found' : 'No Events Recorded',
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
                    : 'No cattle events have been recorded yet.\nTap "Add Event" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              if (!isFiltering) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _onAddEvent,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add First Event'),
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
                'Error Loading Events',
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