import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/services/breeding_analysis_service.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

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
  
  // Filter controllers
  String? _selectedCow;
  String? _selectedBull;
  String? _selectedBreedingType;
  
  // Available options for filters
  List<String> _availableCows = [];
  List<String> _availableBulls = [];
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
      final cows = await BreedingAnalysisService.getAvailableCows();
      final bulls = await BreedingAnalysisService.getAvailableBulls();
      final breedingTypes = await BreedingAnalysisService.getAvailableBreedingTypes();
      
      if (mounted) {
        setState(() {
          _availableCows = cows;
          _availableBulls = bulls;
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
        selectedCowTag: _selectedCow,
        selectedBullTag: _selectedBull,
        selectedBreedingType: _selectedBreedingType,
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
    _performAnalysis();
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
    final cowAnalysis = _analysisData!['cow_analysis'] as List;
    final bullPerformance = _analysisData!['bull_performance'] as List;
    final breedingTypePerformance = _analysisData!['breeding_type_performance'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters Section
          _buildFiltersSection(),
          const SizedBox(height: 20),
          
          // Overall Statistics
          _buildOverallStatistics(overallStats),
          const SizedBox(height: 20),
          
          // Charts Section
          _buildChartsSection(bullPerformance, breedingTypePerformance),
          const SizedBox(height: 20),
          
          // Tables Section
          _buildTablesSection(cowAnalysis, bullPerformance, breedingTypePerformance),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterDropdown(
            label: 'Cow',
            value: _selectedCow,
            items: ['All Cows', ..._availableCows],
            onChanged: (value) {
              setState(() {
                _selectedCow = value == 'All Cows' ? null : value;
              });
              _onFilterChanged();
            },
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            label: 'Bull',
            value: _selectedBull,
            items: ['All Bulls', ..._availableBulls],
            onChanged: (value) {
              setState(() {
                _selectedBull = value == 'All Bulls' ? null : value;
              });
              _onFilterChanged();
            },
          ),
          const SizedBox(height: 12),
          _buildBreedingTypeDropdown(),
        ],
      ),
    );
  }

  Widget _buildBreedingTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breeding Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBreedingType,
              hint: Text('All Types'),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Types'),
                ),
                ..._availableBreedingTypes.map((type) => DropdownMenuItem<String>(
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

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('Select $label'),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
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
                title: 'Total',
                value: stats['total_breedings'].toString(),
                color: AppColors.primary,
                icon: FontAwesomeIcons.cow,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Success',
                value: stats['total_successful'].toString(),
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
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
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
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

  Widget _buildChartsSection(List bullPerformance, List breedingTypePerformance) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Charts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          title: 'Bull Performance',
          child: _buildBullPerformanceChart(bullPerformance),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          title: 'Breeding Types',
          child: _buildBreedingTypeChart(breedingTypePerformance),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget _buildBullPerformanceChart(List bullPerformance) {
    if (bullPerformance.isEmpty) {
      return _buildEmptyState('No bull data available');
    }

    final sortedBulls = List.from(bullPerformance)
      ..sort((a, b) => (b['success_rate'] as double).compareTo(a['success_rate'] as double));
    final topBulls = sortedBulls.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < topBulls.length) {
                  final bull = topBulls[value.toInt()];
                  final tag = bull['bull_tag'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      tag.length > 4 ? '${tag.substring(0, 4)}...' : tag,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 20,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
          },
        ),
        barGroups: topBulls.asMap().entries.map((entry) {
          final index = entry.key;
          final bull = entry.value;
          final successRate = bull['success_rate'] as double;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: successRate,
                color: successRate >= 80 
                    ? Colors.green 
                    : successRate >= 60 
                        ? Colors.orange 
                        : Colors.red,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBreedingTypeChart(List breedingTypePerformance) {
    if (breedingTypePerformance.isEmpty) {
      return _buildEmptyState('No breeding type data available');
    }

    return PieChart(
      PieChartData(
        sections: breedingTypePerformance.map((type) {
          final typeName = type['type'] as String;
          final successRate = type['success_rate'] as double;
          final totalBreedings = type['total_breedings'] as int;
          
          // Map to user-friendly labels
          String displayName = typeName;
          switch (typeName.toLowerCase()) {
            case 'artificial_insemination':
              displayName = 'Artificial\nInsemination';
              break;
            case 'natural_breeding':
              displayName = 'Natural\nBreeding';
              break;
            case 'unknown':
              displayName = 'Unknown';
              break;
          }
          
          return PieChartSectionData(
            color: typeName == 'artificial_insemination' 
                ? AppColors.primary 
                : typeName == 'natural_breeding'
                    ? AppColors.vibrantGreen
                    : Colors.grey,
            value: totalBreedings.toDouble(),
            title: '$displayName\n${successRate.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 30,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTablesSection(List cowAnalysis, List bullPerformance, List breedingTypePerformance) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.table_chart, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Detailed Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTableCard(
          title: 'Cow Analysis',
          data: cowAnalysis,
          columns: ['Cow', 'Total', 'Success', 'Rate'],
          getRowData: (item) {
            final successRate = item['success_rate'] as double;
            return [
              item['cow_tag'],
              item['total_breedings'].toString(),
              item['successful_breedings'].toString(),
              '${successRate.toStringAsFixed(1)}%',
            ];
          },
          getRowColor: (item) {
            final successRate = item['success_rate'] as double;
            if (successRate >= 80) return Colors.green;
            if (successRate >= 60) return Colors.orange;
            return Colors.red;
          },
        ),
        const SizedBox(height: 12),
        _buildTableCard(
          title: 'Breeding Types',
          data: breedingTypePerformance,
          columns: ['Type', 'Total', 'Success', 'Rate'],
          getRowData: (item) {
            final successRate = item['success_rate'] as double;
            final typeName = item['type'] as String;
            
            // Map to user-friendly labels
            String displayName = typeName;
            switch (typeName.toLowerCase()) {
              case 'artificial_insemination':
                displayName = 'Artificial Insemination';
                break;
              case 'natural_breeding':
                displayName = 'Natural Breeding';
                break;
              case 'unknown':
                displayName = 'Unknown';
                break;
            }
            
            return [
              displayName,
              item['total_breedings'].toString(),
              item['successful_breedings'].toString(),
              '${successRate.toStringAsFixed(1)}%',
            ];
          },
          getRowColor: (item) {
            final successRate = item['success_rate'] as double;
            if (successRate >= 80) return Colors.green;
            if (successRate >= 60) return Colors.orange;
            return Colors.red;
          },
        ),
      ],
    );
  }

  Widget _buildTableCard({
    required String title,
    required List data,
    required List<String> columns,
    required List<String> Function(Map<String, dynamic>) getRowData,
    required Color Function(Map<String, dynamic>) getRowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No data available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns.map((col) => DataColumn(
                  label: Text(
                    col,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )).toList(),
                rows: data.map((item) {
                  final rowData = getRowData(item);
                  final color = getRowColor(item);
                  return DataRow(
                    cells: rowData.map((cell) => DataCell(
                      Text(
                        cell,
                        style: TextStyle(
                          fontSize: 12,
                          color: cell.contains('%') ? color : null,
                          fontWeight: cell.contains('%') ? FontWeight.w600 : null,
                        ),
                      ),
                    )).toList(),
                  );
                }).toList(),
                headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                dataTextStyle: const TextStyle(fontSize: 12),
                dividerThickness: 1,
                border: TableBorder.all(color: Colors.grey[200]!),
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
