import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_event_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/vaccination_dashboard_widget.dart';
import 'widgets/breeding_analytics_widget.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_detail_screen.dart';

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

  // Weight analysis state
  String? _selectedWeightCattleTag; // Selected cattle for weight analysis
  String _weightTagSearch = '';

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
          // Initialize default selected cattle for weight analysis if not set
          if (_selectedWeightCattleTag == null) {
            final tagsWithWeighed = allEvents
                .where((e) => (e['event_type']?.toString().toLowerCase() ?? '') == 'weighed')
                .map((e) => e['cattle_tag']?.toString() ?? '')
                .where((t) => t.isNotEmpty)
                .toSet()
                .toList();
            if (tagsWithWeighed.isNotEmpty) {
              _selectedWeightCattleTag = tagsWithWeighed.first;
            }
          }
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
    // Check if there's any data to display
    if (allCattle.isEmpty && allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.vibrantGreen.withOpacity(0.3)),
                ),
                child: Icon(
                  FontAwesomeIcons.cow,
                  size: 64,
                  color: AppColors.vibrantGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Data Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start by adding cattle to your herd to see analytics and insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildOverviewCards(),
              const SizedBox(height: 20),
              _buildClassificationDistribution(),
              const SizedBox(height: 20),
              _buildCalfGrowerSexCharts(),
              const SizedBox(height: 20),
              _buildStatusBreakdown(),
              const SizedBox(height: 20),
              _buildBreedingAnalytics(),
              const SizedBox(height: 20),
              _buildVaccinationDashboard(),
              const SizedBox(height: 20),
              _buildWeightAnalysis(),
              const SizedBox(height: 20),
              _buildExpectedDeliveries(),
              const SizedBox(height: 20),
              _buildRecentEvents(),
              const SizedBox(height: 20),
              _buildBreedDistribution(),
              const SizedBox(height: 20),
              _buildKeepAnEyeOn(),
              const SizedBox(height: 100), // Bottom padding
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightAnalysis() {
    // Available tags from all cattle (not only those with weighed events)
    final allTags = allCattle
        .map((c) => c.tagNo)
        .where((t) => t.isNotEmpty)
        .toSet() // ensure unique to avoid duplicate value assertion
        .toList()
      ..sort();
    // Filter tags by search query (case-insensitive contains)
    final availableTags = (_weightTagSearch.isEmpty
        ? allTags
        : allTags.where((t) => t.toLowerCase().contains(_weightTagSearch.toLowerCase())).toList())
      ..sort();

    // Resolve selected tag safely against the current list
    final String? selectedTag = (availableTags.contains(_selectedWeightCattleTag))
        ? _selectedWeightCattleTag
        : (availableTags.isNotEmpty ? availableTags.first : null);

    // Ensure a selection exists if possible
    // (Do not call setState here; use selectedTag locally and update on user change)

    // Filter weighed events by selected cattle tag
    final weighedEvents = allEvents.where((e) =>
      (e['event_type']?.toString().toLowerCase() ?? '') == 'weighed' &&
      (e['weighed_result'] != null && e['weighed_result'].toString().isNotEmpty) &&
      (e['event_date'] != null && e['event_date'].toString().isNotEmpty) &&
      (selectedTag != null && e['cattle_tag']?.toString() == selectedTag)
    ).toList()
      ..sort((a, b) {
        final ad = DateTime.tryParse(a['event_date']?.toString() ?? '') ?? DateTime(1900);
        final bd = DateTime.tryParse(b['event_date']?.toString() ?? '') ?? DateTime(1900);
        return ad.compareTo(bd);
      });

    return _buildAnimatedCard(
      delay: 225,
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
                const Icon(Icons.monitor_weight_rounded, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Weight Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Search by tag no
                _buildWeightTagSearchField(),
                const SizedBox(width: 8),
                if (availableTags.isNotEmpty) _buildWeightCattleSelector(availableTags, selectedTag),
              ],
            ),
            const SizedBox(height: 20),
            if (weighedEvents.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.insights_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      availableTags.isEmpty
                          ? 'No weighed events recorded'
                          : 'No weighed events for #${selectedTag}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 250,
                child: LineChart(
                  (() {
                    final spots = _buildWeightSpots(weighedEvents);
                    final double minX = 0;
                    final double maxX = spots.isEmpty ? 0 : (spots.length - 1).toDouble();
                    return LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                            getTitlesWidget: (val, meta) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(val.toStringAsFixed(0),
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true,
                            interval: 1,
                            getTitlesWidget: (val, meta) {
                              // Only display for whole-number indices within range
                              if (val % 1 != 0) return const SizedBox.shrink();
                              final idx = val.toInt();
                              final label = _weightChartLabels[idx] ?? '';
                              if (label.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(1)} kg',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          )).toList(),
                        ),
                      ),
                      minX: minX,
                      maxX: maxX,
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.darkGreen,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.darkGreen.withOpacity(0.12),
                          ),
                          spots: spots,
                        ),
                      ],
                    );
                  })(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeepAnEyeOn() {
    // Identify cattle that need attention
    final List<Cattle> sickCattle = allCattle.where((c) => c.status.toLowerCase() == 'sick').toList();
    final List<Cattle> lostCattle = allCattle.where((c) => c.status.toLowerCase() == 'lost').toList();

    final bool hasItems = sickCattle.isNotEmpty || lostCattle.isNotEmpty;

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
              children: const [
                Icon(Icons.visibility_rounded, color: AppColors.darkGreen, size: 24),
                SizedBox(width: 12),
                Text(
                  'Keep an Eye On',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!hasItems)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 48,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No issues found. All good!',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (sickCattle.isNotEmpty) _buildAttentionSection(
                label: 'Sick',
                color: Colors.red.shade500,
                icon: Icons.sick_rounded,
                cattle: sickCattle,
              ),
              if (lostCattle.isNotEmpty) _buildAttentionSection(
                label: 'Lost',
                color: Colors.amber.shade700,
                icon: Icons.search_rounded,
                cattle: lostCattle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionSection({
    required String label,
    required Color color,
    required IconData icon,
    required List<Cattle> cattle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$label (${cattle.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cattle
                .take(12)
                .map((c) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CattleDetailScreen(cattle: c),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.35)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sell_rounded, size: 14, color: color),
                            const SizedBox(width: 6),
                            Text(
                              c.tagNo,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
          if (cattle.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${cattle.length - 12} more',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeightCattleSelector(List<String> availableTags, String? selectedTag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTag,
          isDense: true,
          iconSize: 18,
          items: availableTags
              .map((tag) => DropdownMenuItem(
                    value: tag,
                    child: Text('#$tag', style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedWeightCattleTag = v),
        ),
      ),
    );
  }

  Widget _buildWeightTagSearchField() {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tag...',
                isDense: true,
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) => setState(() => _weightTagSearch = val.trim()),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the data points for the weight chart based on selected period
  final Map<int, String> _weightChartLabels = {};

  List<FlSpot> _buildWeightSpots(List<Map<String, dynamic>> weighedEvents) {
    _weightChartLabels.clear();
    int idx = 0;
    String? lastDateLabel;
    return weighedEvents.map((e) {
      final ds = DateTime.tryParse(e['event_date']?.toString() ?? '');
      final w = double.tryParse(e['weighed_result']?.toString() ?? '');
      final y = (w ?? 0).toDouble();
      final x = (idx).toDouble();
      String label = ds != null ? _formatEventDateLabel(ds) : '';
      // Avoid duplicate labels for multiple events on the same day
      if (lastDateLabel != null && label == lastDateLabel) {
        label = '';
      } else {
        lastDateLabel = label;
      }
      _weightChartLabels[idx] = label;
      idx += 1;
      return FlSpot(x, y);
    }).toList();
  }


  String _formatEventDateLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
  }

  Widget _buildExpectedDeliveries() {
    // Extract pregnant events with expected delivery date
    final List<Map<String, dynamic>> deliveries = allEvents
        .where((e) =>
            (e['event_type']?.toString().toLowerCase() ?? '') == 'pregnant' &&
            (e['expected_delivery_date'] != null &&
                e['expected_delivery_date'].toString().isNotEmpty))
        .map((e) => {
              'cattle_tag': e['cattle_tag'],
              'expected_delivery_date': e['expected_delivery_date'],
            })
        .toList();

    // Sort by expected delivery date (earliest first)
    deliveries.sort((a, b) {
      try {
        final ad = DateTime.parse(a['expected_delivery_date']);
        final bd = DateTime.parse(b['expected_delivery_date']);
        return ad.compareTo(bd);
      } catch (_) {
        return 0;
      }
    });

    return _buildAnimatedCard(
      delay: 175,
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
              children: const [
                Icon(Icons.calendar_month, color: AppColors.darkGreen, size: 24),
                SizedBox(width: 12),
                Text(
                  'Expected Deliveries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (deliveries.isNotEmpty)
              ...deliveries.map((d) => _buildExpectedDeliveryRow(d)).toList()
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
                      'No expected deliveries',
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

  Widget _buildExpectedDeliveryRow(Map<String, dynamic> delivery) {
    final tag = delivery['cattle_tag']?.toString() ?? 'N/A';
    final dateStr = delivery['expected_delivery_date']?.toString();

    DateTime? date;
    int? daysLeft;
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
        daysLeft = date.difference(DateTime.now()).inDays;
      } catch (_) {}
    }

    final Color chipColor;
    if (daysLeft == null) {
      chipColor = Colors.grey.shade500;
    } else if (daysLeft < 0) {
      chipColor = Colors.red.shade500; // overdue
    } else if (daysLeft <= 14) {
      chipColor = Colors.orange.shade600; // soon
    } else {
      chipColor = AppColors.vibrantGreen; // later
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.pregnant_woman, color: chipColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$tag',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  date != null ? _formatFullDate(date) : 'N/A',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (daysLeft != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                daysLeft < 0
                    ? '${daysLeft.abs()}d overdue'
                    : '${daysLeft}d left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: chipColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildOverviewCards() {
    final totalCattle = allCattle.length;
    final activeCattle = allCattle.where((c) => 
      c.status.toLowerCase() != 'sold' && c.status.toLowerCase() != 'deceased').length;

    return _buildAnimatedCard(
      delay: 0,
      child: _buildOverviewCard(
        title: 'Total Cattle',
        value: totalCattle.toString(),
        icon: FontAwesomeIcons.cow,
        color: AppColors.vibrantGreen,
        subtitle: '$activeCattle active',
      ),
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
      height: 180, // Fixed height to match pie chart container
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
          // Header with icon and title
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          // Main value display
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          // Subtitle centered
          Center(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildStatusBreakdown() {
    // Define all 8 status types
    final allStatuses = ['Healthy', 'Sick', 'Breeding', 'Pregnant', 'Lactating', 'Lactating & Pregnant', 'Sold', 'Deceased', 'Lost'];
    
    final statusCount = <String, int>{};
    
    // Initialize all statuses with 0
    for (var status in allStatuses) {
      statusCount[status] = 0;
    }
    
    // Count actual cattle statuses
    for (var cattle in allCattle) {
      final status = cattle.status.isNotEmpty ? cattle.status : 'Unknown';
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
                             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 2,
                 crossAxisSpacing: 12,
                 mainAxisSpacing: 12,
                 childAspectRatio: 1.5,
               ),
              itemCount: statusCount.length,
              itemBuilder: (context, index) {
                final entry = statusCount.entries.toList()[index];
                                 final color = _getStatusColor(entry.key);
                 return Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   decoration: BoxDecoration(
                     color: color.withOpacity(0.05),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: color.withOpacity(0.2)),
                   ),
                                     child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       // Label at top
                       Row(
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
                           Expanded(
                             child: Text(
                               entry.key,
                               style: const TextStyle(
                                 fontSize: 14,
                                 fontWeight: FontWeight.w600,
                                 color: AppColors.textPrimary,
                               ),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 6),
                       // Value centered
                       Center(
                         child: Text(
                           '${entry.value}',
                           style: TextStyle(
                             fontSize: 24,
                             fontWeight: FontWeight.bold,
                             color: color,
                           ),
                         ),
                       ),
                     ],
                   ),
                );
              },
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
    // Restore per-event color usage but remove main card background color
    final color = _getEventTypeColor(eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
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
                  '$cattleTag',
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

  Widget _buildCalfGrowerSexCharts() {
    return Row(
      children: [
        Expanded(
          child: _buildAnimatedCard(
            delay: 100,
            child: _buildCalfChart(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnimatedCard(
            delay: 200,
            child: _buildGrowerChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationDistribution() {
    // Define all 6 classifications
    final allClassifications = ['Calf', 'Grower', 'Heifer', 'Steer', 'Cow', 'Bull'];
    
    final classificationCount = <String, int>{};
    
    // Initialize all classifications with 0
    for (var classification in allClassifications) {
      classificationCount[classification] = 0;
    }
    
    // Count actual cattle classifications
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
            if (sortedClassifications.isNotEmpty)
              Column(
                children: sortedClassifications.map((entry) {
                  final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
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
                            widthFactor: (percentage / 100).clamp(0.0, 1.0),
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
    return AppColors.lightGreen;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green.shade500;
      case 'sick':
        return Colors.red.shade500;
      case 'breeding':
        return Colors.pink.shade500;
      case 'lactating':
        return Colors.blue.shade500;
      case 'pregnant':
        return Colors.purple.shade500;
      case 'lactating & pregnant':
        return Colors.indigo.shade500;
      case 'sold':
        return Colors.orange.shade500;
      case 'deceased':
        return Colors.grey.shade600;
      default:
        return AppColors.lightGreen;
    }
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'sick':
        return Colors.red.shade600;
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
      case 'lost':
        return Colors.amber.shade600;
      case 'other':
        return Colors.blueGrey.shade400;
      default:
        return AppColors.lightGreen;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'sick':
        return Icons.sick_rounded;
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
      case 'lost':
        return Icons.search_rounded;
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

  Widget _buildBreedingAnalytics() {
    return _buildAnimatedCard(
      delay: 150,
      child: const BreedingAnalyticsWidget(),
    );
  }

  Widget _buildVaccinationDashboard() {
    return _buildAnimatedCard(
      delay: 200,
      child: VaccinationDashboardWidget(
        allCattle: allCattle,
        allEvents: allEvents,
      ),
    );
  }

  Widget _buildCalfChart() {
    final calfMales = allCattle.where((c) => 
      c.classification.toLowerCase() == 'calf' && c.sex.toLowerCase() == 'male').length;
    final calfFemales = allCattle.where((c) => 
      c.classification.toLowerCase() == 'calf' && c.sex.toLowerCase() == 'female').length;
    final totalCalves = calfMales + calfFemales;

    if (totalCalves == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calf Sex',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80, // Same height as pie chart
              child: Center(
                child: Text(
                  'No calves',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Empty legend space to maintain same height
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('M', 0, AppColors.darkGreen),
                _buildLegendItem('F', 0, AppColors.gold),
              ],
            ),
          ],
        ),
      );
    }

    final malePercentage = ((calfMales / totalCalves) * 100).toStringAsFixed(0);
    final femalePercentage = ((calfFemales / totalCalves) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calf Sex',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: AppColors.darkGreen,
                    value: calfMales.toDouble(),
                    title: '${malePercentage}%',
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: AppColors.gold,
                    value: calfFemales.toDouble(),
                    title: '${femalePercentage}%',
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 12,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('M', calfMales, AppColors.darkGreen),
              _buildLegendItem('F', calfFemales, AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowerChart() {
    final growerMales = allCattle.where((c) => 
      c.classification.toLowerCase() == 'grower' && c.sex.toLowerCase() == 'male').length;
    final growerFemales = allCattle.where((c) => 
      c.classification.toLowerCase() == 'grower' && c.sex.toLowerCase() == 'female').length;
    final totalGrowers = growerMales + growerFemales;

    if (totalGrowers == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grower Sex',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80, // Same height as pie chart
              child: Center(
                child: Text(
                  'No growers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Empty legend space to maintain same height
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('M', 0, AppColors.darkGreen),
                _buildLegendItem('F', 0, AppColors.gold),
              ],
            ),
          ],
        ),
      );
    }

    final malePercentage = ((growerMales / totalGrowers) * 100).toStringAsFixed(0);
    final femalePercentage = ((growerFemales / totalGrowers) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grower Sex',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: AppColors.darkGreen,
                    value: growerMales.toDouble(),
                    title: '${malePercentage}%',
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: AppColors.gold,
                    value: growerFemales.toDouble(),
                    title: '${femalePercentage}%',
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 12,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('M', growerMales, AppColors.darkGreen),
              _buildLegendItem('F', growerFemales, AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}