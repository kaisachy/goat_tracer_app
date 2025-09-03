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
  final String? initialSearch;

  const ScheduleScreen({super.key, this.initialSearch});

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

      // Apply initial search if provided
      if (widget.initialSearch != null && widget.initialSearch!.trim().isNotEmpty) {
        _searchController.text = widget.initialSearch!;
        _searchQuery = widget.initialSearch!;
        // Ensure the All tab is selected so filter applies across all
        if (_tabController.index != _allTab) {
          _tabController.index = _allTab;
        }
      }

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
            (schedule.veterinarian?.toLowerCase().contains(query) ?? false) ||
            (schedule.vaccineType?.toLowerCase().contains(query) ?? false);
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
              (schedule.veterinarian?.toLowerCase().contains(query) ?? false) ||
              (schedule.vaccineType?.toLowerCase().contains(query) ?? false);
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
      resizeToAvoidBottomInset: false,
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
              child: const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: ScheduleStatsRow(
              tabCounts: _tabCounts,
            ),
          ),
          SliverToBoxAdapter(
            child: ScheduleTabBar(
              tabController: _tabController,
              tabCounts: _tabCounts,
            ),
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
          onMenuAction: (action, schedule) async {
            if (action == 'view') {
              await showDialog(
                context: context,
                builder: (_) => ScheduleDetailsDialog(schedule: schedule),
              );
            }
          },
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.vibrantGreen,
      ),
    );
  }
}