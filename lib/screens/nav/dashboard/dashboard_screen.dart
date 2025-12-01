import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/services/goat/goat_history_service.dart';
import 'package:goat_tracer_app/services/user_guide_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:showcaseview/showcaseview.dart';
import 'widgets/breeding_analytics_widget.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

/// Public state class to allow access from outside
class DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<Goat> allGoats = [];
  List<Map<String, dynamic>> allEvents = [];
  bool isLoading = true;
  String? error;

  // Weight analysis state
  String? _selectedWeightgoatTag; // Selected goat for weight analysis
  String _weightTagSearch = '';

  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User guide keys
  final GlobalKey _overviewCardKey = GlobalKey();
  final GlobalKey _classificationKey = GlobalKey();
  final GlobalKey _statusBreakdownKey = GlobalKey();
  final GlobalKey _breedingAnalyticsKey = GlobalKey();
  final GlobalKey _weightAnalysisKey = GlobalKey();
  final GlobalKey _expectedDeliveriesKey = GlobalKey();
  final GlobalKey _recentEventsKey = GlobalKey();
  final GlobalKey _breedDistributionKey = GlobalKey();
  final GlobalKey _keepAnEyeOnKey = GlobalKey();
  
  // Store the ShowCaseWidget context
  BuildContext? _showCaseContext;
  
  // ScrollController for auto-scrolling
  final ScrollController _scrollController = ScrollController();
  
  // Timer for auto-advancing showcase
  Timer? _autoAdvanceTimer;

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

      final goatData = await GoatService.getAllGoats();
      final eventsData = await GoatHistoryService.getgoatHistory();

      if (mounted) {
        setState(() {
          allGoats = goatData;
          allEvents = eventsData;
          isLoading = false;
          error = null;
          // Initialize default selected goat for weight analysis if not set
          if (_selectedWeightgoatTag == null) {
            final tagsWithWeighed = allEvents
                .where((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'weighed')
                .map((e) => e['goat_tag']?.toString() ?? '')
                .where((t) => t.isNotEmpty)
                .toSet()
                .toList();
            if (tagsWithWeighed.isNotEmpty) {
              _selectedWeightgoatTag = tagsWithWeighed.first;
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
    _autoAdvanceTimer?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }
  
  /// Helper method to scroll to a showcase widget
  Future<void> _scrollToShowcase(GlobalKey key) async {
    final context = key.currentContext;
    if (context != null && _scrollController.hasClients) {
      try {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.2, // Show widget at 20% from top to leave room for tooltip
        );
      } catch (e) {
        debugPrint('Error scrolling to showcase: $e');
      }
    }
  }

  /// Public method to start the user guide (called from home screen)
  void startUserGuide() async {
    if (_showCaseContext == null) {
      debugPrint('ShowCase context not available yet');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait a moment and try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Reset the guide completion status
    await UserGuideService.resetGuide('dashboard');
    debugPrint('User guide reset, starting showcase...');
    
    if (mounted && _showCaseContext != null) {
      try {
        // Wait for widgets to be fully rendered
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Start the showcase - it will auto-scroll to each item
        ShowCaseWidget.of(_showCaseContext!).startShowCase([
          _overviewCardKey,
          _classificationKey,
          _statusBreakdownKey,
          _breedingAnalyticsKey,
          _weightAnalysisKey,
          _expectedDeliveriesKey,
          _recentEventsKey,
          _breedDistributionKey,
          _keepAnEyeOnKey,
        ]);
      } catch (e) {
        debugPrint('Error starting user guide: $e');
        // Show a snackbar if guide fails to start
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to start user guide. Please try again.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 300),
      onFinish: () async {
        debugPrint('User guide finished, marking as completed...');
        await UserGuideService.markGuideCompleted('dashboard');
        debugPrint('User guide marked as completed');
      },
      onStart: (index, key) {
        // Cancel any existing auto-advance timer
        _autoAdvanceTimer?.cancel();
        
        // Ensure the widget is scrolled into view
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToShowcase(key);
        });
        
        // Auto-advance after Breeding Analytics
        if (key == _breedingAnalyticsKey) {
          debugPrint('Breeding Analytics showcase started, setting up auto-advance...');
          _autoAdvanceTimer = Timer(const Duration(seconds: 3), () {
            debugPrint('Auto-advance timer fired for Breeding Analytics');
            if (mounted && _showCaseContext != null) {
              try {
                // Get the list of all showcase keys in order
                final allKeys = [
                  _overviewCardKey,
                  _classificationKey,
                  _statusBreakdownKey,
                  _breedingAnalyticsKey,
                  _weightAnalysisKey,
                  _expectedDeliveriesKey,
                  _recentEventsKey,
                  _breedDistributionKey,
                  _keepAnEyeOnKey,
                ];
                
                // Find the index of breeding analytics
                final breedingIndex = allKeys.indexOf(_breedingAnalyticsKey);
                debugPrint('Breeding Analytics is at index: $breedingIndex');
                
                if (breedingIndex >= 0 && breedingIndex < allKeys.length - 1) {
                  // Get remaining keys after breeding analytics
                  final remainingKeys = allKeys.sublist(breedingIndex + 1);
                  debugPrint('Will continue with ${remainingKeys.length} remaining showcases');
                  
                  // Wait for next frame to ensure UI is stable
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted && _showCaseContext != null) {
                        try {
                          debugPrint('Dismissing current showcase...');
                          // Dismiss the current showcase
                          ShowCaseWidget.of(_showCaseContext!).dismiss();
                          
                          // Wait longer for dismiss animation to complete
                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (mounted && _showCaseContext != null) {
                              try {
                                debugPrint('Starting next showcase sequence with ${remainingKeys.length} items');
                                ShowCaseWidget.of(_showCaseContext!).startShowCase(remainingKeys);
                              } catch (e) {
                                debugPrint('Error starting next showcase: $e');
                              }
                            } else {
                              debugPrint('Widget not mounted or context lost after delay');
                            }
                          });
                        } catch (e) {
                          debugPrint('Error dismissing showcase: $e');
                        }
                      } else {
                        debugPrint('Widget not mounted or context is null');
                      }
                    });
                  });
                } else {
                  debugPrint('Breeding Analytics is last item or not found in list');
                }
              } catch (e) {
                debugPrint('Error in auto-advance logic: $e');
              }
            } else {
              debugPrint('Cannot auto-advance: mounted=$mounted, hasContext=${_showCaseContext != null}');
            }
          });
        }
      },
      builder: (showCaseContext) {
        // Store the ShowCaseWidget context
        _showCaseContext = showCaseContext;
        
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
      },
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
    if (allGoats.isEmpty && allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.vibrantGreen.withValues(alpha: 0.3)),
                ),
                child: Image.asset(
                  'assets/images/goat-icons/goat.png',
                  width: 64,
                  height: 64,
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
                'Start by adding goat to your herd to see analytics and insights.',
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
      controller: _scrollController,
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
              _buildStatusBreakdown(),
              const SizedBox(height: 20),
              _buildBreedingAnalytics(),
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
    // Available tags from all goat (not only those with weighed history)
    final allTags = allGoats
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
    final String? selectedTag = (availableTags.contains(_selectedWeightgoatTag))
        ? _selectedWeightgoatTag
        : (availableTags.isNotEmpty ? availableTags.first : null);

    // Ensure a selection exists if possible
    // (Do not call setState here; use selectedTag locally and update on user change)

    // Filter weighed history by selected Goat Tag
    final weighedEvents = allEvents.where((e) =>
      (e['history_type']?.toString().toLowerCase() ?? '') == 'weighed' &&
      (e['weighed_result'] != null && e['weighed_result'].toString().isNotEmpty) &&
      (e['history_date'] != null && e['history_date'].toString().isNotEmpty) &&
      (selectedTag != null && e['goat_tag']?.toString() == selectedTag)
    ).toList()
      ..sort((a, b) {
        final ad = DateTime.tryParse(a['history_date']?.toString() ?? '') ?? DateTime(1900);
        final bd = DateTime.tryParse(b['history_date']?.toString() ?? '') ?? DateTime(1900);
        return ad.compareTo(bd);
      });

    return Showcase(
      key: _weightAnalysisKey,
      title: 'Weight Analysis',
      description: 'Track weight changes over time for individual goats. Use the search and dropdown to select a specific goat tag, then view its weight progression in the chart below.',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      child: _buildAnimatedCard(
        delay: 225,
        child: Container(
        padding: const EdgeInsets.all(24),
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
                if (availableTags.isNotEmpty) _buildWeightgoatSelector(availableTags, selectedTag),
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
                          ? 'No weighed history recorded'
                          : 'No weighed history for #$selectedTag',
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
                            color: AppColors.darkGreen.withValues(alpha: 0.12),
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
      ),
    );
  }

  Widget _buildKeepAnEyeOn() {
    // Identify goat that need attention
    final List<Goat> sickGoat = allGoats.where((c) => c.status.toLowerCase() == 'sick').toList();
    final List<Goat> lostGoat = allGoats.where((c) => c.status.toLowerCase() == 'lost').toList();

    final bool hasItems = sickGoat.isNotEmpty || lostGoat.isNotEmpty;

    return Showcase(
      key: _keepAnEyeOnKey,
      title: 'Keep an Eye On',
      description: 'Monitor goats that need immediate attention. This section highlights sick and lost goats, helping you quickly identify and address health issues or missing animals in your herd.',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipPosition: TooltipPosition.top,
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      descTextStyle: const TextStyle(
        fontSize: 13,
        color: Colors.white,
        height: 1.3,
      ),
      overlayOpacity: 0.4,
      disableBarrierInteraction: false,
      child: _buildAnimatedCard(
        delay: 700,
        child: Container(
        padding: const EdgeInsets.all(24),
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
              if (sickGoat.isNotEmpty) _buildAttentionSection(
                label: 'Sick',
                color: Colors.red.shade500,
                icon: Icons.sick_rounded,
                goat: sickGoat,
              ),
              if (lostGoat.isNotEmpty) _buildAttentionSection(
                label: 'Lost',
                color: Colors.amber.shade700,
                icon: Icons.search_rounded,
                goat: lostGoat,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAttentionSection({
    required String label,
    required Color color,
    required IconData icon,
    required List<Goat> goat,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$label (${goat.length})',
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
            children: goat
                .take(12)
                .map((c) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoatDetailScreen(goat: c),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.35)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
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
          if (goat.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${goat.length - 12} more',
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeightgoatSelector(List<String> availableTags, String? selectedTag) {
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
          onChanged: (v) => setState(() => _selectedWeightgoatTag = v),
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
      final ds = DateTime.tryParse(e['history_date']?.toString() ?? '');
      final w = double.tryParse(e['weighed_result']?.toString() ?? '');
      final y = (w ?? 0).toDouble();
      final x = (idx).toDouble();
      String label = ds != null ? _formatEventDateLabel(ds) : '';
      // Avoid duplicate labels for multiple history on the same day
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
    // Extract pregnant history with expected delivery date
    final List<Map<String, dynamic>> deliveries = allEvents
        .where((e) =>
            (e['history_type']?.toString().toLowerCase() ?? '') == 'pregnant' &&
            (e['expected_delivery_date'] != null &&
                e['expected_delivery_date'].toString().isNotEmpty))
        .map((e) => {
              'goat_tag': e['goat_tag'],
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

    return Showcase(
      key: _expectedDeliveriesKey,
      title: 'Expected Deliveries',
      description: 'Stay on top of upcoming kidding dates. This section lists all pregnant goats with their expected delivery dates, color-coded by urgency (red for overdue, orange for soon, green for later).',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      child: _buildAnimatedCard(
        delay: 175,
        child: Container(
        padding: const EdgeInsets.all(24),
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
              ...deliveries.map((d) => _buildExpectedDeliveryRow(d))
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
      ),
    );
  }

  Widget _buildExpectedDeliveryRow(Map<String, dynamic> delivery) {
    final tag = delivery['goat_tag']?.toString() ?? 'N/A';
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
        color: chipColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.12),
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
                color: chipColor.withValues(alpha: 0.12),
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
    final totalgoat = allGoats.length;
    final activegoat = allGoats.where((c) => 
      c.status.toLowerCase() != 'sold' && c.status.toLowerCase() != 'mortality').length;

    return Showcase(
      key: _overviewCardKey,
      title: 'Total Goat Overview',
      description: 'This card shows the total number of goats in your herd and how many are currently active. Active goats exclude those that are sold or have passed away.',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      child: _buildAnimatedCard(
        delay: 0,
        child: _buildOverviewCard(
          title: 'TOTAL GOAT',
          value: totalgoat.toString(),
          icon: FontAwesomeIcons.cow,
          color: AppColors.vibrantGreen,
          subtitle: '$activegoat active',
        ),
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
    // Check if icon is cow icon, use goat image instead
    final bool useGoatIcon = icon == FontAwesomeIcons.cow;
    
    return Container(
      height: 180, // Fixed height to match pie chart container
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: useGoatIcon
                    ? Image.asset(
                        'assets/images/goat-icons/goat.png',
                        width: 24,
                        height: 24,
                        color: color,
                      )
                    : Icon(icon, color: color, size: 24),
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
                color: AppColors.textSecondary.withValues(alpha: 0.8),
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
    final allStatuses = ['Healthy', 'Sick', 'Breeding', 'Pregnant', 'Lactating', 'Lactating & Pregnant', 'Sold', 'Mortality', 'Lost', 'Slaughtered'];
    
    final statusCount = <String, int>{};
    
    // Initialize all statuses with 0
    for (var status in allStatuses) {
      statusCount[status] = 0;
    }
    
    // Count actual goat statuses
    for (var goat in allGoats) {
      final status = goat.status.isNotEmpty ? goat.status : 'Unknown';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }

    return Showcase(
      key: _statusBreakdownKey,
      title: 'Status Breakdown',
      description: 'Monitor the health and reproductive status of your goats. This grid shows counts for each status type including Healthy, Sick, Breeding, Pregnant, Lactating, and more.',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      child: _buildAnimatedCard(
        delay: 300,
        child: Container(
        padding: const EdgeInsets.all(24),
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
                     color: color.withValues(alpha: 0.05),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: color.withValues(alpha: 0.2)),
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
      ),
    );
  }

  Widget _buildRecentEvents() {
    final recentEvents = allEvents.where((event) {
      try {
        final eventDate = DateTime.parse(event['history_date']);
        return eventDate.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      } catch (e) {
        return false;
      }
    }).take(5).toList();

    return Showcase(
      key: _recentEventsKey,
      title: 'Recent History Recorded',
      description: 'Quickly view the most recent activities recorded in your herd. This shows the last 5 events from the past 7 days, including vaccinations, treatments, breeding, and other important events.',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      child: _buildAnimatedCard(
        delay: 400,
        child: Container(
        padding: const EdgeInsets.all(24),
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
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.darkGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Recent History Recorded',
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
      ),
    );
  }

  Widget _buildEventTile(Map<String, dynamic> event) {
    final eventType = event['history_type'] ?? 'Unknown';
    final goatTag = event['goat_tag'] ?? 'N/A';
    final eventDate = event['history_date'];
    // Restore per-event color usage but remove main card background color
    final color = _getEventTypeColor(eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                  '$goatTag',
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
    for (var goat in allGoats) {
      final breed = goat.breed ?? 'Unknown';
      if (breed.isNotEmpty) {
        breedCount[breed] = (breedCount[breed] ?? 0) + 1;
      }
    }

    return Showcase(
      key: _breedDistributionKey,
      title: 'Breed Distribution',
      description: 'View the distribution of different breeds in your herd. This section shows the count of each breed type, helping you understand the genetic diversity of your goats.',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      child: _buildAnimatedCard(
        delay: 600,
        child: Container(
        padding: const EdgeInsets.all(24),
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
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
      ),
    );
  }

  Widget _buildClassificationDistribution() {
    // Define all 6 classifications
    final allClassifications = ['Buck', 'Doe', 'Buckling', 'Doeling', 'Grower', 'Kid'];
    
    final classificationCount = <String, int>{};
    
    // Initialize all classifications with 0
    for (var classification in allClassifications) {
      classificationCount[classification] = 0;
    }
    
    String normalizeClassification(String raw) {
      final lower = raw.toLowerCase();
      if (lower == 'kid') return 'Kid';
      if (lower == 'grower' || lower == 'growers') return 'Grower';
      if (lower == 'doeling') return 'Doeling';
      if (lower == 'buckling') return 'Buckling';
      if (lower == 'doe') return 'Doe';
      if (lower == 'buck') return 'Buck';
      return raw.isNotEmpty ? raw : 'Unclassified';
    }

    // Count actual goat classifications and track sex breakdown for Kid & Grower
    final Map<String, Map<String, int>> sexByClassification = {};
    for (var goat in allGoats) {
      final rawClass = goat.classification.isNotEmpty
          ? goat.classification
          : 'Unclassified';
      final classification = normalizeClassification(rawClass);

      classificationCount[classification] =
          (classificationCount[classification] ?? 0) + 1;

      final sexKey = goat.sex.toLowerCase() == 'female' ? 'female' : 'male';
      sexByClassification.putIfAbsent(classification, () => {'male': 0, 'female': 0});
      sexByClassification[classification]![sexKey] =
          (sexByClassification[classification]![sexKey] ?? 0) + 1;
    }

    final total = allGoats.length;
    final orderMap = {
      'Buck': 0,
      'Doe': 1,
      'Buckling': 2,
      'Doeling': 3,
      'Male Grower': 4,
      'Female Grower': 5,
      'Male Kid': 6,
      'Female Kid': 7,
      'Grower': 8,
      'Kid': 9,
    };

    final sortedClassifications = classificationCount.entries.toList()
      ..sort((a, b) {
        final ai = orderMap[a.key] ?? 999;
        final bi = orderMap[b.key] ?? 999;
        return ai.compareTo(bi);
      });

    // Build display entries so Kid/Grower become separate Male/Female bars (non-zero only)
    final List<MapEntry<String, int>> displayClassifications = [];
    for (final entry in sortedClassifications) {
      final keyLower = entry.key.toLowerCase();
      final sex = sexByClassification[entry.key] ??
          sexByClassification[entry.key.toLowerCase()] ??
          {'male': 0, 'female': 0};

      if (keyLower == 'kid' || keyLower == 'grower') {
        final maleCount = sex['male'] ?? 0;
        final femaleCount = sex['female'] ?? 0;
        if (maleCount > 0) {
          displayClassifications.add(MapEntry('Male ${entry.key}', maleCount));
        }
        if (femaleCount > 0) {
          displayClassifications.add(MapEntry('Female ${entry.key}', femaleCount));
        }
      } else {
        displayClassifications.add(entry);
      }
    }

    return Showcase(
      key: _classificationKey,
      title: 'Classification Distribution',
      description: 'View how your goats are distributed across different classifications (Kid, Grower, Doeling, Buckling, Doe, Buck). Each bar shows the count and percentage of your total herd.',
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tooltipBackgroundColor: AppColors.darkGreen,
      textColor: Colors.white,
      child: _buildAnimatedCard(
        delay: 650,
        child: Container(
        padding: const EdgeInsets.all(24),
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
            if (displayClassifications.isNotEmpty)
              Column(
                children: displayClassifications.map((entry) {
                  final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

                  // For "Male Kid" / "Female Kid" etc, derive base classification for color
                  String baseKey = entry.key;
                  final lower = baseKey.toLowerCase();
                  if (lower.startsWith('male ')) {
                    baseKey = baseKey.substring(5);
                  } else if (lower.startsWith('female ')) {
                    baseKey = baseKey.substring(7);
                  }

                  final color = _getClassificationColor(baseKey);
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
                                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withValues(alpha: 0.3)),
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
                                    color.withValues(alpha: 0.8),
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
      case 'mortality':
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
      case 'kidding':
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
      case 'aborted':
        return Colors.red.shade600;
      case 'lost':
        return Colors.amber.shade600;
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
      case 'kidding':
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
      case 'aborted':
        return Icons.heart_broken_rounded;
      case 'lost':
        return Icons.search_rounded;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small header widget to showcase instead of the entire large widget
        Showcase(
          key: _breedingAnalyticsKey,
          title: 'Breeding Analytics',
          description: 'Track breeding performance filtered by doe and buck. View conception rates, breeding history, and get insights into your breeding program success.',
          targetShapeBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tooltipBackgroundColor: AppColors.darkGreen,
          textColor: Colors.white,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            height: 1.3,
          ),
          overlayOpacity: 0.4,
          disableBarrierInteraction: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.darkGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Breeding Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // The actual widget without showcase
        _buildAnimatedCard(
          delay: 150,
          child: const BreedingAnalyticsWidget(),
        ),
      ],
    );
  }

}
