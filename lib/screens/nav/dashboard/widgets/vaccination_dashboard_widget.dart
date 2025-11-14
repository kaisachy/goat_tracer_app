import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/models/vaccination_schedule.dart';
import 'package:goat_tracer_app/models/schedule.dart';
import 'package:goat_tracer_app/services/vaccination_service.dart';
import 'package:goat_tracer_app/services/schedule/schedule_service.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/home_screen.dart';

class VaccinationDashboardWidget extends StatefulWidget {
  final List<goat> allgoat;
  final List<Map<String, dynamic>> allEvents;

  const VaccinationDashboardWidget({
    super.key,
    required this.allgoat,
    required this.allEvents,
  });

  @override
  State<VaccinationDashboardWidget> createState() => _VaccinationDashboardWidgetState();
}

class _VaccinationDashboardWidgetState extends State<VaccinationDashboardWidget> {
  List<VaccinationSchedule> vaccinationSchedules = [];
  List<Map<String, dynamic>> goatNeedingVaccination = [];
  Map<String, dynamic> vaccinationStats = {};
  List<Schedule> scheduledVaccinations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVaccinationData();
  }

  Future<void> _loadVaccinationData() async {
    try {
      setState(() => isLoading = true);

      // Generate recommended vaccination schedules (for stats and goat-needing section)
      final schedules = await VaccinationService().generateVaccinationSchedules(
        allgoat: widget.allgoat,
        allEvents: widget.allEvents,
      );

      // Get goat needing vaccination
      final goatNeeding = VaccinationService().getgoatNeedingVaccination(
        schedules: schedules,
        allgoat: widget.allgoat,
      );

      // Get vaccination statistics
      final stats = VaccinationService().getVaccinationStatistics(
        schedules: schedules,
        allgoat: widget.allgoat,
      );

      // Fetch actual scheduled vaccinations from backend schedule system
      final scheduled = await ScheduleService.getSchedules(
        type: 'vaccination',
        status: 'Scheduled',
      );

      if (mounted) {
        setState(() {
          vaccinationSchedules = schedules;
          goatNeedingVaccination = goatNeeding;
          vaccinationStats = stats;
          scheduledVaccinations = scheduled;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildOverviewSummaryRow(),
          const SizedBox(height: 16),
          _buildScheduledOverviewList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.vibrantGreen),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.vibrantGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.vaccines_rounded,
            color: AppColors.vibrantGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Vaccination Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSummaryRow() {
    final overdue = scheduledVaccinations.where((s) => s.scheduleDateTime.isBefore(DateTime.now())).length;
    final today = scheduledVaccinations.where((s) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final scheduleDate = DateTime(s.scheduleDateTime.year, s.scheduleDateTime.month, s.scheduleDateTime.day);
      return scheduleDate == todayDate;
    }).length;
    final upcoming = scheduledVaccinations.where((s) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final weekLater = todayDate.add(const Duration(days: 7));
      final d = DateTime(s.scheduleDateTime.year, s.scheduleDateTime.month, s.scheduleDateTime.day);
      return !d.isBefore(weekLater);
    }).length;

    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Today', today.toString(), Icons.today, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('Upcoming', upcoming.toString(), Icons.upcoming, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('Overdue', overdue.toString(), Icons.warning, Colors.red)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledOverviewList() {
    if (scheduledVaccinations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule_outlined, color: Colors.grey[600]!, size: 28),
            const SizedBox(height: 8),
            Text(
              'No vaccination schedules yet',
              style: TextStyle(color: Colors.grey[700]!, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a vaccination schedule from the Schedule tab',
              style: TextStyle(color: Colors.grey[600]!, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort and group by date: Today, Tomorrow, This Week, Later
    final sorted = List<Schedule>.from(scheduledVaccinations)
      ..sort((a, b) => a.scheduleDateTime.compareTo(b.scheduleDateTime));

    final Map<String, List<Schedule>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekLater = today.add(const Duration(days: 7));

    for (final s in sorted) {
      final d = DateTime(s.scheduleDateTime.year, s.scheduleDateTime.month, s.scheduleDateTime.day);
      String key;
      if (d == today) {
        key = 'Today';
      } else if (d == tomorrow) {
        key = 'Tomorrow';
      } else if (d.isBefore(weekLater)) {
        key = 'This Week';
      } else {
        key = 'Upcoming';
      }
      groups.putIfAbsent(key, () => []).add(s);
    }

    final order = ['Today', 'Tomorrow', 'This Week', 'Upcoming'];
    final keys = order.where((k) => groups.containsKey(k)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...keys.map((k) => _buildDateGroup(k, groups[k]!)),
      ],
    );
  }

  Widget _buildDateGroup(String label, List<Schedule> schedules) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.vibrantGreen.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.vibrantGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.vibrantGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${schedules.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.vibrantGreen),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: schedules.take(5).map((s) => _buildScheduleRow(s)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(Schedule schedule) {
    final isOverdue = schedule.scheduleDateTime.isBefore(DateTime.now());
    final daysUntilDue = schedule.scheduleDateTime.difference(DateTime.now()).inDays;

    void openScheduleScreen() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(initialSelectedIndex: 4),
        ),
      );
    }

    return InkWell(
      onTap: openScheduleScreen,
      borderRadius: BorderRadius.circular(10),
      child: Container
      (
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue ? Colors.red[50]! : Colors.grey[50]!,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isOverdue ? Colors.red[300]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red[100]! : AppColors.vibrantGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(isOverdue ? Icons.warning : Icons.schedule, size: 16, color: isOverdue ? Colors.red[600]! : AppColors.vibrantGreen),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.vaccineType ?? schedule.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatScheduleDate(schedule.scheduleDateTime),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isOverdue ? Colors.red[100]! : Colors.orange[100]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isOverdue ? 'Overdue' : (daysUntilDue <= 7 ? 'Due in $daysUntilDue d' : 'Scheduled'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isOverdue ? Colors.red[700]! : Colors.orange[700]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScheduleDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
