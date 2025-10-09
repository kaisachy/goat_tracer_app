import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_header_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_stats_row_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_tab_bar_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_card_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_empty_states_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/today_schedule_header_widget.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/schedule.dart';
import '../../../services/schedule/schedule_service.dart';
import '../../../utils/schedule_utils.dart';
import '../../../services/cattle/cattle_history_service.dart';
import 'schedule_form.dart';


class ScheduleContentWidget extends StatefulWidget {
  final Function(VoidCallback)? onReloadCallback;
  
  const ScheduleContentWidget({
    super.key,
    this.onReloadCallback,
  });

  @override
  State<ScheduleContentWidget> createState() => _ScheduleContentWidgetState();
}

class _ScheduleContentWidgetState extends State<ScheduleContentWidget> with TickerProviderStateMixin {
  List<Schedule> _schedules = [];
  List<Schedule> _filteredSchedules = [];
  List<Schedule> _todaysSchedules = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ScheduleFilter _selectedFilter = ScheduleFilter.all;
  final ScheduleSort _selectedSort = ScheduleSort.dateTimeAsc;

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Tab indices
  static const int _allTab = 0;
  static const int _todayTab = 1;
  static const int _upcomingTab = 2;
  static const int _overdueTab = 3;
  static const int _completedTab = 4;

  // Cache for tab counts - Initialize with zeros
  Map<String, int> _tabCounts = {
    'all': 0,
    'today': 0,
    'upcoming': 0,
    'overdue': 0,
    'completed': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Register reload callback with parent
    widget.onReloadCallback?.call(loadSchedules);

    // Load schedules immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadSchedules();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      switch (_tabController.index) {
        case _allTab:
          _selectedFilter = ScheduleFilter.all;
          break;
        case _todayTab:
          _selectedFilter = ScheduleFilter.all; // Will be filtered separately for today
          break;
        case _upcomingTab:
          _selectedFilter = ScheduleFilter.upcoming;
          break;
        case _overdueTab:
          _selectedFilter = ScheduleFilter.overdue;
          break;
        case _completedTab:
          _selectedFilter = ScheduleFilter.completed;
          break;
      }
    });
    _applyFilters();
  }

  Future<void> loadSchedules() async {
    setState(() => _isLoading = true);

    try {
      final schedules = await ScheduleService.getSchedules();

      // Process data
      _schedules = schedules;
      _loadTodaysSchedules();

      // Calculate new counts
      final stats = ScheduleStats.getStatusCounts(_schedules);
      final newTabCounts = {
        'all': _schedules.length,
        'today': _todaysSchedules.length,
        'upcoming': stats['upcoming'] ?? 0,
        'overdue': stats['overdue'] ?? 0,
        'completed': stats['completed'] ?? 0,
      };

      // Update state with all data
      setState(() {
        _tabCounts = newTabCounts;
        _isLoading = false;
      });

      // Apply filters after state is updated
      _applyFilters();

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading schedules: ${e.toString()}', isError: true);
    }
  }

  void _loadTodaysSchedules() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    _todaysSchedules = _schedules.where((schedule) {
      final scheduleDate = schedule.scheduleDateTime;
      return scheduleDate.isAfter(todayStart) && scheduleDate.isBefore(todayEnd);
    }).toList();
  }

  void _applyFilters() {
    List<Schedule> filtered = [];

    switch (_selectedFilter) {
      case ScheduleFilter.all:
        filtered = _schedules;
        break;
      case ScheduleFilter.upcoming:
        filtered = _schedules.where((schedule) =>
            schedule.status.toLowerCase() == 'scheduled' &&
            schedule.scheduleDateTime.isAfter(DateTime.now())).toList();
        break;
      case ScheduleFilter.overdue:
        filtered = _schedules.where((schedule) =>
            schedule.status.toLowerCase() == 'scheduled' &&
            schedule.scheduleDateTime.isBefore(DateTime.now())).toList();
        break;
      case ScheduleFilter.completed:
        filtered = _schedules.where((schedule) =>
            schedule.status.toLowerCase() == 'completed').toList();
        break;
      case ScheduleFilter.cancelled:
        filtered = _schedules.where((schedule) =>
            schedule.status.toLowerCase() == 'cancelled').toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        final query = _searchQuery.toLowerCase();
        return schedule.title.toLowerCase().contains(query) ||
            (schedule.details?.toLowerCase().contains(query) ?? false) ||
            (schedule.cattleTag?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case ScheduleSort.dateTimeAsc:
          return a.scheduleDateTime.compareTo(b.scheduleDateTime);
        case ScheduleSort.dateTimeDesc:
          return b.scheduleDateTime.compareTo(a.scheduleDateTime);
        case ScheduleSort.titleAsc:
          return a.title.compareTo(b.title);
        case ScheduleSort.titleDesc:
          return b.title.compareTo(a.title);
        case ScheduleSort.statusAsc:
          return a.status.compareTo(b.status);
        case ScheduleSort.statusDesc:
          return b.status.compareTo(a.status);
      }
    });

    setState(() {
      _filteredSchedules = filtered;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            // Header with search and stats
            ScheduleHeader(
              searchController: _searchController,
              onSearchChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
              onSearchClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _applyFilters();
              },
              onScheduleAdded: loadSchedules,
              child: ScheduleStatsRow(tabCounts: _tabCounts),
            ),
            // Tab Bar
            ScheduleTabBar(
              key: ValueKey(_tabCounts.toString()),
              tabController: _tabController,
              tabCounts: _tabCounts,
            ),
            // Tab Content
            SizedBox(
              height: MediaQuery.of(context).size.height - 200, // Adjust height to prevent overflow
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScheduleList(), // All
                  _buildTodayScheduleList(), // Today
                  _buildScheduleList(), // Upcoming
                  _buildScheduleList(), // Overdue
                  _buildScheduleList(), // Completed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredSchedules.isEmpty) {
      final type = _getEmptyStateType();
      return ScheduleEmptyStates(
        type: type,
        hasSchedules: _schedules.isNotEmpty,
        searchQuery: _searchQuery,
      );
    }

    return RefreshIndicator(
      onRefresh: loadSchedules,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredSchedules.length,
        itemBuilder: (context, index) {
          final schedule = _filteredSchedules[index];
          return ScheduleCard(
            schedule: schedule,
            onMenuAction: _handleMenuAction,
          );
        },
      ),
    );
  }

  Widget _buildTodayScheduleList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todaysSchedules.isEmpty) {
      return const ScheduleEmptyStates(type: ScheduleEmptyStateType.todayEmpty);
    }

    return RefreshIndicator(
      onRefresh: loadSchedules,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TodayScheduleHeader(todaysSchedules: _todaysSchedules),
          const SizedBox(height: 16),
          ..._filteredSchedules.map((s) => ScheduleCard(
                schedule: s,
                isToday: true,
                onMenuAction: _handleMenuAction,
              )),
        ],
      ),
    );
  }

  ScheduleEmptyStateType _getEmptyStateType() {
    if (_searchQuery.isNotEmpty) return ScheduleEmptyStateType.searchEmpty;
    switch (_selectedFilter) {
      case ScheduleFilter.upcoming:
        return ScheduleEmptyStateType.upcomingEmpty;
      case ScheduleFilter.overdue:
        return ScheduleEmptyStateType.overdueEmpty;
      case ScheduleFilter.completed:
        return ScheduleEmptyStateType.completedEmpty;
      default:
        return ScheduleEmptyStateType.allEmpty;
    }
  }

  // Menu action handlers and other methods
  void _handleMenuAction(String action, Schedule schedule) {
    switch (action) {
      case 'view':
        _showScheduleDetails(schedule);
        break;
      case 'edit':
        _showEditScheduleDialog(schedule);
        break;
      case 'delete':
        _confirmDeleteSchedule(schedule);
        break;
      case 'cancel':
        _updateStatus(schedule, ScheduleStatus.cancelled);
        break;
      case 'complete':
        _updateStatus(schedule, ScheduleStatus.completed);
        break;
      case 'reschedule':
        _updateStatus(schedule, ScheduleStatus.scheduled);
        break;
      case 'duplicate':
        _duplicateSchedule(schedule);
        break;
    }
  }



  void _showEditScheduleDialog(Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleForm(
          onScheduleAdded: loadSchedules,
          scheduleToEdit: schedule,
        ),
      ),
    ).then((_) {
      // Refresh the schedules after editing
      loadSchedules();
    });
  }

  Future<void> _updateStatus(Schedule schedule, String status) async {
    try {
      await ScheduleService.updateScheduleStatus(schedule.id ?? 0, status);
      // If marking as completed, auto-create event(s) except Feed and Other
      if (status == ScheduleStatus.completed) {
        await _createEventsForSchedule(schedule);
      } else if (status == ScheduleStatus.scheduled) {
        // If rescheduled, remove previously auto-created history for this schedule
        await _removeEventsForSchedule(schedule);
      }
      await loadSchedules();
      _showSnackBar('Schedule updated to $status');
    } catch (e) {
      _showSnackBar('Failed to update status: ${e.toString()}', isError: true);
    }
  }

  Future<void> _duplicateSchedule(Schedule schedule) async {
    try {
      // Duplicate to the same datetime by default
      await ScheduleService.duplicateSchedule(schedule, schedule.scheduleDateTime);
      await loadSchedules();
      _showSnackBar('Schedule duplicated');
    } catch (e) {
      _showSnackBar('Failed to duplicate: ${e.toString()}', isError: true);
    }
  }

  Future<void> _createEventsForSchedule(Schedule schedule) async {
    final mappedEventType = _mapScheduleTypeToEventType(schedule.type);
    if (mappedEventType == null) {
      return; // No matching event for this type
    }

    final tags = _extractCattleTags(schedule.cattleTag);
    int successCount = 0;
    for (final tag in tags) {
      final data = <String, dynamic>{
        'cattle_tag': tag,
        'event_type': mappedEventType,
        'event_date': _formatDateForApi(schedule.scheduleDateTime),
        'notes': schedule.details,
      };
      // For vaccination, carry over vaccine name and technician
      if (mappedEventType.toLowerCase() == 'vaccinated') {
        if ((schedule.vaccineType ?? '').isNotEmpty) {
          data['medicine_given'] = schedule.vaccineType;
        }
        if ((schedule.scheduledBy ?? '').isNotEmpty) {
          data['technician'] = schedule.scheduledBy;
        }
      }
      try {
        final ok = await CattleHistoryService.storeCattleHistory(data);
        if (ok) successCount++;
      } catch (_) {}
    }
    if (successCount > 0) {
      _showSnackBar('Created $successCount ${mappedEventType.toLowerCase()} event(s)');
    }
  }

  Future<void> _removeEventsForSchedule(Schedule schedule) async {
    final mappedEventType = _mapScheduleTypeToEventType(schedule.type);
    if (mappedEventType == null) return;

    final tags = _extractCattleTags(schedule.cattleTag);
    final allEvents = await CattleHistoryService.getCattleHistory();
    final scheduleDate = _formatDateForApi(schedule.scheduleDateTime);

    for (final tag in tags) {
      // Find matching history by cattle_tag, event_type, and event_date
      final matches = allEvents.where((e) =>
        (e['cattle_tag']?.toString() ?? '').trim().toUpperCase() == tag.trim().toUpperCase() &&
        (e['event_type']?.toString().toLowerCase() ?? '') == mappedEventType.toLowerCase() &&
        (e['event_date']?.toString() ?? '') == scheduleDate
      );
      for (final evt in matches) {
        final id = int.tryParse('${evt['id']}');
        if (id != null) {
          await CattleHistoryService.deleteCattleHistory(id);
        }
      }
    }
  }

  List<String> _extractCattleTags(String? cattleTag) {
    if (cattleTag == null || cattleTag.trim().isEmpty) return [];
    return cattleTag
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  String? _mapScheduleTypeToEventType(String scheduleType) {
    switch (scheduleType.toLowerCase()) {
      case 'vaccination':
        return 'Vaccinated';
      case 'deworming':
        return 'Deworming';
      case 'hoof trimming':
        return 'Hoof Trimming';
      case 'weigh':
        return 'Weighed';
      case 'feed':
      case 'other':
        return null;
      default:
        return null;
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showScheduleDetails(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cattle: ${schedule.cattleTag ?? 'No cattle assigned'}'),
            Text('Type: ${schedule.type}'),
            Text('Status: ${schedule.status}'),
            if (schedule.details != null) Text('Details: ${schedule.details}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSchedule(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ScheduleService.deleteSchedule(schedule.id ?? 0);
                Navigator.pop(context);
                loadSchedules();
                _showSnackBar('Schedule deleted successfully');
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Failed to delete schedule: ${e.toString()}', isError: true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
