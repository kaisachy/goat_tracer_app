import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../constants/app_colors.dart';

class MilkScreen extends StatefulWidget {
  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Daily';

  // Sample milk production data - replace with actual data from your service
  final List<Map<String, dynamic>> _sampleMilkRecords = [
    {
      'id': 1,
      'cattleId': 'COW001',
      'cattleName': 'Bella',
      'date': DateTime.now(),
      'morningYield': 12.5,
      'eveningYield': 10.2,
      'totalYield': 22.7,
      'quality': 'A',
      'notes': 'Good quality milk',
    },
    {
      'id': 2,
      'cattleId': 'COW002',
      'cattleName': 'Luna',
      'date': DateTime.now().subtract(Duration(days: 1)),
      'morningYield': 15.0,
      'eveningYield': 12.8,
      'totalYield': 27.8,
      'quality': 'A+',
      'notes': 'Excellent production',
    },
    {
      'id': 3,
      'cattleId': 'COW003',
      'cattleName': 'Daisy',
      'date': DateTime.now().subtract(Duration(days: 2)),
      'morningYield': 8.5,
      'eveningYield': 7.3,
      'totalYield': 15.8,
      'quality': 'B+',
      'notes': 'Slightly lower production',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
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
        onPressed: () => _showAddMilkRecordDialog(),
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
              'Today\'s Total', '45.3 L', Icons.opacity, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(
              'Weekly Avg', '42.1 L', Icons.trending_up, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(
              'Active Cows', '8', FontAwesomeIcons.cow, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color color) {
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
                  backgroundColor: isSelected ? AppColors.primary : Colors.grey
                      .shade200,
                  foregroundColor: isSelected ? Colors.white : Colors.grey
                      .shade700,
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sampleMilkRecords.length,
      itemBuilder: (context, index) {
        final record = _sampleMilkRecords[index];
        return _buildMilkRecordCard(record);
      },
    );
  }

  Widget _buildMilkRecordCard(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMilkRecordDetails(record),
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
                    child: const FaIcon(
                        FontAwesomeIcons.cow, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record['cattleName']} (${record['cattleId']})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(record['date']),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildQualityBadge(record['quality']),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildYieldInfo('Morning', record['morningYield']),
                  ),
                  Expanded(
                    child: _buildYieldInfo('Evening', record['eveningYield']),
                  ),
                  Expanded(
                    child: _buildYieldInfo(
                        'Total', record['totalYield'], isTotal: true),
                  ),
                ],
              ),
              if (record['notes'] != null && record['notes'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record['notes'],
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Production Trends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Chart will be displayed here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Performers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPerformerItem('Bella', 'COW001', 22.7, 1),
                  _buildPerformerItem('Luna', 'COW002', 27.8, 2),
                  _buildPerformerItem('Daisy', 'COW003', 15.8, 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformerItem(String name, String id, double yield, int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: rank <= 3 ? AppColors.primary : Colors.grey,
            child: Text(
              '$rank',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$name ($id)'),
          ),
          Text(
            '${yield.toStringAsFixed(1)} L',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Daily Production Report'),
              subtitle: const Text('Generate PDF report for today'),
              trailing: const Icon(Icons.download),
              onTap: () => _generateReport('daily'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Weekly Summary'),
              subtitle: const Text('Generate weekly production summary'),
              trailing: const Icon(Icons.download),
              onTap: () => _generateReport('weekly'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Monthly Report'),
              subtitle: const Text('Complete monthly analysis'),
              trailing: const Icon(Icons.download),
              onTap: () => _generateReport('monthly'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Custom Report'),
              subtitle: const Text('Create custom date range report'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => _showCustomReportDialog(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date
        .difference(now)
        .inDays;

    if (diff == 0) {
      return 'Today';
    } else if (diff == -1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showMilkRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('${record['cattleName']} - Milk Record'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${_formatDate(record['date'])}'),
                const SizedBox(height: 8),
                Text('Morning Yield: ${record['morningYield']} L'),
                const SizedBox(height: 8),
                Text('Evening Yield: ${record['eveningYield']} L'),
                const SizedBox(height: 8),
                Text('Total Yield: ${record['totalYield']} L'),
                const SizedBox(height: 8),
                Text('Quality Grade: ${record['quality']}'),
                if (record['notes'] != null && record['notes'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${record['notes']}'),
                ],
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
                  // Navigate to edit record
                },
                child: const Text('Edit'),
              ),
            ],
          ),
    );
  }

  void _showAddMilkRecordDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Add Milk Record Screen'),
        backgroundColor: AppColors.primary,
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Custom Report Screen'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}