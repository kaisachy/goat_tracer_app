import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/models/schedule.dart';

class WebSchedulerWidget extends StatelessWidget {
  final List<Schedule> schedules;
  final DateTime selectedDate;
  final String currentView;
  final Function(DateTime) onDateSelected;
  final Function(Schedule) onScheduleTapped;
  final bool isMobile;

  const WebSchedulerWidget({
    super.key,
    required this.schedules,
    required this.selectedDate,
    required this.currentView,
    required this.onDateSelected,
    required this.onScheduleTapped,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    // Always show calendar, even with no events (like web version)
    return Container(
      child: _buildCalendarView(context),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    switch (currentView) {
      case 'day':
        return _buildDayView(context);
      case 'week':
        return _buildWeekView(context);
      case 'month':
        return _buildMonthView(context);
      default:
        return _buildWeekView(context);
    }
  }

  Widget _buildDayView(BuildContext context) {
    
    return Column(
      children: [
        // Time column header
        Container(
          height: isMobile ? 40 : 50,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 60 : 80,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Time',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(),
              ),
            ],
          ),
        ),
        // Time slots
        Expanded(
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              final timeString = _formatTime(hour, 0);
              final hourSchedules = _getSchedulesForHour(selectedDate, hour);
              
              return Container(
                height: isMobile ? 40 : 50,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Time label
                    Container(
                      width: isMobile ? 60 : 80,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          timeString,
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    // Event area
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onDateSelected(selectedDate),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
                          child: Row(
                            children: hourSchedules.map((schedule) {
                              return Expanded(
                                child: _buildScheduleEvent(schedule),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(BuildContext context) {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    
    return Column(
      children: [
        // Days of week header
        Container(
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Time column header - responsive width
              Container(
                width: MediaQuery.of(context).size.width < 600 ? 60 : 80,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Time',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                    ),
                  ),
                ),
              ),
              // Day headers
              ...List.generate(7, (index) {
                final day = startOfWeek.add(Duration(days: index));
                final isToday = _isSameDay(day, DateTime.now());
                
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayName(day.weekday),
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600 ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.primary : const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.primary : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // Time slots
        Expanded(
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              final timeString = _formatTime(hour, 0);
              final isMobile = MediaQuery.of(context).size.width < 600;
              
              return Container(
                height: isMobile ? 40 : 50,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Time label - responsive width
                    Container(
                      width: isMobile ? 60 : 80,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          timeString,
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    // Day columns
                    ...List.generate(7, (dayIndex) {
                      final day = startOfWeek.add(Duration(days: dayIndex));
                      final daySchedules = _getSchedulesForHour(day, hour);
                      
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => onDateSelected(day),
                            child: Container(
                              padding: EdgeInsets.all(isMobile ? 1 : 2),
                              child: Column(
                                children: daySchedules.map((schedule) {
                                  return Expanded(
                                    child: _buildScheduleEvent(schedule),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstDayOfWeek = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    
    return Column(
      children: [
        // Days of week header
        Container(
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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
              ? AppColors.primary.withOpacity(0.1)
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
                  color: isCurrentMonth 
                      ? (isToday ? AppColors.primary : Colors.black)
                      : const Color(0xFF9CA3AF),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            // Schedule indicators
            if (schedules.isNotEmpty)
              Expanded(
                child: Column(
                  children: schedules.take(3).map((schedule) {
                    return _buildScheduleIndicator(schedule);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleEvent(Schedule schedule) {
    return GestureDetector(
      onTap: () => onScheduleTapped(schedule),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 0.5 : 1, vertical: isMobile ? 0.5 : 1),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4, vertical: isMobile ? 1 : 2),
        decoration: BoxDecoration(
          color: _getScheduleColor(schedule),
          borderRadius: BorderRadius.circular(isMobile ? 2 : 4),
          border: schedule.status.toLowerCase() == 'cancelled' 
              ? Border.all(color: Colors.red, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (schedule.status.toLowerCase() == 'cancelled')
              Icon(
                Icons.cancel,
                size: isMobile ? 8 : 10,
                color: Colors.white,
              ),
            if (schedule.status.toLowerCase() == 'completed')
              Icon(
                Icons.check,
                size: isMobile ? 8 : 10,
                color: Colors.white,
              ),
            if (schedule.isOverdue)
              Icon(
                Icons.warning,
                size: isMobile ? 8 : 10,
                color: Colors.white,
              ),
            if (schedule.status.toLowerCase() == 'cancelled' || 
                schedule.status.toLowerCase() == 'completed' || 
                schedule.isOverdue)
              SizedBox(width: isMobile ? 2 : 4),
            Expanded(
              child: Text(
                schedule.title,
                style: TextStyle(
                  fontSize: isMobile ? 8 : 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: _getScheduleColor(schedule),
          borderRadius: BorderRadius.circular(4),
          border: schedule.status.toLowerCase() == 'cancelled' 
              ? Border.all(color: Colors.red, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (schedule.status.toLowerCase() == 'cancelled')
              const Icon(
                Icons.cancel,
                size: 8,
                color: Colors.white,
              ),
            if (schedule.status.toLowerCase() == 'completed')
              const Icon(
                Icons.check,
                size: 8,
                color: Colors.white,
              ),
            if (schedule.isOverdue)
              const Icon(
                Icons.warning,
                size: 8,
                color: Colors.white,
              ),
            if (schedule.status.toLowerCase() == 'cancelled' || 
                schedule.status.toLowerCase() == 'completed' || 
                schedule.isOverdue)
              const SizedBox(width: 2),
            Expanded(
              child: Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Schedule> _getSchedulesForDate(DateTime date) {
    return schedules.where((schedule) {
      return _isSameDay(schedule.scheduleDateTime, date);
    }).toList();
  }

  List<Schedule> _getSchedulesForHour(DateTime date, int hour) {
    return schedules.where((schedule) {
      return _isSameDay(schedule.scheduleDateTime, date) &&
             schedule.scheduleDateTime.hour == hour;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Color _getScheduleColor(Schedule schedule) {
    // Handle cancelled events with a different color
    if (schedule.status.toLowerCase() == 'cancelled') {
      return Colors.grey;
    }
    
    // Handle completed events with a different color
    if (schedule.status.toLowerCase() == 'completed') {
      return Colors.green;
    }
    
    // Handle overdue events with a different color
    if (schedule.isOverdue) {
      return Colors.red;
    }
    
    // Default colors based on type
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

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
