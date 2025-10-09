import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/models/vaccination_schedule.dart';
import 'package:cattle_tracer_app/services/vaccination_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_history_service.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/schedule_form.dart';
import 'package:cattle_tracer_app/models/schedule.dart';
import 'package:cattle_tracer_app/services/schedule/schedule_service.dart';


class VaccinationScheduleScreen extends StatefulWidget {
  final VoidCallback? onAnyScheduleAdded;
  const VaccinationScheduleScreen({super.key, this.onAnyScheduleAdded});

  @override
  State<VaccinationScheduleScreen> createState() => _VaccinationScheduleScreenState();
}

class _VaccinationScheduleScreenState extends State<VaccinationScheduleScreen>
    with TickerProviderStateMixin {
  List<Cattle> allCattle = [];
  List<Map<String, dynamic>> allEvents = [];
  List<VaccinationSchedule> vaccinationSchedules = [];
  List<Map<String, dynamic>> cattleNeedingVaccination = [];
  Map<String, List<VaccineType>> vaccinesByStage = {};
  // key: TAG|vaccineType(lower)
  final Map<String, Schedule> _scheduledByCattleVaccine = {};
  
  bool isLoading = true;
  String? error;
  String selectedFilter = 'All'; // All, Overdue, Due Soon, Pending, Completed
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVaccinationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openScheduleForm(String vaccineType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleForm(
          preSelectedVaccineType: vaccineType,
          onScheduleAdded: () {
            // Reload data when schedule is added
            _loadVaccinationData();
            // Notify parent (e.g., EventScheduleScreen Schedule tab) to reload
            widget.onAnyScheduleAdded?.call();
          },
        ),
      ),
    );
  }

  Future<void> _loadVaccinationData() async {
    try {
      setState(() => isLoading = true);

      final cattleData = await CattleService.getAllCattle();
      final eventsData = await CattleHistoryService.getCattleHistory();
      // Load existing scheduled vaccination schedules from backend
      final existingVaccinationSchedules = await ScheduleService.getSchedules(
        type: ScheduleType.vaccination,
        status: ScheduleStatus.scheduled,
      );

      final schedules = await VaccinationService().generateVaccinationSchedules(
        allCattle: cattleData,
        allEvents: eventsData,
      );

      final cattleNeeding = VaccinationService().getCattleNeedingVaccination(
        schedules: schedules,
        allCattle: cattleData,
      );

      final vaccinesByStageData = VaccinationService().getVaccinesByStage();

      // Build lookup map for quick checks per cattle+vaccine
      _scheduledByCattleVaccine.clear();
      for (final sched in existingVaccinationSchedules) {
        if (sched.vaccineType == null || sched.vaccineType!.isEmpty) continue;
        final vaccineKeyName = sched.vaccineType!.toLowerCase();
        for (final tag in sched.cattleTagsList) {
          final key = _scheduledKey(tag, vaccineKeyName);
          // Keep the earliest upcoming schedule if multiple
          if (_scheduledByCattleVaccine.containsKey(key)) {
            final current = _scheduledByCattleVaccine[key]!;
            if (sched.scheduleDateTime.isBefore(current.scheduleDateTime)) {
              _scheduledByCattleVaccine[key] = sched;
            }
          } else {
            _scheduledByCattleVaccine[key] = sched;
          }
        }
      }

      if (mounted) {
        setState(() {
          allCattle = cattleData;
          allEvents = eventsData;
          vaccinationSchedules = schedules;
          cattleNeedingVaccination = cattleNeeding;
          vaccinesByStage = vaccinesByStageData;
          isLoading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load vaccination data: $e';
          isLoading = false;
        });
      }
    }
  }

  String _scheduledKey(String cattleTag, String vaccineTypeLower) {
    return '${cattleTag.trim().toUpperCase()}|$vaccineTypeLower';
  }

  Schedule? _getScheduledFor(String cattleTag, String vaccineType) {
    final key = _scheduledKey(cattleTag, vaccineType.toLowerCase());
    return _scheduledByCattleVaccine[key];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.vibrantGreen,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.vibrantGreen,
              tabs: const [
                Tab(text: 'Schedule', icon: Icon(Icons.schedule)),
                Tab(text: 'Protocol', icon: Icon(Icons.medical_information)),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : error != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildScheduleTab(),
                          _buildProtocolTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.vibrantGreen),
          SizedBox(height: 16),
          Text(
            'Loading Vaccination Data...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadVaccinationData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return RefreshIndicator(
      onRefresh: _loadVaccinationData,
      color: AppColors.vibrantGreen,
      child: _buildVaccineTypeList(),
    );
  }

  Widget _buildVaccineTypeList() {
    // Group schedules by vaccine type (including empty ones)
    final Map<String, List<VaccinationSchedule>> groupedSchedules = {};
    
    // Initialize with all vaccine types from protocol (even if empty)
    for (final vaccineType in VaccinationProtocol.vaccineTypes) {
      groupedSchedules[vaccineType.name] = [];
    }
    
    // Add actual schedules
    for (final schedule in vaccinationSchedules) {
      if (groupedSchedules.containsKey(schedule.vaccineType)) {
        groupedSchedules[schedule.vaccineType]!.add(schedule);
      }
    }

    // Group vaccines by stage
    final Map<String, List<String>> vaccinesByStageLocal = {};
    for (final vaccineType in VaccinationProtocol.vaccineTypes) {
      final stage = vaccineType.applicableStages.isNotEmpty 
          ? vaccineType.applicableStages.first 
          : 'Other';
      
      vaccinesByStageLocal.putIfAbsent(stage, () => []);
      vaccinesByStageLocal[stage]!.add(vaccineType.name);
    }

    // Sort stages by priority
    final stagePriority = {
      'Newborn Calf': 0,
      'Pre-weaning Calves': 1,
      'Weaned Calves / Growers / Steer': 2,
      'Replacement Heifers': 3,
      'Breeding Cows & Bulls': 4,
      'Pregnant Heifer & Cow': 5,
      'Other': 999,
    };

    final sortedStages = vaccinesByStageLocal.keys.toList()
      ..sort((a, b) => (stagePriority[a] ?? 999).compareTo(stagePriority[b] ?? 999));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedStages.length,
      itemBuilder: (context, index) {
        final stage = sortedStages[index];
        final vaccineTypes = vaccinesByStageLocal[stage]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.vibrantGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...vaccineTypes.map((vaccineType) {
              final allForType = groupedSchedules[vaccineType] ?? [];
              final forThisStage = allForType.where((s) => s.cattleStage == stage).toList();
              return _buildVaccineTypeCard(vaccineType, forThisStage);
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildVaccineTypeCard(String vaccineType, List<VaccinationSchedule> schedules) {
    final vaccineInfo = VaccinationProtocol.vaccineTypes.firstWhere(
      (v) => v.name == vaccineType,
      orElse: () => VaccineType(
        name: vaccineType,
        protectsAgainst: 'Unknown',
        recommendedTiming: 'Unknown',
        purpose: 'Unknown',
        applicableStages: [],
        ageInMonths: 0,
      ),
    );

    final pendingOrOverdue = schedules.where((s) => s.isPending || s.isOverdue).toList();
    // final completedCount = schedules.where((s) => s.isCompleted).length; // Unused
    final hasSchedules = schedules.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.vibrantGreen.withOpacity(0.1),
                  AppColors.vibrantGreen.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(
                color: AppColors.vibrantGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccineType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (vaccineInfo.applicableStages.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.vibrantGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.vibrantGreen.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Stage: ${vaccineInfo.applicableStages.first}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.vibrantGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          vaccineInfo.protectsAgainst,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openScheduleForm(vaccineType),
                        icon: const Icon(Icons.schedule, size: 12),
                        label: const Text('Schedule', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.vibrantGreen,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.vibrantGreen, width: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasSchedules 
                              ? (pendingOrOverdue.isNotEmpty 
                                  ? AppColors.vibrantGreen 
                                  : Colors.grey.shade500)
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasSchedules 
                                  ? (pendingOrOverdue.isNotEmpty 
                                      ? Icons.pending_actions 
                                      : Icons.check_circle)
                                  : Icons.info_outline,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasSchedules 
                                  ? '${pendingOrOverdue.length} pending'
                                  : 'No cattle',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cattle Needing Vaccination:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (pendingOrOverdue.isNotEmpty)
                  ...pendingOrOverdue.map((schedule) => _buildCattleVaccinationRow(schedule))
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hasSchedules 
                              ? 'No cattle currently need this vaccine'
                              : 'No cattle in your herd require this vaccine',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCattleVaccinationRow(VaccinationSchedule schedule) {
    final cattle = allCattle.firstWhere(
      (c) => c.tagNo == schedule.cattleTag,
      orElse: () => Cattle(
        id: 0,
        tagNo: schedule.cattleTag,
        sex: '',
        classification: '',
        status: '',
        source: '',
      ),
    );

    final ageInMonths = _getAccurateAgeInMonths(cattle);
    final ageDisplay = _getAgeDisplay(cattle, ageInMonths);
    final classification = _normalizeClassification(cattle.classification);
    final scheduled = _getScheduledFor(cattle.tagNo, schedule.vaccineType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tag: ${cattle.tagNo}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Age: $ageDisplay • $classification',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (scheduled != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.vibrantGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Scheduled • ${_formatScheduleDate(scheduled.scheduleDateTime)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _getAccurateAgeInMonths(Cattle cattle) {
    if (cattle.age != null && cattle.age!.isNotEmpty) {
      try {
        final ageValue = int.tryParse(cattle.age!);
        if (ageValue != null && ageValue >= 0) {
          return ageValue;
        }
      } catch (_) {}
    }
    if (cattle.dateOfBirth != null && cattle.dateOfBirth!.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(cattle.dateOfBirth!);
        final now = DateTime.now();
        final difference = now.difference(birthDate);
        final ageInMonths = (difference.inDays / 30.44).round();
        return ageInMonths > 0 ? ageInMonths : 0;
      } catch (_) {}
    }
    return _getDefaultAgeByClassification(cattle.classification);
  }

  int _getDefaultAgeByClassification(String classification) {
    switch (classification.toLowerCase()) {
      case 'calf':
        return 3;
      case 'grower':
      case 'growers':
        return 8;
      case 'heifer':
      case 'heifers':
        return 15;
      case 'cow':
      case 'cows':
        return 36;
      case 'bull':
      case 'bulls':
        return 36;
      default:
        return 12;
    }
  }

  String _getAgeDisplay(Cattle cattle, int ageInMonths) {
    if (ageInMonths < 12) {
      return '$ageInMonths months';
    } else {
      final years = ageInMonths ~/ 12;
      final months = ageInMonths % 12;
      if (months == 0) {
        return '$years years';
      } else {
        return '$years years, $months months';
      }
    }
  }

  String _normalizeClassification(String classification) {
    final normalized = classification.trim().toLowerCase();
    switch (normalized) {
      case 'calf':
      case 'calves':
        return 'Calf';
      case 'grower':
      case 'growers':
        return 'Growers';
      case 'heifer':
      case 'heifers':
        return 'Heifer';
      case 'cow':
      case 'cows':
        return 'Cow';
      case 'bull':
      case 'bulls':
        return 'Bull';
      default:
        return classification;
    }
  }


  String _formatScheduleDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(date.year, date.month, date.day);
    
    if (scheduleDate == today) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (scheduleDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }


















  Widget _buildProtocolTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ...vaccinesByStage.entries.map((entry) => 
            _buildStageProtocolCard(entry.key, entry.value)
          ),
        ],
      ),
    );
  }

  Widget _buildStageProtocolCard(String stage, List<VaccineType> vaccines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...vaccines.map((vaccine) => _buildVaccineInfo(vaccine)),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineInfo(VaccineType vaccine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.vibrantGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.vibrantGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vaccine.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.shield,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Protects against: ${vaccine.protectsAgainst}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Timing: ${vaccine.recommendedTiming}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vaccine.purpose,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }




}


