import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/models/schedule.dart';
import 'package:cattle_tracer_app/services/scheduler/scheduler_service.dart';
import 'widgets/web_scheduler_widget.dart';

class FarmerSchedulerContentWidget extends StatefulWidget {
  const FarmerSchedulerContentWidget({super.key});

  @override
  State<FarmerSchedulerContentWidget> createState() => _FarmerSchedulerContentWidgetState();
}

class _FarmerSchedulerContentWidgetState extends State<FarmerSchedulerContentWidget> {
  List<Schedule> _schedules = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _currentView = 'week'; // Default to week view like web version

  @override
  void initState() {
    super.initState();
    // Always show calendar first, then load events
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final schedules = await SchedulerService.getAllSchedules();
      
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
      
      // Show success message if schedules were loaded
      if (schedules.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${schedules.length} scheduled events'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // On error, still show calendar but with empty schedules
      setState(() {
        _schedules = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedules: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // Automatically switch to Day view when a date is clicked from Month view
      if (_currentView == 'month') {
        _currentView = 'day';
      }
    });
  }

  void _onViewChanged(String view) {
    setState(() {
      _currentView = view;
    });
  }

  void _onScheduleTapped(Schedule schedule) {
    // Show event details popup like web version
    _showEventDetailsPopup(schedule);
  }

  void _showEventDetailsPopup(Schedule schedule) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _buildEventDetailsPopup(schedule),
    );
  }

  Widget _buildEventDetailsPopup(Schedule schedule) {
    final startTime = schedule.scheduleDateTime;
    final duration = _getDurationAsDouble(schedule.duration);
    final endTime = startTime.add(Duration(minutes: (duration * 60).round()));
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 20,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Header with vibrant green
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.vibrantGreen,
                    AppColors.vibrantGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.vibrantGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(schedule),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            schedule.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
            // Enhanced Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time and Duration Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.vibrantGreen.withOpacity(0.1),
                            AppColors.vibrantGreen.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.vibrantGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppColors.vibrantGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Schedule Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.vibrantGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatTimeRange(startTime, endTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Description Card
                    if (schedule.details != null && schedule.details!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              schedule.details!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Enhanced Metadata Grid
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildEnhancedMetadataItem(
                            Icons.person_outline,
                            'Created by',
                            schedule.creatorName ?? 'Unknown User',
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildEnhancedMetadataItem(
                            Icons.location_on_outlined,
                            'Location',
                            schedule.location ?? 'No location specified',
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildEnhancedMetadataItem(
                            Icons.notifications_outlined,
                            'Reminder',
                            schedule.reminder ?? 'No Reminder',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMetadataItem(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(Schedule schedule) {
    if (schedule.status.toLowerCase() == 'cancelled') {
      return Icons.cancel_outlined;
    } else if (schedule.status.toLowerCase() == 'completed') {
      return Icons.check_circle_outline;
    } else if (schedule.isOverdue) {
      return Icons.warning_amber_outlined;
    } else {
      return Icons.event_outlined;
    }
  }

  String _formatTimeRange(DateTime startTime, DateTime endTime) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = months[startTime.month - 1];
    final day = startTime.day;
    final year = startTime.year;
    
    // Format start time
    final startHour = startTime.hour;
    final startMinute = startTime.minute;
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final startDisplayHour = startHour > 12 ? startHour - 12 : (startHour == 0 ? 12 : startHour);
    final startTimeString = '${startDisplayHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} $startPeriod';
    
    // Format end time
    final endHour = endTime.hour;
    final endMinute = endTime.minute;
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final endDisplayHour = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
    final endTimeString = '${endDisplayHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} $endPeriod';
    
    return '$month $day, $year at $startTimeString - $endTimeString';
  }

  double _getDurationAsDouble(dynamic duration) {
    if (duration == null) return 1.0;
    
    if (duration is String) {
      final durationStr = duration.toLowerCase().trim();
      
      // Handle formats like "2h", "1.5h", "30m", "90m"
      if (durationStr.endsWith('h')) {
        final hoursStr = durationStr.substring(0, durationStr.length - 1);
        return double.tryParse(hoursStr) ?? 1.0;
      } else if (durationStr.endsWith('m')) {
        final minutesStr = durationStr.substring(0, durationStr.length - 1);
        final minutes = double.tryParse(minutesStr) ?? 60.0;
        return minutes / 60.0; // Convert minutes to hours
      } else {
        // Try to parse as a number
        return double.tryParse(durationStr) ?? 1.0;
      }
    } else if (duration is int) {
      return duration.toDouble();
    } else if (duration is double) {
      return duration;
    }
    
    return 1.0; // Default to 1 hour
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeString = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    
    return '$month $day, $year at $timeString';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Navigation controls with date label inline
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildNavButton(Icons.chevron_left, () => _navigate(-1)),
                        const SizedBox(width: 8),
                        _buildNavButton(Icons.chevron_right, () => _navigate(1)),
                        const SizedBox(width: 8),
                        _buildTodayButton(),
                      ],
                    ),
                    // Date label inline with navigation
                    Expanded(
                      child: Center(
                        child: Text(
                          _getCurrentWeekText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // View toggles below navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildViewToggle('day', 'Day'),
                    const SizedBox(width: 8),
                    _buildViewToggle('week', 'Week'),
                    const SizedBox(width: 8),
                    _buildViewToggle('month', 'Month'),
                  ],
                ),
              ],
            ),
          ),
          // Calendar content - always show calendar like web version
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadSchedules,
                    child: WebSchedulerWidget(
                      schedules: _schedules,
                      selectedDate: _selectedDate,
                      currentView: _currentView,
                      onDateSelected: _onDateSelected,
                      onScheduleTapped: _onScheduleTapped,
                      isMobile: MediaQuery.of(context).size.width < 600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTodayButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = DateTime.now();
          });
        },
        child: const Text(
          'Today',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(String view, String label) {
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () => _onViewChanged(view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _navigate(int direction) {
    setState(() {
      if (_currentView == 'day') {
        _selectedDate = _selectedDate.add(Duration(days: direction));
      } else if (_currentView == 'week') {
        _selectedDate = _selectedDate.add(Duration(days: direction * 7));
      } else if (_currentView == 'month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + direction);
      }
    });
  }

  String _getCurrentWeekText() {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (_currentView == 'day') {
      final month = monthNames[_selectedDate.month - 1];
      return '$month ${_selectedDate.day}, ${_selectedDate.year}';
    } else if (_currentView == 'week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final startMonth = monthNames[startOfWeek.month - 1];
      final endMonth = monthNames[endOfWeek.month - 1];
      
      if (startOfWeek.month == endOfWeek.month) {
        // Same month: "Oct 5 - Oct 11, 2025"
        return '$startMonth ${startOfWeek.day} - $endMonth ${endOfWeek.day}, ${endOfWeek.year}';
      } else {
        // Different months: "Oct 30 - Nov 5, 2025"
        return '$startMonth ${startOfWeek.day} - $endMonth ${endOfWeek.day}, ${endOfWeek.year}';
      }
    } else {
      // Month view
      final month = monthNames[_selectedDate.month - 1];
      return '$month ${_selectedDate.year}';
    }
  }

}
