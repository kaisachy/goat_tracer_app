import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_header_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_stats_row_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_tab_bar_widget.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/schedule.dart';
import '../../../services/schedule/schedule_service.dart';
import '../../../utils/schedule_utils.dart';
import 'cattle_schedule_form.dart';


class ScheduleContentWidget extends StatefulWidget {
  const ScheduleContentWidget({super.key});

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

    // Load schedules immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedules();
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

  Future<void> _loadSchedules() async {
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
      case ScheduleFilter.highPriority:
        filtered = _schedules.where((schedule) =>
            schedule.priority.toLowerCase() == 'high').toList();
        break;
      case ScheduleFilter.mediumPriority:
        filtered = _schedules.where((schedule) =>
            schedule.priority.toLowerCase() == 'medium').toList();
        break;
      case ScheduleFilter.lowPriority:
        filtered = _schedules.where((schedule) =>
            schedule.priority.toLowerCase() == 'low').toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        final query = _searchQuery.toLowerCase();
        return schedule.title.toLowerCase().contains(query) ||
            (schedule.notes?.toLowerCase().contains(query) ?? false) ||
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
        case ScheduleSort.priorityAsc:
          return a.priority.compareTo(b.priority);
        case ScheduleSort.priorityDesc:
          return b.priority.compareTo(a.priority);
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
      return const Center(
        child: Text('No schedules found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView.builder(
        itemCount: _filteredSchedules.length,
        itemBuilder: (context, index) {
          final schedule = _filteredSchedules[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(schedule.title),
              subtitle: Text(schedule.cattleTag ?? 'No cattle assigned'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, schedule),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
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
      return const Center(
        child: Text('No schedules for today'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView.builder(
        itemCount: _todaysSchedules.length,
        itemBuilder: (context, index) {
          final schedule = _todaysSchedules[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(schedule.title),
              subtitle: Text(schedule.cattleTag ?? 'No cattle assigned'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, schedule),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
    );
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
    }
  }



  void _showEditScheduleDialog(Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CattleScheduleForm(
          onScheduleAdded: _loadSchedules,
          scheduleToEdit: schedule,
        ),
      ),
    ).then((_) {
      // Refresh the schedules after editing
      _loadSchedules();
    });
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
            Text('Priority: ${schedule.priority}'),
            Text('Status: ${schedule.status}'),
            if (schedule.notes != null) Text('Notes: ${schedule.notes}'),
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
                _loadSchedules();
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
