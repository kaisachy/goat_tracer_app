import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_content_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_header_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_stats_row_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_tab_bar_widget.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/schedule.dart';
import '../../../services/schedule/schedule_service.dart';
import '../../../utils/schedule_utils.dart';
import 'cattle_schedule_form.dart';
import 'modals/schedule_details_dialog_modal.dart';


class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
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
    // Get current Philippines time (UTC+8)
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final today = DateTime(now.year, now.month, now.day);

    _todaysSchedules = _schedules.where((schedule) {
      // Convert schedule time to Philippines time for comparison
      final schedulePhTime = schedule.scheduleDateTime.toUtc().add(const Duration(hours: 8));
      final scheduleDate = DateTime(schedulePhTime.year, schedulePhTime.month, schedulePhTime.day);
      return scheduleDate == today;
    }).toList();

    _todaysSchedules.sort((a, b) => a.scheduleDateTime.compareTo(b.scheduleDateTime));
  }

  void _applyFilters() {
    List<Schedule> filtered = _schedules;

    // Apply search filter first
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        final query = _searchQuery.toLowerCase();
        return schedule.title.toLowerCase().contains(query) ||
            schedule.type.toLowerCase().contains(query) ||
            (schedule.cattleTag?.toLowerCase().contains(query) ?? false) ||
            (schedule.veterinarian?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply status filter based on current tab
    if (_tabController.index == _todayTab) {
      // For today tab, use today's schedules regardless of status
      filtered = _todaysSchedules.where((schedule) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return schedule.title.toLowerCase().contains(query) ||
              schedule.type.toLowerCase().contains(query) ||
              (schedule.cattleTag?.toLowerCase().contains(query) ?? false) ||
              (schedule.veterinarian?.toLowerCase().contains(query) ?? false);
        }
        return true;
      }).toList();
    } else {
      // For other tabs, apply the appropriate filter
      filtered = filtered.where((schedule) => _selectedFilter.matches(schedule)).toList();
    }

    // Sort the filtered results
    filtered = _selectedSort.sort(filtered);

    setState(() {
      _filteredSchedules = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: ScheduleHeader(
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
          ),
          SliverPersistentHeader(
            delegate: ScheduleTabBarDelegate(
              ScheduleTabBar(
                key: ValueKey(_tabCounts.toString()), // Force rebuild when counts change
                tabController: _tabController,
                tabCounts: _tabCounts,
              ),
            ),
            pinned: true,
          ),
        ],
        body: ScheduleContent(
          tabController: _tabController,
          isLoading: _isLoading,
          schedules: _schedules,
          filteredSchedules: _filteredSchedules,
          todaysSchedules: _todaysSchedules,
          selectedFilter: _selectedFilter,
          searchQuery: _searchQuery,
          onRefresh: _loadSchedules,
          onMenuAction: _handleMenuAction,
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCattleScheduleForm,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Add Schedule',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
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
      case 'complete':
        _updateScheduleStatus(schedule, ScheduleStatus.completed);
        break;
      case 'cancel':
        _updateScheduleStatus(schedule, ScheduleStatus.cancelled);
        break;
      case 'reschedule':
        _updateScheduleStatus(schedule, ScheduleStatus.scheduled);
        break;
      case 'duplicate':
        _duplicateSchedule(schedule);
        break;
      case 'delete':
        _confirmDeleteSchedule(schedule);
        break;
    }
  }

  void _showCattleScheduleForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CattleScheduleForm(
          onScheduleAdded: _loadSchedules,
        ),
      ),
    );
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
    );
  }

  void _showScheduleDetails(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleDetailsDialog(schedule: schedule),
    );
  }

  Future<void> _updateScheduleStatus(Schedule schedule, String newStatus) async {
    try {
      await ScheduleService.updateScheduleStatus(schedule.id!, newStatus);
      _showSnackBar('Schedule ${newStatus.toLowerCase()} successfully');
      _loadSchedules(); // This will refresh all data and update counts
    } catch (e) {
      _showSnackBar('Error updating schedule: ${e.toString()}', isError: true);
    }
  }

  Future<void> _duplicateSchedule(Schedule schedule) async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await ScheduleService.duplicateSchedule(schedule, tomorrow);
      _showSnackBar('Schedule duplicated successfully');
      _loadSchedules();
    } catch (e) {
      _showSnackBar('Error duplicating schedule: ${e.toString()}', isError: true);
    }
  }

  void _confirmDeleteSchedule(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${schedule.title}"?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule(schedule);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    try {
      await ScheduleService.deleteSchedule(schedule.id!);
      _showSnackBar('Schedule deleted successfully');
      _loadSchedules();
    } catch (e) {
      _showSnackBar('Error deleting schedule: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}