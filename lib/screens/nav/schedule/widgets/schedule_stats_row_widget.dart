import 'package:flutter/material.dart';
import '../../../../../constants/app_colors.dart';

class ScheduleStatsRow extends StatelessWidget {
  final Map<String, int> tabCounts;

  const ScheduleStatsRow({
    super.key,
    required this.tabCounts,
  });

  @override
  Widget build(BuildContext context) {
    final todayCount = tabCounts['today'] ?? 0;
    final upcomingCount = tabCounts['upcoming'] ?? 0;
    final overdueCount = tabCounts['overdue'] ?? 0;
    final totalCount = tabCounts['all'] ?? 0;
    final completedCount = tabCounts['completed'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Today', todayCount, AppColors.primary, Icons.today),
            const SizedBox(width: 12),
            _buildStatCard('Upcoming', upcomingCount, Colors.blue[600]!, Icons.upcoming),
            const SizedBox(width: 12),
            _buildStatCard('Overdue', overdueCount, Colors.red[600]!, Icons.warning),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildStatCard('Completed', completedCount, Colors.green[600]!, Icons.check_circle),
                  const SizedBox(width: 12),
                  _buildStatCard('Total', totalCount, AppColors.gold, Icons.event_note),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
