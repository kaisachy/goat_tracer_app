// lib/screens/nav/cattle/widgets/event_cattle_tab_content.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_event_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/event_search_filter_bar.dart';
import '../cattle_event_form_screen.dart';
import '../modals/event_duplication_modal.dart';

class EventCattleTabContent extends StatefulWidget {
  final Cattle cattle;
  final VoidCallback onAddEvent;

  const EventCattleTabContent({
    super.key,
    required this.cattle,
    required this.onAddEvent,
  });

  @override
  State<EventCattleTabContent> createState() => _EventCattleTabContentState();
}

class _EventCattleTabContentState extends State<EventCattleTabContent> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String selectedEventType = 'All';
  Set<int> expandedCards = <int>{};

  List<String> get eventTypes {
    final femaleEventTypes = [
      'All', 'Dry off', 'Treated', 'Breeding', 'Weighed', 'Gives Birth',
      'Vaccinated', 'Pregnant', 'Aborted Pregnancy', 'Deworming',
      'Hoof Trimming', 'Other',
    ];

    final maleEventTypes = [
      'All', 'Treated', 'Weighed', 'Vaccinated', 'Deworming',
      'Hoof Trimming', 'Castrated', 'Weaned', 'Other',
    ];

    // Check cattle gender and return appropriate event types
    final gender = widget.cattle.gender.toLowerCase();
    return gender == 'female' ? femaleEventTypes : maleEventTypes;
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
    _loadCattleEvents();
  }

  Future<void> _loadCattleEvents() async {
    try {
      setState(() => isLoading = true);
      final allEvents = await CattleEventService.getCattleEvent();
      final cattleEvents = allEvents.where((event) =>
      (event['cattle_tag']?.toString().trim().toLowerCase() ?? '') ==
          widget.cattle.tagNo.trim().toLowerCase()
      ).toList();

      // Sort events by date to find the latest one
      cattleEvents.sort((a, b) {
        final dateA = DateTime.tryParse(a['event_date'] ?? '1900-01-01') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['event_date'] ?? '1900-01-01') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Descending order (latest first)
      });

      if (mounted) {
        setState(() {
          events = cattleEvents;
          isLoading = false;
          error = null;

          // Auto-expand the latest event (index 0 after sorting)
          if (events.isNotEmpty) {
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

  Future<void> _refreshEvents() async => await _loadCattleEvents();

  List<Map<String, dynamic>> get _filteredEvents {
    return events.where((event) {
      final type = (event['event_type'] ?? '').toString().toLowerCase();
      final notes = (event['notes'] ?? '').toString().toLowerCase();
      final diagnosis = (event['diagnosis'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      final matchesSearch = type.contains(query) ||
          notes.contains(query) ||
          diagnosis.contains(query);

      final matchesFilter = selectedEventType == 'All' ||
          type == selectedEventType.toLowerCase();

      // Additional filter: only show events that are valid for the cattle's gender
      final gender = widget.cattle.gender.toLowerCase();
      final validEventTypes = gender == 'female'
          ? ['dry off', 'treated', 'breeding', 'weighed', 'gives birth', 'vaccinated',
        'pregnant', 'aborted pregnancy', 'deworming', 'hoof trimming', 'other']
          : ['treated', 'weighed', 'vaccinated', 'deworming', 'hoof trimming',
        'castrated', 'weaned','other'];

      final matchesGender = validEventTypes.contains(type);

      return matchesSearch && matchesFilter && matchesGender;
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

      // If duplication was successful, refresh the events list
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
            cattleTag: widget.cattle.tagNo,
          ),
        ),
      );

      // If edit was successful, refresh the events list
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
                      '${event['event_type']}',
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
                const Text('Deleting event...'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 10), // Longer duration for loading
          ),
        );
      }

      // Call the delete API
      final success = await CattleEventService.deleteCattleEvent(event['id']);

      // Clear any existing snackbars
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (success) {
        // Refresh the events list
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
      // Clear loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (mounted) {
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
    if (events.isEmpty) return const SizedBox.shrink();

    final totalEvents = events.length;
    final filteredCount = _filteredEvents.length;
    final recentEvent = events.isNotEmpty
        ? events.reduce((a, b) =>
    DateTime.parse(a['event_date'] ?? '1900-01-01')
        .isAfter(DateTime.parse(b['event_date'] ?? '1900-01-01')) ? a : b)
        : null;

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
    final eventColor = _getEventColor(eventType);
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
                    child: Icon(_getEventIcon(eventType), color: eventColor, size: 24),
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
      // No additional fields for dry off
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
                    : 'Events for this cattle will appear here.\nTap "Add Event" to get started.',
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
                  onPressed: widget.onAddEvent,
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

  // Helper methods for icons, colors, and date formatting
  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'breeding': return Icons.favorite_rounded;
      case 'weighed': return Icons.monitor_weight_rounded;
      case 'gives birth': return Icons.child_care_rounded;
      case 'vaccinated': return Icons.vaccines_rounded;
      case 'pregnant': return Icons.pregnant_woman_rounded;
      case 'treated': return Icons.medical_services_rounded;
      case 'dry off': return Icons.pause_circle_rounded;
      case 'deworming': return Icons.pest_control_rounded;
      case 'hoof trimming': return Icons.content_cut_rounded;
      case 'castrated': return Icons.minor_crash_rounded;
      case 'weaned': return Icons.rss_feed_rounded;
      case 'aborted pregnancy': return Icons.heart_broken_rounded;
      case 'other': return Icons.more_horiz_rounded;
      default: return Icons.event_note_rounded;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'breeding': return Colors.pink.shade400;
      case 'weighed': return Colors.orange.shade500;
      case 'gives birth': return Colors.blue.shade400;
      case 'vaccinated': return Colors.green.shade500;
      case 'pregnant': return Colors.purple.shade400;
      case 'treated': return Colors.red.shade400;
      case 'dry off': return Colors.grey.shade500;
      case 'deworming': return Colors.yellow.shade600;
      case 'hoof trimming': return Colors.brown.shade400;
      case 'castrated': return Colors.indigo.shade400;
      case 'weaned': return Colors.teal.shade400;
      case 'aborted pregnancy': return Colors.red.shade600;
      case 'other': return Colors.blueGrey.shade400;
      default: return AppColors.lightGreen;
    }
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
}