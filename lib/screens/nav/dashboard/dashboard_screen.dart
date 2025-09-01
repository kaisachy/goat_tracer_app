import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_event_service.dart';
import '../../dashboard/breeding_success_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<Cattle> allCattle = [];
  List<Map<String, dynamic>> allEvents = [];
  bool isLoading = true;
  String? error;

  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => isLoading = true);

      final cattleData = await CattleService.getAllCattle();
      final eventsData = await CattleEventService.getCattleEvent();

      if (mounted) {
        setState(() {
          allCattle = cattleData;
          allEvents = eventsData;
          isLoading = false;
          error = null;
        });
        _cardAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load dashboard data: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async => await _loadDashboardData();

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.vibrantGreen,
              child: isLoading
                  ? _buildLoadingState()
                  : error != null
                  ? _buildErrorState()
                  : _buildDashboardContent(),
            ),
          ),
        ),
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
            'Loading Dashboard...',
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
              'Dashboard Error',
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
              onPressed: _refreshData,
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

  Widget _buildDashboardContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildOverviewCards(),
              const SizedBox(height: 20),
              _buildBreedingSuccessCard(),
              const SizedBox(height: 20),
              _buildGenderDistribution(),
              const SizedBox(height: 20),
              _buildStatusBreakdown(),
              const SizedBox(height: 20),
              _buildRecentEvents(),
              const SizedBox(height: 20),
              _buildEventsByType(),
              const SizedBox(height: 20),
              _buildBreedDistribution(),
              const SizedBox(height: 20),
              _buildClassificationDistribution(),
              const SizedBox(height: 20),
              _buildHealthStats(),
              const SizedBox(height: 100), // Bottom padding
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    final totalCattle = allCattle.length;
    final activeCattle = allCattle.where((c) => c.status.toLowerCase() == 'active').length;
    final totalEvents = allEvents.length;
    final recentEvents = allEvents.where((e) {
      try {
        final eventDate = DateTime.parse(e['event_date']);
        return eventDate.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      } catch (e) {
        return false;
      }
    }).length;

    return Row(
      children: [
        Expanded(
          child: _buildAnimatedCard(
            delay: 0,
            child: _buildOverviewCard(
              title: 'Total Cattle',
              value: totalCattle.toString(),
              icon: FontAwesomeIcons.cow,
              color: AppColors.vibrantGreen,
              subtitle: '$activeCattle active',
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnimatedCard(
            delay: 100,
            child: _buildOverviewCard(
              title: 'Total Events',
              value: totalEvents.toString(),
              icon: Icons.event_note,
              color: Colors.blue.shade500,
              subtitle: '$recentEvents this month',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDistribution() {
    final males = allCattle.where((c) => c.gender.toLowerCase() == 'male').length;
    final females = allCattle.where((c) => c.gender.toLowerCase() == 'female').length;
    final total = allCattle.length;

    return _buildAnimatedCard(
      delay: 200,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Gender Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (total > 0) ...[
              _buildGenderBar('Male', males, total, Colors.blue.shade400),
              const SizedBox(height: 16),
              _buildGenderBar('Female', females, total, Colors.pink.shade400),
            ] else
              const Text(
                'No cattle data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage / 100,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown() {
    final statusCount = <String, int>{};
    for (var cattle in allCattle) {
      final status = cattle.status.toLowerCase();
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }

    return _buildAnimatedCard(
      delay: 300,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Status Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (statusCount.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: statusCount.entries.map((entry) {
                  final color = _getStatusColor(entry.key);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                          '${entry.key.toUpperCase()}: ${entry.value}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              const Text(
                'No status data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEvents() {
    final recentEvents = allEvents.where((event) {
      try {
        final eventDate = DateTime.parse(event['event_date']);
        return eventDate.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      } catch (e) {
        return false;
      }
    }).take(5).toList();

    return _buildAnimatedCard(
      delay: 400,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Recent Events (7 Days)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (recentEvents.isNotEmpty)
              ...recentEvents.map((event) => _buildEventTile(event))
            else
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent event',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

  Widget _buildEventTile(Map<String, dynamic> event) {
    final eventType = event['event_type'] ?? 'Unknown';
    final cattleTag = event['cattle_tag'] ?? 'N/A';
    final eventDate = event['event_date'];
    final color = _getEventTypeColor(eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getEventTypeIcon(eventType),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'Cattle #$cattleTag',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(eventDate),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsByType() {
    final eventTypeCount = <String, int>{};
    for (var event in allEvents) {
      final eventType = event['event_type']?.toString().toLowerCase() ?? 'unknown';
      eventTypeCount[eventType] = (eventTypeCount[eventType] ?? 0) + 1;
    }

    final sortedEvents = eventTypeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildAnimatedCard(
      delay: 500,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Events by Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (sortedEvents.isNotEmpty)
              ...sortedEvents.take(6).map((entry) {
                final color = _getEventTypeColor(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        _getEventTypeIcon(entry.key),
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              const Text(
                'No event data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedDistribution() {
    final breedCount = <String, int>{};
    for (var cattle in allCattle) {
      final breed = cattle.breed ?? 'Unknown';
      if (breed.isNotEmpty) {
        breedCount[breed] = (breedCount[breed] ?? 0) + 1;
      }
    }

    return _buildAnimatedCard(
      delay: 600,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(FontAwesomeIcons.dna, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Breed Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (breedCount.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: breedCount.entries.map((entry) {
                  final colors = [
                    Colors.blue.shade400,
                    Colors.green.shade400,
                    Colors.purple.shade400,
                    Colors.orange.shade400,
                    Colors.teal.shade400,
                  ];
                  final color = colors[entry.key.hashCode % colors.length];

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              const Text(
                'No breed data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationDistribution() {
    final classificationCount = <String, int>{};
    for (var cattle in allCattle) {
      final classification = cattle.classification.isNotEmpty
          ? cattle.classification
          : 'Unclassified';
      classificationCount[classification] = (classificationCount[classification] ?? 0) + 1;
    }

    final total = allCattle.length;
    final sortedClassifications = classificationCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildAnimatedCard(
      delay: 650,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Classification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (sortedClassifications.isNotEmpty && total > 0)
              Column(
                children: sortedClassifications.map((entry) {
                  final percentage = (entry.value / total * 100);
                  final color = _getClassificationColor(entry.key);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getClassificationIcon(entry.key),
                                    color: color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}% of herd',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: percentage / 100,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.8),
                                    color,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No classification data available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

  Widget _buildHealthStats() {
    final treatmentEvents = allEvents.where((e) =>
    e['event_type']?.toString().toLowerCase() == 'treated').length;
    final vaccinationEvents = allEvents.where((e) =>
    e['event_type']?.toString().toLowerCase() == 'vaccinated').length;
    final dewormingEvents = allEvents.where((e) =>
    e['event_type']?.toString().toLowerCase() == 'deworming').length;

    return _buildAnimatedCard(
      delay: 700,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Health Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildHealthStatCard(
                    title: 'Treatments',
                    count: treatmentEvents,
                    icon: Icons.medical_services,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthStatCard(
                    title: 'Vaccinations',
                    count: vaccinationEvents,
                    icon: Icons.vaccines,
                    color: Colors.green.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthStatCard(
                    title: 'Deworming',
                    count: dewormingEvents,
                    icon: Icons.pest_control,
                    color: Colors.orange.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
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

  Widget _buildAnimatedCard({
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Color _getClassificationColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'calf':
        return Colors.lightBlue.shade400;
      case 'heifer':
        return Colors.pink.shade400;
      case 'bull':
        return Colors.deepOrange.shade500;
      case 'cow':
        return Colors.green.shade500;
      case 'steer':
        return Colors.brown.shade500;
      case 'grower':
        return Colors.purple.shade400;
      default:
        return Colors.indigo.shade400;
    }
  }

  IconData _getClassificationIcon(String classification) {
    switch (classification.toLowerCase()) {
      case 'calf':
        return Icons.child_care;
      case 'heifer':
        return Icons.female;
      case 'bull':
        return Icons.male;
      case 'cow':
        return FontAwesomeIcons.cow;
      case 'steer':
        return Icons.agriculture;
      case 'grower':
        return Icons.trending_up;
      default:
        return Icons.pets;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade500;
      case 'inactive':
        return Colors.grey.shade500;
      case 'sold':
        return Colors.blue.shade500;
      case 'deceased':
        return Colors.red.shade500;
      default:
        return AppColors.lightGreen;
    }
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'breeding':
        return Colors.pink.shade400;
      case 'weighed':
        return Colors.orange.shade500;
      case 'gives birth':
        return Colors.blue.shade400;
      case 'vaccinated':
        return Colors.green.shade500;
      case 'pregnant':
        return Colors.purple.shade400;
      case 'treated':
        return Colors.red.shade400;
      case 'dry off':
        return Colors.grey.shade500;
      case 'deworming':
        return Colors.yellow.shade600;
      case 'hoof trimming':
        return Colors.brown.shade400;
      case 'castrated':
        return Colors.indigo.shade400;
      case 'weaned':
        return Colors.teal.shade400;
      case 'aborted pregnancy':
        return Colors.red.shade600;
      case 'other':
        return Colors.blueGrey.shade400;
      default:
        return AppColors.lightGreen;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'breeding':
        return Icons.favorite_rounded;
      case 'weighed':
        return Icons.monitor_weight_rounded;
      case 'gives birth':
        return Icons.child_care_rounded;
      case 'vaccinated':
        return Icons.vaccines_rounded;
      case 'pregnant':
        return Icons.pregnant_woman_rounded;
      case 'treated':
        return Icons.medical_services_rounded;
      case 'dry off':
        return Icons.pause_circle_rounded;
      case 'deworming':
        return Icons.pest_control_rounded;
      case 'hoof trimming':
        return Icons.content_cut_rounded;
      case 'castrated':
        return Icons.minor_crash_rounded;
      case 'weaned':
        return Icons.rss_feed_rounded;
      case 'aborted pregnancy':
        return Icons.heart_broken_rounded;
      case 'other':
        return Icons.more_horiz_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) return 'Today';
      if (difference == 1) return 'Yesterday';
      if (difference < 7) return '${difference}d ago';

      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildBreedingSuccessCard() {
    return _buildAnimatedCard(
      delay: 150,
      child: const BreedingSuccessCard(),
    );
  }
}