import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/models/schedule.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/schedule/schedule_service.dart';
import 'package:intl/intl.dart';

class CattleSchedulesSection extends StatefulWidget {
  final Cattle cattle;
  const CattleSchedulesSection({super.key, required this.cattle});

  @override
  State<CattleSchedulesSection> createState() => _CattleSchedulesSectionState();
}

class _CattleSchedulesSectionState extends State<CattleSchedulesSection> {
  List<Schedule>? schedules;
  bool isLoadingSchedules = true;
  String? scheduleError;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (widget.cattle.tagNo.isEmpty) {
      if (mounted) {
        setState(() {
          isLoadingSchedules = false;
          schedules = [];
          scheduleError = 'Cattle tag is required to load schedules';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        isLoadingSchedules = true;
        scheduleError = null;
      });
    }
    try {
      final normalizedTag = widget.cattle.tagNo.trim().toUpperCase();
      log('Loading schedules for cattle tag: "$normalizedTag"');
      final fetchedSchedules =
      await ScheduleService.getSchedulesForCattle(normalizedTag);
      log('Successfully fetched ${fetchedSchedules.length} schedules');
      if (mounted) {
        setState(() {
          schedules = fetchedSchedules;
          isLoadingSchedules = false;
          scheduleError = null;
        });
      }
    } catch (e) {
      log('Error loading schedules for cattle ${widget.cattle.tagNo}: $e');
      if (mounted) {
        setState(() {
          schedules = [];
          isLoadingSchedules = false;
          scheduleError = 'Failed to load schedules: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: _buildScheduleSection(),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The original Row containing the schedule count has been removed.
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: _buildScheduleContent(),
        ),
      ],
    );
  }

  Widget _buildScheduleContent() {
    if (isLoadingSchedules) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      );
    }
    if (scheduleError != null) {
      return Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.textSecondary.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load schedules',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scheduleError!,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadSchedules,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      );
    }
    if (schedules == null || schedules!.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.event_busy,
            color: AppColors.textSecondary.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            widget.cattle.tagNo.isEmpty
                ? 'Cattle tag is required to load schedules'
                : 'No schedules assigned to ${widget.cattle.tagNo}',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadSchedules,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      );
    }
    final sortedSchedules = List<Schedule>.from(schedules!)
      ..sort((a, b) => b.scheduleDateTime.compareTo(a.scheduleDateTime));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleStats(),
        const SizedBox(height: 16),
        ...sortedSchedules
            .take(3)
            .map((schedule) => _buildScheduleItem(schedule)),
        if (sortedSchedules.length > 3) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _showAllSchedules,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('View all ${sortedSchedules.length} schedules'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleStats() {
    final completedCount = schedules!.where((s) => s.isCompleted).length;
    final overdueCount = schedules!.where((s) => s.isOverdue).length;
    final upcomingCount = schedules!.where((s) => s.isUpcoming()).length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (completedCount > 0)
          _buildStatChip('Completed', completedCount, AppColors.darkGreen),
        if (overdueCount > 0)
          _buildStatChip('Overdue', overdueCount, Colors.red),
        if (upcomingCount > 0)
          _buildStatChip('Upcoming', upcomingCount, AppColors.accent),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    Color statusColor = _getScheduleStatusColor(schedule);
    IconData statusIcon = _getScheduleStatusIcon(schedule);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  statusIcon,
                  size: 14,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _formatScheduleDate(schedule.scheduleDateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 12,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    schedule.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      schedule.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScheduleStatusColor(Schedule schedule) {
    if (schedule.isOverdue) return Colors.red;
    if (schedule.isCompleted) return AppColors.darkGreen;
    if (schedule.isCancelled) return AppColors.textSecondary;
    if (schedule.isUpcoming(days: 1)) return AppColors.accent;
    return AppColors.primary;
  }

  IconData _getScheduleStatusIcon(Schedule schedule) {
    if (schedule.isOverdue) return Icons.warning;
    if (schedule.isCompleted) return Icons.check_circle;
    if (schedule.isCancelled) return Icons.cancel;
    return Icons.schedule;
  }

  String _formatScheduleDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • h:mm a').format(dateTime);
  }

  void _showAllSchedules() {
    if (schedules == null || schedules!.isEmpty) return;
    final sortedSchedules = List<Schedule>.from(schedules!)
      ..sort((a, b) => b.scheduleDateTime.compareTo(a.scheduleDateTime));
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Schedules',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'for ${widget.cattle.tagNo}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedSchedules.length,
                  itemBuilder: (context, index) {
                    return _buildScheduleItem(sortedSchedules[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}