import 'package:flutter/material.dart';
import '../../../../../constants/app_colors.dart';
import '../../../../../models/schedule.dart';

class TodayScheduleHeader extends StatelessWidget {
  final List<Schedule> todaysSchedules;

  const TodayScheduleHeader({
    super.key,
    required this.todaysSchedules,
  });

  @override
  Widget build(BuildContext context) {
    // Use Philippines time for display
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final completedToday = todaysSchedules.where((s) => s.isCompleted).length;
    final pendingToday = todaysSchedules.length - completedToday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.today,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDateFull(now),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (todaysSchedules.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProgressItem('Pending', pendingToday, Colors.orange[600]!),
                const SizedBox(width: 24),
                _buildProgressItem('Completed', completedToday, Colors.green[600]!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDateFull(DateTime date) {
    // Convert to Philippines time (UTC+8)
    final phDate = date.toUtc().add(const Duration(hours: 8));

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return '${weekdays[phDate.weekday - 1]}, ${months[phDate.month - 1]} ${phDate.day}';
  }
}