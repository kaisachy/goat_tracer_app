// milk_reports_tab.dart
import 'package:flutter/material.dart';

class MilkReportsTab extends StatelessWidget {
  final Function(String) generateReport;
  final VoidCallback showCustomReportDialog;

  const MilkReportsTab({
    super.key,
    required this.generateReport,
    required this.showCustomReportDialog,
  });

  @override
  Widget build(BuildContext context) {
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
              onTap: () => generateReport('daily'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Weekly Summary'),
              subtitle: const Text('Generate weekly production summary'),
              trailing: const Icon(Icons.download),
              onTap: () => generateReport('weekly'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Monthly Report'),
              subtitle: const Text('Complete monthly analysis'),
              trailing: const Icon(Icons.download),
              onTap: () => generateReport('monthly'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Custom Report'),
              subtitle: const Text('Create custom date range report'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: showCustomReportDialog,
            ),
          ),
        ],
      ),
    );
  }
}