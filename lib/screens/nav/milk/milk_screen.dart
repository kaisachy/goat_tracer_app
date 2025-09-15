// Fixed milk_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/app_colors.dart';
import '../../../models/milk.dart';
import '../../../services/cattle/cattle_service.dart';
import '../../../models/cattle.dart';
import '../../../services/milk/milk_production_service.dart';
import 'milk_record_form.dart';
import 'milk_analytics_tab.dart';
import 'milk_reports_tab.dart';

class MilkScreen extends StatefulWidget {
  const MilkScreen({super.key});

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Daily';
  List<MilkProduction> _milkRecords = [];
  List<Cattle> _allCattle = [];
  bool _isLoading = true;

  // Statistics variables
  double _todaysTotal = 0.0;
  double _weeklyAverage = 0.0;
  int _activeCows = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all cattle first, then filter for cows only
      final allCattle = await CattleService.getAllCattle();
      final cows = allCattle.where((cattle) =>
      cattle.classification.toLowerCase() == 'cow').toList();

      final milkRecords = await MilkProductionService.getMilkProductions();

      setState(() {
        _allCattle = cows; // Only store cows
        _milkRecords = milkRecords;
        _calculateStatistics();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _calculateStatistics() {
    final today = DateTime.now();
    final todayRecords = _milkRecords.where((record) =>
    record.recordDate.year == today.year &&
        record.recordDate.month == today.month &&
        record.recordDate.day == today.day).toList();

    // Calculate today's total
    _todaysTotal = todayRecords.fold(0.0, (sum, record) =>
    sum + (record.totalYield ?? 0.0));

    // Calculate weekly average (last 7 days)
    final weekAgo = today.subtract(Duration(days: 7));
    final weekRecords = _milkRecords.where((record) =>
        record.recordDate.isAfter(weekAgo)).toList();

    if (weekRecords.isNotEmpty) {
      final weeklyTotal = weekRecords.fold(0.0, (sum, record) =>
      sum + (record.totalYield ?? 0.0));
      _weeklyAverage = weeklyTotal / 7;
    } else {
      _weeklyAverage = 0.0;
    }

    // Count active cows (cows that have milk records in the last 30 days)
    final monthAgo = today.subtract(Duration(days: 30));
    final activeTags = _milkRecords
        .where((record) => record.recordDate.isAfter(monthAgo))
        .map((record) => record.cattleTag)
        .where((tag) => tag != null)
        .toSet();

    _activeCows = activeTags.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildStatsCards(),
          _buildPeriodSelector(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductionTab(),
                _buildAnalyticsTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddMilkRecord(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Record Milk'),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(
              'Today\'s Total', '${_todaysTotal.toStringAsFixed(1)} L',
              Icons.opacity, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(
              'Weekly Avg', '${_weeklyAverage.toStringAsFixed(1)} L',
              Icons.trending_up, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(
              'Milking Cows', '$_activeCows',
              FontAwesomeIcons.cow, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Daily', 'Weekly', 'Monthly'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedPeriod = period),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade200,
                  foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(period),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Production'),
          Tab(text: 'Analytics'),
          Tab(text: 'Reports'),
        ],
      ),
    );
  }

  Widget _buildProductionTab() {
    if (_milkRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.opacity, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No milk records found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to record milk from your cows',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Filter records based on selected period
    final filteredRecords = _getFilteredRecords();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          final record = filteredRecords[index];
          return _buildMilkRecordCard(record);
        },
      ),
    );
  }

  List<MilkProduction> _getFilteredRecords() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'Daily':
        return _milkRecords.where((record) =>
        record.recordDate.year == now.year &&
            record.recordDate.month == now.month &&
            record.recordDate.day == now.day).toList();
      case 'Weekly':
        final weekAgo = now.subtract(Duration(days: 7));
        return _milkRecords.where((record) =>
            record.recordDate.isAfter(weekAgo)).toList();
      case 'Monthly':
        final monthAgo = now.subtract(Duration(days: 30));
        return _milkRecords.where((record) =>
            record.recordDate.isAfter(monthAgo)).toList();
      default:
        return _milkRecords;
    }
  }

  Widget _buildMilkRecordCard(MilkProduction record) {
    // Find cattle name from tag
    final cattle = _allCattle.firstWhere(
          (c) => c.tagNo == record.cattleTag,
      orElse: () => Cattle(
        id: 0,
        tagNo: record.cattleTag ?? 'Unknown',
        sex: 'Unknown',
        classification: 'Unknown',
        status: 'Unknown',
        source: 'Unknown',
      ),
    );

    // Check if this should be displayed as "Whole Farm Milk"
    final isWholeFarmMilk = (record.cattleTag == null || record.cattleTag == 'N/A' || record.cattleTag == 'Unknown');
    final displayTitle = isWholeFarmMilk ? 'Whole Farm Milk' : '${record.cattleTag ?? 'N/A'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMilkRecordDetails(record, cattle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                        isWholeFarmMilk ? FontAwesomeIcons.warehouse : FontAwesomeIcons.cow,
                        color: Colors.blue,
                        size: 20
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(record.recordDate),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildQualityBadge(record.milkQuality ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildYieldInfo('Morning', record.morningYield ?? 0.0),
                  ),
                  Expanded(
                    child: _buildYieldInfo('Evening', record.eveningYield ?? 0.0),
                  ),
                  Expanded(
                    child: _buildYieldInfo('Total', record.totalYield ?? 0.0, isTotal: true),
                  ),
                ],
              ),
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.notes!,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYieldInfo(String label, double value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)} L',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primary : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityBadge(String quality) {
    Color color;
    switch (quality) {
      case 'A+':
        color = Colors.green;
        break;
      case 'A':
        color = Colors.lightGreen;
        break;
      case 'B+':
        color = Colors.orange;
        break;
      case 'B':
        color = Colors.deepOrange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        'Grade $quality',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return MilkAnalyticsTab(
      milkRecords: _milkRecords,
      allCattle: _allCattle,
    );
  }

  Widget _buildReportsTab() {
    return MilkReportsTab(
      generateReport: _generateReport,
      showCustomReportDialog: _showCustomReportDialog,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showMilkRecordDetails(MilkProduction record, Cattle cattle) {
    // Check if this should be displayed as "Whole Farm Milk"
    final isWholeFarmMilk = (record.cattleTag == null || record.cattleTag == 'N/A' || record.cattleTag == 'Unknown');
    final displayTitle = isWholeFarmMilk ? 'Whole Farm Milk' : '${record.cattleTag ?? 'N/A'}';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white, // Changed to solid white
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                        isWholeFarmMilk
                            ? FontAwesomeIcons.warehouse
                            : FontAwesomeIcons.cow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Record Details',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getQualityColor(record.milkQuality ?? 'N/A').withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getQualityColor(record.milkQuality ?? 'N/A').withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'Grade ${record.milkQuality ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and Type Info
                      _buildDetailRow(
                        icon: FontAwesomeIcons.calendar,
                        label: 'Date',
                        value: _formatDate(record.recordDate),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      _buildDetailRow(
                        icon: FontAwesomeIcons.droplet,
                        label: 'Milk Type',
                        value: record.milkType ?? (isWholeFarmMilk ? 'Whole Farm Milk' : 'N/A'),
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),

                      if (!isWholeFarmMilk) ...[
                        _buildDetailRow(
                          icon: FontAwesomeIcons.tag,
                          label: 'Cattle Tag',
                          value: record.cattleTag ?? 'N/A',
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Production Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.05),
                              AppColors.primary.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildYieldCard(
                                    'Morning',
                                    record.morningYield ?? 0.0,
                                    FontAwesomeIcons.sun,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildYieldCard(
                                    'Evening',
                                    record.eveningYield ?? 0.0,
                                    FontAwesomeIcons.moon,
                                    Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Total Yield - Featured
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.bottleDroplet,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      Text(
                                        '${(record.totalYield ?? 0.0).toStringAsFixed(1)} L',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Total Yield',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Notes Section
                      if (record.notes != null && record.notes!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.stickyNote,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Notes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                record.notes!,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToEditMilkRecord(record);
                        },
                        icon: const FaIcon(FontAwesomeIcons.edit, size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteRecord(record);
                        },
                        icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYieldCard(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)} L',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'A+': return Colors.green;
      case 'A': return Colors.lightGreen;
      case 'B+': return Colors.orange;
      case 'B': return Colors.deepOrange;
      case 'C': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Future<void> _navigateToAddMilkRecord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MilkRecordFormScreen(
          allCattle: _allCattle,
          isEditing: false,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (result['delete'] == true) {
        // Handle delete if needed
        if (result['recordId'] != null) {
          await _deleteMilkRecord(result['recordId']);
        }
      } else {
        // Handle add/update
        await _handleFormResult(result);
      }
    }
  }

  Future<void> _navigateToEditMilkRecord(MilkProduction record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MilkRecordFormScreen(
          record: record,
          allCattle: _allCattle,
          isEditing: true,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (result['delete'] == true) {
        // Handle delete
        if (result['recordId'] != null) {
          await _deleteMilkRecord(result['recordId']);
        }
      } else {
        // Handle update
        await _handleFormResult(result);
      }
    }
  }

  Future<void> _handleFormResult(Map<String, dynamic> result) async {
    final milkType = result['milkType'] as String;
    final cattleTag = result['cattleTag'] as String?;
    final recordDate = result['recordDate'] as DateTime;
    final morningYield = result['morningYield'] as double?;
    final eveningYield = result['eveningYield'] as double?;
    final quality = result['quality'] as String;
    final notes = result['notes'] as String? ?? '';
    final isEditing = result['isEditing'] as bool? ?? false;
    final recordId = result['recordId'] as int?;

    if (isEditing && recordId != null) {
      await _updateMilkRecord(recordId, milkType, cattleTag, recordDate, morningYield, eveningYield, quality, notes);
    } else {
      await _addMilkRecord(milkType, cattleTag, recordDate, morningYield, eveningYield, quality, notes);
    }
  }

  Future<void> _addMilkRecord(
      String milkType,
      String? cattleTag,
      DateTime recordDate,
      double? morningYield,
      double? eveningYield,
      String quality,
      String notes,
      ) async {
    // Validation based on milk type
    if (milkType == 'Individual Cow Milk' && cattleTag == null) {
      _showErrorSnackBar('Please select a cow for individual cow milk');
      return;
    }

    if (milkType == 'Individual Cow Milk' && _allCattle.isEmpty) {
      _showErrorSnackBar('No cows available for milk recording');
      return;
    }

    // Calculate total yield
    final totalYield = (morningYield ?? 0.0) + (eveningYield ?? 0.0);

    final data = {
      'milk_type': milkType,
      'cattle_tag': milkType == 'Individual Cow Milk' ? cattleTag : null,
      'record_date': recordDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'morning_yield': morningYield,
      'evening_yield': eveningYield,
      'total_yield': totalYield,
      'milk_quality': quality,
      'notes': notes.isEmpty ? null : notes,
    };

    try {
      final success = await MilkProductionService.storeMilkProduction(data);

      if (success) {
        _showSuccessSnackBar('Milk record added successfully');
        await _loadData(); // Refresh data
      } else {
        _showErrorSnackBar('Failed to add milk record');
      }
    } catch (e) {
      _showErrorSnackBar('Error adding milk record: $e');
    }
  }

  Future<void> _updateMilkRecord(
      int id,
      String milkType,
      String? cattleTag,
      DateTime recordDate,
      double? morningYield,
      double? eveningYield,
      String quality,
      String notes,
      ) async {
    // Validation based on milk type
    if (milkType == 'Individual Cow Milk' && cattleTag == null) {
      _showErrorSnackBar('Please select a cow for individual cow milk');
      return;
    }

    // Calculate total yield
    final totalYield = (morningYield ?? 0.0) + (eveningYield ?? 0.0);

    final data = {
      'id': id,
      'milk_type': milkType,
      'cattle_tag': milkType == 'Individual Cow Milk' ? cattleTag : null,
      'record_date': recordDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'morning_yield': morningYield,
      'evening_yield': eveningYield,
      'total_yield': totalYield,
      'milk_quality': quality,
      'notes': notes.isEmpty ? null : notes,
    };

    try {
      final success = await MilkProductionService.updateMilkProduction(data);

      if (success) {
        _showSuccessSnackBar('Milk record updated successfully');
        await _loadData(); // Refresh data
      } else {
        _showErrorSnackBar('Failed to update milk record');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating milk record: $e');
    }
  }

  void _confirmDeleteRecord(MilkProduction record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this milk record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMilkRecord(record.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMilkRecord(int id) async {
    try {
      final success = await MilkProductionService.deleteMilkProduction(id);

      if (success) {
        _showSuccessSnackBar('Milk record deleted successfully');
        await _loadData(); // Refresh data
      } else {
        _showErrorSnackBar('Failed to delete milk record');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting milk record: $e');
    }
  }

  void _generateReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $type report...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showCustomReportDialog() {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Custom Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Start Date: ${startDate != null ? "${startDate!.day}/${startDate!.month}/${startDate!.year}" : "Not selected"}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => startDate = date);
                  }
                },
              ),
              ListTile(
                title: Text('End Date: ${endDate != null ? "${endDate!.day}/${endDate!.month}/${endDate!.year}" : "Not selected"}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => endDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: startDate != null && endDate != null
                  ? () {
                Navigator.pop(context);
                _generateCustomReport(startDate!, endDate!);
              }
                  : null,
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _generateCustomReport(DateTime startDate, DateTime endDate) {
    final filteredRecords = _milkRecords.where((record) =>
    record.recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
        record.recordDate.isBefore(endDate.add(Duration(days: 1)))).toList();

    final totalProduction = filteredRecords.fold(0.0, (sum, record) =>
    sum + (record.totalYield ?? 0.0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}'),
            const SizedBox(height: 8),
            Text('Total Records: ${filteredRecords.length}'),
            const SizedBox(height: 8),
            Text('Total Production: ${totalProduction.toStringAsFixed(1)} L'),
            const SizedBox(height: 8),
            Text('Average per Day: ${(totalProduction / (endDate.difference(startDate).inDays + 1)).toStringAsFixed(1)} L'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Report data exported (feature not implemented)');
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}