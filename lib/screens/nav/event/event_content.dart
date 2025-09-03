// lib/screens/nav/event/event_content.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_event_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/events/event_search_filter_bar.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_event_form_screen.dart';

import 'package:cattle_tracer_app/utils/event_type_utils.dart';
import '../../../models/cattle.dart';
import 'cattle_selection_modal.dart';


class EventContent extends StatefulWidget {
  const EventContent({super.key});

  @override
  State<EventContent> createState() => _EventContentState();
}

class _EventContentState extends State<EventContent> {
  List<Map<String, dynamic>> allEvents = [];
  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String selectedEventType = 'All';
  Set<int> expandedCards = <int>{};

  // All possible event types - comprehensive list including all event types from EventTypeUtils
  List<String> get eventTypes {
    return [
      'All', 'Dry off', 'Treated', 'Breeding', 'Weighed', 'Gives Birth',
      'Vaccinated', 'Pregnant', 'Aborted Pregnancy', 'Deworming',
      'Hoof Trimming', 'Castrated', 'Weaned', 'Deceased', 'Other',
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
    'deceased',
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
        uniqueEvents.add(event);
      } else {
        duplicatesToDelete.add(event);
      }
    }

    // Delete duplicates from database
    for (final duplicate in duplicatesToDelete) {
      try {
        await CattleEventService.deleteCattleEvent(duplicate['id']);
        deletedCount++;
      } catch (e) {
        print('Failed to delete duplicate event: $e');
      }
    }

    if (deletedCount > 0) {
      print('Deleted $deletedCount duplicate events');
    }

    return uniqueEvents;
  }

  bool _areEventsIdentical(Map<String, dynamic> event1, Map<String, dynamic> event2) {
    return event1['cattle_tag'] == event2['cattle_tag'] &&
        event1['event_type'] == event2['event_type'] &&
        event1['event_date'] == event2['event_date'] &&
        event1['notes'] == event2['notes'];
  }

  List<Map<String, dynamic>> get _filteredEvents {
    return allEvents.where((event) {
      final matchesSearch = searchQuery.isEmpty ||
          event['cattle_tag']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
          event['notes']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;

      final matchesFilter = selectedEventType == 'All' ||
          event['event_type']?.toString().toLowerCase() == selectedEventType.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
  }

  void _onFilterChanged(String eventType) {
    setState(() {
      selectedEventType = eventType;
    });
  }

  void _onClearFilter() {
    setState(() {
      searchQuery = '';
      selectedEventType = 'All';
    });
  }

  Future<void> _refreshEvents() async {
    await _loadAllCattleEvents();
  }

  void _onAddEvent() async {
    // First show the cattle selection modal
    final selectedCattleTag = await showDialog<String>(
      context: context,
      builder: (context) => const CattleSelectionModal(),
    );

    // If a cattle was selected, open the event form with the selected cattle
    if (selectedCattleTag != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CattleEventFormScreen(cattleTag: selectedCattleTag),
        ),
      ).then((_) => _loadAllCattleEvents());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
    final _ = allEvents
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
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.filter_list_rounded,
              label: 'Filtered',
              value: '$filteredCount',
              color: AppColors.vibrantGreen,
            ),
          ),
          if (recentEvent != null)
            Expanded(
              child: _buildSummaryItem(
                icon: Icons.calendar_today_rounded,
                label: 'Latest Event',
                value: _formatDate(recentEvent['event_date']),
                color: Colors.orange,
              ),
            ),
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
        Icon(icon, color: color, size: 24),
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
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid';
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading events',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAllCattleEvents,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first cattle event',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _onAddEvent,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
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
                        Text(
                          eventType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: eventColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_right_rounded,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
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
                  // Event details
                  ...details.map((detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${detail['label']}:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            detail['value'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  void _handleEventAction(String action, Map<String, dynamic> event) {
    switch (action) {
      case 'edit':
        _editEvent(event);
        break;
      case 'duplicate':
        _duplicateEvent(event);
        break;
      case 'delete':
        _deleteEvent(event);
        break;
    }
  }





  void _editEvent(Map<String, dynamic> event) {
    // Convert the map to a CattleEvent object
    final cattleEvent = CattleEvent.fromJson(event);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CattleEventFormScreen(
          event: cattleEvent,
          cattleTag: event['cattle_tag']?.toString(),
        ),
      ),
    ).then((_) => _loadAllCattleEvents());
  }

  void _duplicateEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Event'),
        content: const Text('This feature is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    
    );
  }

  void _deleteEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete this ${event['event_type']} event for cattle ${event['cattle_tag']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await CattleEventService.deleteCattleEvent(event['id']);
                Navigator.pop(context);
                _loadAllCattleEvents();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event deleted successfully'),
                    backgroundColor: AppColors.vibrantGreen,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete event: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Get event details based on event type
  List<Map<String, String?>> _getEventDetails(Map<String, dynamic> event) {
    final eventType = (event['event_type'] ?? '').toString().toLowerCase();
    final details = <Map<String, String?>>[];

    switch (eventType) {
      case 'breeding':
        if (event['bull_tag'] != null) details.add({'label': 'Bull Tag', 'value': event['bull_tag']});
        if (event['semen_used'] != null) details.add({'label': 'Semen Used', 'value': event['semen_used']});
        if (event['estimated_return_date'] != null) details.add({'label': 'Return Date', 'value': _formatDate(event['estimated_return_date'])});
        break;
      case 'treated':
        if (event['sickness_symptoms'] != null) details.add({'label': 'Symptoms', 'value': event['sickness_symptoms']});
        if (event['diagnosis'] != null) details.add({'label': 'Diagnosis', 'value': event['diagnosis']});
        if (event['medicine_given'] != null) details.add({'label': 'Medicine', 'value': event['medicine_given']});
        if (event['technician'] != null) details.add({'label': 'Technician', 'value': event['technician']});
        break;
      case 'weighed':
        if (event['weighed_result'] != null) details.add({'label': 'Weight', 'value': '${event['weighed_result']} kg'});
        break;
      case 'gives birth':
        if (event['bull_tag'] != null) details.add({'label': 'Bull Tag', 'value': event['bull_tag']});
        if (event['calf_tag'] != null) details.add({'label': 'Calf Tag', 'value': event['calf_tag']});
        break;
      case 'vaccinated':
        if (event['medicine_given'] != null) details.add({'label': 'Vaccine', 'value': event['medicine_given']});
        if (event['technician'] != null) details.add({'label': 'Technician', 'value': event['technician']});
        break;
      case 'pregnant':
        if (event['breeding_date'] != null) details.add({'label': 'Breeding Date', 'value': _formatDate(event['breeding_date'])});
        if (event['expected_delivery_date'] != null) details.add({'label': 'Due Date', 'value': _formatDate(event['expected_delivery_date'])});
        if (event['bull_tag'] != null) details.add({'label': 'Bull Tag', 'value': event['bull_tag']});
        break;
      case 'deworming':
        if (event['medicine_given'] != null) details.add({'label': 'Medicine', 'value': event['medicine_given']});
        break;
      case 'castrated':
        if (event['technician'] != null) details.add({'label': 'Technician', 'value': event['technician']});
        break;
      case 'deceased':
        if (event['cause_of_death'] != null) details.add({'label': 'Cause of Death', 'value': event['cause_of_death']});
        break;
    }

    // Always add notes if available
    if (event['notes'] != null && event['notes'].toString().isNotEmpty) {
      details.add({'label': 'Notes', 'value': event['notes']});
    }

    return details;
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

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        if (_duplicatableEventTypes.contains((event['event_type'] ?? '').toString().toLowerCase()))
          const PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_rounded, size: 18),
                SizedBox(width: 8),
                Text('Duplicate'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleEventAction(value, event);
      }
    });
  }
}
