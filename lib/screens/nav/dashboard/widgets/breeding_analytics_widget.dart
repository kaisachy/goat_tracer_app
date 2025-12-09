import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/services/breeding_analysis_service.dart';

class BreedingAnalyticsWidget extends StatefulWidget {
  const BreedingAnalyticsWidget({super.key});

  @override
  State<BreedingAnalyticsWidget> createState() => _BreedingAnalyticsWidgetState();
}

class _BreedingAnalyticsWidgetState extends State<BreedingAnalyticsWidget>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _analysisData;


  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load analysis
      await _performAnalysis();

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load breeding analytics: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performAnalysis() async {
    try {
      final result = await BreedingAnalysisService.getBreedingSuccessAnalysis(
        selectedDoeTag: null,
        selectedBuckTag: null,
        dateRange: null,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _analysisData = result['data'];
            _error = null;
            _isLoading = false;
          });

          // Start animations
          _fadeController.forward();
          _slideController.forward();
        } else {
          setState(() {
            _error = result['error'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Analysis failed: $e';
          _isLoading = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildAnalyticsContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, color: AppColors.darkGreen, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Breeding Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Center(
          child: CircularProgressIndicator(
            color: AppColors.vibrantGreen,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Loading analytics...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, color: AppColors.darkGreen, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Breeding Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error ?? 'Failed to load data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, color: AppColors.vibrantGreen),
                iconSize: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsContent() {
    if (_analysisData == null) return const SizedBox.shrink();

    final overallStats = _analysisData!['overall_statistics'];
    final breedingTypePerformance = _analysisData!['breeding_type_performance'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.analytics, color: AppColors.darkGreen, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Breeding Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Overall Statistics
        _buildOverallStats(overallStats),
        const SizedBox(height: 20),

        // Breeding Type Performance
        _buildBreedingTypePerformance(breedingTypePerformance),
      ],
    );
  }


  Widget _buildOverallStats(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Success',
                value: stats['total_successful'].toString(),
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Failed',
                value: stats['total_failed'].toString(),
                color: Colors.red,
                icon: Icons.cancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Rate',
                value: '${stats['overall_success_rate'].toStringAsFixed(1)}%',
                color: AppColors.vibrantGreen,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreedingTypePerformance(List breedingTypePerformance) {
    // Always show Natural Breeding and Artificial Insemination
    List<Map<String, dynamic>> allBreedingTypes = [
      {
        'type': 'natural_breeding',
        'total_breedings': 0,
        'successful_breedings': 0,
        'success_rate': 0.0,
      },
      {
        'type': 'artificial_insemination',
        'total_breedings': 0,
        'successful_breedings': 0,
        'success_rate': 0.0,
      }
    ];

    // Update with actual data if available
    for (var actualType in breedingTypePerformance) {
      final typeName = actualType['type'] as String;
      final existingIndex = allBreedingTypes.indexWhere((t) => t['type'] == typeName);

      if (existingIndex != -1) {
        allBreedingTypes[existingIndex] = actualType;
      } else {
        allBreedingTypes.add(actualType);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Breeding Type Performance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...allBreedingTypes.map((type) => _buildBreedingTypeCard(type)),
      ],
    );
  }

  Widget _buildBreedingTypeCard(Map<String, dynamic> typeData) {
    final typeName = typeData['type'] as String;
    final successRate = (typeData['success_rate'] as num).toDouble();
    final totalBreedings = typeData['total_breedings'] as int;
    final successfulBreedings = typeData['successful_breedings'] as int;
    final hasData = totalBreedings > 0;

    // Map to user-friendly labels and colors
    String displayName = typeName;
    Color primaryColor = AppColors.primary;
    IconData icon = Icons.healing;

    switch (typeName.toLowerCase()) {
      case 'artificial_insemination':
        displayName = 'Artificial Insemination';
        primaryColor = AppColors.primary;
        icon = Icons.science;
        break;
      case 'natural_breeding':
        displayName = 'Natural Breeding';
        primaryColor = AppColors.vibrantGreen;
        icon = Icons.nature;
        break;
      case 'unknown':
        displayName = 'Unknown Method';
        primaryColor = Colors.grey;
        icon = Icons.help_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Progress Circle
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: hasData ? successRate / 100 : 0.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        hasData ? primaryColor : Colors.grey[300]!
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasData ? '${successRate.toStringAsFixed(0)}%' : '0%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasData ? primaryColor : Colors.grey[500],
                      ),
                    ),
                    Icon(
                      icon,
                      size: 10,
                      color: hasData ? primaryColor.withValues(alpha: 0.7) : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasData ? AppColors.textPrimary : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat(
                      label: 'Total',
                      value: totalBreedings.toString(),
                      color: hasData ? Colors.blue : Colors.grey[400]!,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      label: 'Success',
                      value: successfulBreedings.toString(),
                      color: hasData ? Colors.green : Colors.grey[400]!,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      label: 'Failed',
                      value: (totalBreedings - successfulBreedings).toString(),
                      color: hasData ? Colors.red : Colors.grey[400]!,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: hasData ? successRate / 100 : 0.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      hasData ? primaryColor : Colors.grey[300]!
                  ),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

