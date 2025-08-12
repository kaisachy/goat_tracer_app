
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_card_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_empty_states_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/today_schedule_header_widget.dart';
import 'package:flutter/material.dart';
import '../../../../../models/schedule.dart';
import '../../../../../utils/schedule_utils.dart';


class ScheduleContent extends StatelessWidget {
  final TabController tabController;
  final bool isLoading;
  final List<Schedule> schedules;
  final List<Schedule> filteredSchedules;
  final List<Schedule> todaysSchedules;
  final ScheduleFilter selectedFilter;
  final String searchQuery;
  final Future<void> Function() onRefresh;
  final Function(String action, Schedule schedule) onMenuAction;

  const ScheduleContent({
    super.key,
    required this.tabController,
    required this.isLoading,
    required this.schedules,
    required this.filteredSchedules,
    required this.todaysSchedules,
    required this.selectedFilter,
    required this.searchQuery,
    required this.onRefresh,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading schedules...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: tabController,
      children: [
        _buildScheduleList(), // All
        _buildTodayScheduleList(), // Today
        _buildScheduleList(), // Upcoming
        _buildScheduleList(), // Overdue
        _buildScheduleList(), // Completed
      ],
    );
  }

  Widget _buildTodayScheduleList() {
    if (todaysSchedules.isEmpty) {
      return const ScheduleEmptyStates(
        type: ScheduleEmptyStateType.todayEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TodayScheduleHeader(todaysSchedules: todaysSchedules),
          const SizedBox(height: 16),
          ...filteredSchedules.map((schedule) => ScheduleCard(
            schedule: schedule,
            isToday: true,
            onMenuAction: onMenuAction,
          )),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    if (filteredSchedules.isEmpty) {
      return ScheduleEmptyStates(
        type: _getEmptyStateType(),
        hasSchedules: schedules.isNotEmpty,
        searchQuery: searchQuery,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredSchedules.length,
        itemBuilder: (context, index) {
          final schedule = filteredSchedules[index];
          return ScheduleCard(
            schedule: schedule,
            onMenuAction: onMenuAction,
          );
        },
      ),
    );
  }

  ScheduleEmptyStateType _getEmptyStateType() {
    if (searchQuery.isNotEmpty) {
      return ScheduleEmptyStateType.searchEmpty;
    }

    switch (selectedFilter) {
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
}