import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/services/breeding_analysis_service.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';

class BreedingSuccessDashboard extends StatefulWidget {
  const BreedingSuccessDashboard({super.key});

  @override
  State<BreedingSuccessDashboard> createState() => _BreedingSuccessDashboardState();
}

class _BreedingSuccessDashboardState extends State<BreedingSuccessDashboard>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _analysisData;

  // Enhanced filter controllers
  String? _selectedDoe;
  String? _selectedBuck;
  String? _selectedBreedingType;
  DateTimeRange? _selectedDateRange;
  String? _selectedSuccessStatus; // 'all', 'successful', 'failed'

  // Available options for filters
  List<String> _availableDoes = [];
  List<String> _availableBucks = [];
  List<Map<String, String>> _availableBreedingTypes = [];

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load available options for filters
      final does = await BreedingAnalysisService.getAvailableDoes();
      final bucks = await BreedingAnalysisService.getAvailableBucks();
      final breedingTypes = await BreedingAnalysisService.getAvailableBreedingTypes();

      if (mounted) {
        setState(() {
          _availableDoes = does;
          _availableBucks = bucks;
          _availableBreedingTypes = breedingTypes;
        });
      }

      // Load initial analysis
      await _performAnalysis();

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performAnalysis() async {
    try {
      final result = await BreedingAnalysisService.getBreedingSuccessAnalysis(
        selectedDoeTag: _selectedDoe,
        selectedBuckTag: _selectedBuck,
        selectedBreedingType: _selectedBreedingType,
        dateRange: _selectedDateRange,
        successStatus: _selectedSuccessStatus,
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

  void _onFilterChanged() {
    _fadeController.reset();
    _slideController.reset();
    _performAnalysis();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDoe = null;
      _selectedBuck = null;
      _selectedBreedingType = null;
      _selectedDateRange = null;
      _selectedSuccessStatus = null;
    });
    _onFilterChanged();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Breeding Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildDashboard(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.vibrantGreen,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading analytics...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_analysisData == null) return const SizedBox.shrink();

    final overallStats = _analysisData!['overall_statistics'];
    final breedingTypePerformance = _analysisData!['breeding_type_performance'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Filters Section
          _buildEnhancedFiltersSection(),
          const SizedBox(height: 20),

          // Overall Statistics (without Total)
          _buildOverallStatistics(overallStats),
          const SizedBox(height: 20),

          // Breeding Type Progress Charts
          _buildBreedingTypeProgressSection(breedingTypePerformance),
        ],
      ),
    );
  }

  Widget _buildEnhancedFiltersSection() {
    final hasActiveFilters = _selectedDoe != null ||
        _selectedBuck != null ||
        _selectedBreedingType != null ||
        _selectedDateRange != null ||
        _selectedSuccessStatus != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Advanced Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasActiveFilters)
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // First row - Animal filters
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Doe',
                  value: _selectedDoe,
                  items: ['All Does', ..._availableDoes],
                  onChanged: (value) {
                    setState(() {
                      _selectedDoe = value == 'All Does' ? null : value;
                    });
                    _onFilterChanged();
                  },
                  icon: FontAwesomeIcons.cow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Buck',
                  value: _selectedBuck,
                  items: ['All Bucks', ..._availableBucks],
                  onChanged: (value) {
                    setState(() {
                      _selectedBuck = value == 'All Bucks' ? null : value;
                    });
                    _onFilterChanged();
                  },
                  icon: Icons.male,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Second row - Type and Status filters
          Row(
            children: [
              Expanded(child: _buildBreedingTypeDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildSuccessStatusDropdown()),
            ],
          ),

          const SizedBox(height: 12),

          // Third row - Date range filter
          _buildDateRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: value != null ? AppColors.primary.withValues(alpha: 0.5) : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: value != null ? AppColors.primary.withValues(alpha: 0.05) : Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: const TextStyle(fontSize: 12),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 16,
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreedingTypeDropdown() {
    // Always include Natural Breeding and Artificial Insemination
    List<Map<String, String>> allBreedingTypes = [
      {'value': 'natural_breeding', 'label': 'Natural Breeding'},
      {'value': 'artificial_insemination', 'label': 'Artificial Insemination'},
    ];

    // Add other types from fetched data if they don't already exist
    for (var type in _availableBreedingTypes) {
      if (!allBreedingTypes.any((t) => t['value'] == type['value'])) {
        allBreedingTypes.add(type);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.healing, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Breeding Type',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedBreedingType != null
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedBreedingType != null
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBreedingType,
              hint: const Text('All Types', style: TextStyle(fontSize: 12)),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 16,
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Types'),
                ),
                ...allBreedingTypes.map((type) => DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBreedingType = value;
                });
                _onFilterChanged();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Success Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedSuccessStatus != null
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedSuccessStatus != null
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSuccessStatus,
              hint: const Text('All Status', style: TextStyle(fontSize: 12)),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 16,
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              items: const [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Status'),
                ),
                DropdownMenuItem<String>(
                  value: 'successful',
                  child: Text('Successful Only'),
                ),
                DropdownMenuItem<String>(
                  value: 'failed',
                  child: Text('Failed Only'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSuccessStatus = value;
                });
                _onFilterChanged();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Date Range',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: _selectedDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedDateRange = picked;
              });
              _onFilterChanged();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedDateRange != null
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _selectedDateRange != null
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDateRange != null
                      ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                      : 'Select date range',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedDateRange != null
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    if (_selectedDateRange != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                          _onFilterChanged();
                        },
                        child: Icon(
                          Icons.clear,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallStatistics(Map<String, dynamic> stats) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
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
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Failed',
                value: stats['total_failed'].toString(),
                color: Colors.red,
                icon: Icons.cancel,
              ),
            ),
            const SizedBox(width: 8),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreedingTypeProgressSection(List breedingTypePerformance) {
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
        // Update existing default entry with actual data
        allBreedingTypes[existingIndex] = actualType;
      } else {
        // Add additional types that aren't the main two
        allBreedingTypes.add(actualType);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Breeding Type Performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...allBreedingTypes.map((type) => _buildProgressDoughnutCard(type)),
      ],
    );
  }

  Widget _buildProgressDoughnutCard(Map<String, dynamic> typeData) {
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        // Add subtle opacity for empty data
        border: hasData ? null : Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Opacity(
        opacity: hasData ? 1.0 : 0.6,
        child: Row(
          children: [
            // Progress Doughnut Chart
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: hasData ? successRate / 100 : 0.0,
                      strokeWidth: 8,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasData ? primaryColor : Colors.grey[500],
                        ),
                      ),
                      Icon(
                        icon,
                        size: 12,
                        color: hasData ? primaryColor.withValues(alpha: 0.7) : Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hasData ? AppColors.textPrimary : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMiniStat(
                        label: 'Total',
                        value: totalBreedings.toString(),
                        color: hasData ? Colors.blue : Colors.grey[400]!,
                      ),
                      const SizedBox(width: 16),
                      _buildMiniStat(
                        label: 'Success',
                        value: successfulBreedings.toString(),
                        color: hasData ? Colors.green : Colors.grey[400]!,
                      ),
                      const SizedBox(width: 16),
                      _buildMiniStat(
                        label: 'Failed',
                        value: (totalBreedings - successfulBreedings).toString(),
                        color: hasData ? Colors.red : Colors.grey[400]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: hasData ? successRate / 100 : 0.0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        hasData ? primaryColor : Colors.grey[300]!
                    ),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
