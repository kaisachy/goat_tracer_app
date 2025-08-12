import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

enum ScheduleEmptyStateType {
  allEmpty,
  todayEmpty,
  upcomingEmpty,
  overdueEmpty,
  completedEmpty,
  searchEmpty,
}

class ScheduleEmptyStates extends StatelessWidget {
  final ScheduleEmptyStateType type;
  final bool hasSchedules;
  final String? searchQuery;

  const ScheduleEmptyStates({
    super.key,
    required this.type,
    this.hasSchedules = false,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ScheduleEmptyStateType.todayEmpty:
        return _buildTodayEmptyState();
      case ScheduleEmptyStateType.allEmpty:
        return _buildAllEmptyState();
      case ScheduleEmptyStateType.upcomingEmpty:
        return _buildUpcomingEmptyState();
      case ScheduleEmptyStateType.overdueEmpty:
        return _buildOverdueEmptyState();
      case ScheduleEmptyStateType.completedEmpty:
        return _buildCompletedEmptyState();
      case ScheduleEmptyStateType.searchEmpty:
        return _buildSearchEmptyState();
    }
  }

  Widget _buildTodayEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.today_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No schedules for today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your free day!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No schedules found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (!hasSchedules) ...[
              const SizedBox(height: 8),
              Text(
                'Create your first schedule to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEmptyState() {
    return _buildEmptyStateWithIcon(
      icon: Icons.upcoming_outlined,
      title: 'No upcoming schedules',
      subtitle: 'All caught up for now!',
    );
  }

  Widget _buildOverdueEmptyState() {
    return _buildEmptyStateWithIcon(
      icon: Icons.warning_outlined,
      title: 'No overdue schedules',
      subtitle: 'Great! You\'re on top of everything.',
    );
  }

  Widget _buildCompletedEmptyState() {
    return _buildEmptyStateWithIcon(
      icon: Icons.check_circle_outline,
      title: 'No completed schedules',
      subtitle: 'Complete some schedules to see them here.',
    );
  }

  Widget _buildSearchEmptyState() {
    return _buildEmptyStateWithIcon(
      icon: Icons.search_off_outlined,
      title: 'No schedules match your search',
      subtitle: searchQuery != null ? 'Try searching for something else' : 'Try a different search term',
    );
  }

  Widget _buildEmptyStateWithIcon({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}