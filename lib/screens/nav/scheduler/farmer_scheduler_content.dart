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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      schedule.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        schedule.details ?? 'No description provided',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Metadata
                    _buildMetadataItem(Icons.calendar_today, 'Date and time', _formatDateTime(schedule.scheduleDateTime)),
                    const SizedBox(height: 12),
                    _buildMetadataItem(Icons.timer, 'Duration', '${schedule.duration ?? '1'}h'),
                    const SizedBox(height: 12),
                    _buildMetadataItem(Icons.notifications, 'Reminder', schedule.reminder ?? 'No Reminder'),
                    const SizedBox(height: 12),
                    _buildMetadataItem(Icons.person, 'Created by', schedule.creatorName ?? 'Unknown User'),
                    const SizedBox(height: 20),
                    // Action buttons (view-only for farmers)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
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

  Widget _buildMetadataItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
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
