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
        // Time slots with integrated events
        Expanded(
          child: _buildDayViewWithEvents(context),
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
        // Time slots with integrated events
        Expanded(
          child: _buildWeekViewWithEvents(context, startOfWeek),
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
    final hasSchedules = schedules.isNotEmpty;
    
    return GestureDetector(
      onTap: () => onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : hasSchedules 
                  ? AppColors.vibrantGreen.withOpacity(0.1) // Mark scheduled dates with vibrant green
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday 
              ? Border.all(color: AppColors.primary, width: 2)
              : hasSchedules
                  ? Border.all(color: AppColors.vibrantGreen, width: 1) // Add vibrant green border for scheduled dates
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
                      ? (isToday ? AppColors.primary : (hasSchedules ? AppColors.vibrantGreen : Colors.black)) // Use vibrant green text for scheduled dates
                      : const Color(0xFF9CA3AF),
                  fontWeight: isToday ? FontWeight.bold : (hasSchedules ? FontWeight.w600 : FontWeight.normal), // Make scheduled dates slightly bold
                  fontSize: 14,
                ),
              ),
            ),
            // No schedule indicators - clean month view
          ],
        ),
      ),
    );
  }



  Widget _buildDayViewWithEvents(BuildContext context) {
    final daySchedules = _getSchedulesForDate(selectedDate);
    final hourHeight = isMobile ? 40.0 : 50.0;
    final timeColumnWidth = isMobile ? 60.0 : 80.0;
    
    // Create a list of all time slots
    List<Widget> timeSlots = [];
    
    for (int hour = 0; hour < 24; hour++) {
      // Build the time slot row
      timeSlots.add(
        Container(
          height: hourHeight,
          child: Row(
            children: [
              // Time label
              Container(
                width: timeColumnWidth,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    _formatTime(hour, 0),
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
                    child: SizedBox(height: hourHeight), // Empty space for events
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Create spanning events
    List<Widget> spanningEvents = [];
    for (final schedule in daySchedules) {
      final startTime = schedule.scheduleDateTime;
      final duration = _getDurationAsDouble(schedule.duration);
      final endTime = startTime.add(Duration(minutes: (duration * 60).round()));
      
      // Calculate position and height for the spanning event
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final totalMinutes = endMinutes - startMinutes;
      final eventHeight = (totalMinutes / 60.0) * hourHeight;
      
      // Calculate top position
      final topPosition = (startMinutes / 60.0) * hourHeight;
      
      // Ensure minimum height for visibility
      final minHeight = isMobile ? 20.0 : 24.0;
      final finalHeight = eventHeight < minHeight ? minHeight : eventHeight;
      
      spanningEvents.add(
        Positioned(
          left: timeColumnWidth + (isMobile ? 4 : 8),
          right: (isMobile ? 4 : 8),
          top: topPosition,
          height: finalHeight,
          child: _buildSpanningEvent(schedule, isMobile, finalHeight),
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Stack(
        children: [
          Column(
            children: timeSlots,
          ),
          // Add vertical borders for the event area
          Positioned(
            left: timeColumnWidth,
            top: 0,
            height: 24 * hourHeight, // Fixed height based on 24 hours
            child: Container(
              width: 1,
              color: const Color(0xFFE5E7EB),
            ),
          ),
          // Add horizontal borders for each hour
          ...List.generate(24, (hour) {
            return Positioned(
              left: timeColumnWidth,
              right: 0,
              top: hour * hourHeight,
              child: Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),
            );
          }),
          ...spanningEvents,
        ],
      ),
    );
  }

  Widget _buildWeekViewWithEvents(BuildContext context, DateTime startOfWeek) {
    final hourHeight = isMobile ? 40.0 : 50.0;
    final timeColumnWidth = isMobile ? 60.0 : 80.0;
    
    // Create a list of all time slots
    List<Widget> timeSlots = [];
    
    for (int hour = 0; hour < 24; hour++) {
      // Build the time slot row
      timeSlots.add(
        Container(
          height: hourHeight,
          child: Row(
            children: [
              // Time label
              Container(
                width: timeColumnWidth,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    _formatTime(hour, 0),
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
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDateSelected(day),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 1 : 2),
                      child: SizedBox(height: hourHeight), // Empty space for events
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }
    
    // Create spanning events for each day
    List<Widget> spanningEvents = [];
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final day = startOfWeek.add(Duration(days: dayIndex));
      final daySchedules = _getSchedulesForDate(day);
      
      for (final schedule in daySchedules) {
        final startTime = schedule.scheduleDateTime;
        final duration = _getDurationAsDouble(schedule.duration);
        final endTime = startTime.add(Duration(minutes: (duration * 60).round()));
        
        // Calculate position and height for the spanning event
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;
        final totalMinutes = endMinutes - startMinutes;
        final eventHeight = (totalMinutes / 60.0) * hourHeight;
        
        // Calculate top position
        final topPosition = (startMinutes / 60.0) * hourHeight;
        
        // Calculate left position for the day column
        final dayColumnWidth = (MediaQuery.of(context).size.width - timeColumnWidth) / 7;
        final leftPosition = timeColumnWidth + (dayIndex * dayColumnWidth) + (isMobile ? 1 : 2);
        
        // Ensure minimum height for visibility
        final minHeight = isMobile ? 20.0 : 24.0;
        final finalHeight = eventHeight < minHeight ? minHeight : eventHeight;
        
        spanningEvents.add(
          Positioned(
            left: leftPosition,
            right: MediaQuery.of(context).size.width - leftPosition - dayColumnWidth + (isMobile ? 2 : 4),
            top: topPosition,
            height: finalHeight,
            child: _buildSpanningEvent(schedule, isMobile, finalHeight, isWeekView: true),
          ),
        );
      }
    }
    
    return SingleChildScrollView(
      child: Stack(
        children: [
          Column(
            children: timeSlots,
          ),
          // Add vertical borders for day columns
          ...List.generate(8, (index) {
            final dayColumnWidth = (MediaQuery.of(context).size.width - timeColumnWidth) / 7;
            final leftPosition = timeColumnWidth + (index * dayColumnWidth);
            return Positioned(
              left: leftPosition,
              top: 0,
              height: 24 * hourHeight, // Fixed height based on 24 hours
              child: Container(
                width: 1,
                color: const Color(0xFFE5E7EB),
              ),
            );
          }),
          // Add horizontal borders for each hour
          ...List.generate(24, (hour) {
            return Positioned(
              left: timeColumnWidth,
              right: 0,
              top: hour * hourHeight,
              child: Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),
            );
          }),
          ...spanningEvents,
        ],
      ),
    );
  }


  List<Schedule> _getSchedulesForDate(DateTime date) {
    return schedules.where((schedule) {
      return _isSameDay(schedule.scheduleDateTime, date);
    }).toList();
  }

  Widget _buildSpanningEvent(Schedule schedule, bool isMobile, double eventHeight, {bool isWeekView = false}) {
    final startTime = schedule.scheduleDateTime;
    final duration = _getDurationAsDouble(schedule.duration);
    final endTime = startTime.add(Duration(minutes: (duration * 60).round()));
    
    return GestureDetector(
      onTap: () => onScheduleTapped(schedule),
      child: Container(
        height: eventHeight,
        margin: EdgeInsets.symmetric(vertical: 1, horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: _getScheduleColor(schedule),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Row(
                children: [
                  Expanded(
                    child: isWeekView 
                        ? Container() // Empty content for Week view
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title
                              Text(
                                schedule.title,
                                style: TextStyle(
                                  fontSize: isMobile ? 9 : 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (eventHeight > 30) ...[
                                SizedBox(height: 2),
                                // Time range
                                Text(
                                  '${_formatTime(startTime.hour, startTime.minute)} - ${_formatTime(endTime.hour, endTime.minute)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 7 : 8,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }






  double _getDurationAsDouble(dynamic duration) {
    if (duration == null) return 1.0; // Default 1 hour if null
    
    if (duration is double) return duration;
    if (duration is int) return duration.toDouble();
    if (duration is String) {
      // Handle duration strings like "2h", "1.5h", "30m", "2.5h", etc.
      final durationStr = duration.toLowerCase().trim();
      
      // Check for hours format (e.g., "2h", "1.5h")
      if (durationStr.endsWith('h')) {
        final hourStr = durationStr.substring(0, durationStr.length - 1);
        final parsed = double.tryParse(hourStr);
        return parsed ?? 1.0;
      }
      
      // Check for minutes format (e.g., "30m", "90m")
      if (durationStr.endsWith('m')) {
        final minuteStr = durationStr.substring(0, durationStr.length - 1);
        final parsed = double.tryParse(minuteStr);
        return parsed != null ? parsed / 60.0 : 1.0; // Convert minutes to hours
      }
      
      // Try to parse as plain number (assume hours)
      final parsed = double.tryParse(durationStr);
      return parsed ?? 1.0;
    }
    
    return 1.0; // Default fallback
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }


  Color _getScheduleColor(Schedule schedule) {
    // Use vibrant green for all scheduled events
    return AppColors.vibrantGreen;
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
