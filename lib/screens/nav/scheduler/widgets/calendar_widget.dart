import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/models/schedule.dart';

class CalendarWidget extends StatelessWidget {
  final List<Schedule> schedules;
  final DateTime selectedDate;
  final String currentView;
  final Function(DateTime) onDateSelected;
  final Function(Schedule) onScheduleTapped;

  const CalendarWidget({
    super.key,
    required this.schedules,
    required this.selectedDate,
    required this.currentView,
    required this.onDateSelected,
    required this.onScheduleTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildCalendarView(),
    );
  }

  Widget _buildCalendarView() {
    switch (currentView) {
      case 'month':
        return _buildMonthView();
      case 'week':
        return _buildWeekView();
      case 'day':
        return _buildDayView();
      default:
        return _buildMonthView();
    }
  }

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstDayOfWeek = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    
    return Column(
      children: [
        // Days of week header
        _buildDaysOfWeekHeader(),
        const SizedBox(height: 8),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final date = firstDayOfWeek.add(Duration(days: index));
              final isCurrentMonth = date.month == selectedDate.month;
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, selectedDate);
              final daySchedules = _getSchedulesForDate(date);
              
              return _buildCalendarDay(
                date: date,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                schedules: daySchedules,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    
    return Column(
      children: [
        // Days of week header
        _buildDaysOfWeekHeader(),
        const SizedBox(height: 8),
        // Week grid
        Expanded(
          child: Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, selectedDate);
              final daySchedules = _getSchedulesForDate(date);
              
              return Expanded(
                child: _buildWeekDay(
                  date: date,
                  isToday: isToday,
                  isSelected: isSelected,
                  schedules: daySchedules,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    final daySchedules = _getSchedulesForDate(selectedDate);
    
    return Column(
      children: [
        // Date header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Schedules list
        Expanded(
          child: daySchedules.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: daySchedules.length,
                  itemBuilder: (context, index) {
                    return _buildScheduleCard(daySchedules[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekHeader() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      children: days.map((day) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarDay({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required List<Schedule> schedules,
  }) {
    return GestureDetector(
      onTap: () => onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : isToday 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday 
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // Date number
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : isCurrentMonth 
                          ? AppColors.textPrimary 
                          : AppColors.textSecondary,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Schedule indicators
            if (schedules.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    if (schedules.length <= 3)
                      ...schedules.take(3).map((schedule) => _buildScheduleIndicator(schedule))
                    else ...[
                      ...schedules.take(2).map((schedule) => _buildScheduleIndicator(schedule)),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${schedules.length - 2}',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDay({
    required DateTime date,
    required bool isToday,
    required bool isSelected,
    required List<Schedule> schedules,
  }) {
    return GestureDetector(
      onTap: () => onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : isToday 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday 
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? Colors.white 
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? Colors.white 
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Schedules
            Expanded(
              child: schedules.isEmpty
                  ? const SizedBox()
                  : ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        return _buildScheduleIndicator(schedules[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleIndicator(Schedule schedule) {
    return GestureDetector(
      onTap: () => onScheduleTapped(schedule),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getScheduleColor(schedule),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          schedule.title,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return GestureDetector(
      onTap: () => onScheduleTapped(schedule),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getScheduleColor(schedule),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Schedule details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(schedule.scheduleDateTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (schedule.details != null && schedule.details!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        schedule.details!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(schedule.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                schedule.status,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules for this day',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<Schedule> _getSchedulesForDate(DateTime date) {
    return schedules.where((schedule) {
      return _isSameDay(schedule.scheduleDateTime, date);
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Color _getScheduleColor(Schedule schedule) {
    switch (schedule.type.toLowerCase()) {
      case 'vaccination':
        return Colors.blue;
      case 'deworming':
        return Colors.orange;
      case 'hoof trimming':
        return Colors.purple;
      case 'feed':
        return Colors.green;
      case 'weigh':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

