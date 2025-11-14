import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/schedule/schedule_content.dart' as schedule_content;
import 'package:goat_tracer_app/screens/nav/schedule/schedule_form.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  VoidCallback? _onScheduleReload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: schedule_content.ScheduleContentWidget(
        onReloadCallback: (callback) {
          _onScheduleReload = callback;
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleForm(
              onScheduleAdded: () {
                // Trigger reload of schedule content
                _reloadScheduleContent();
              },
            ),
          ),
        );
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Add Schedule',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
    );
  }

  void _reloadScheduleContent() {
    // Trigger reload of the schedule content widget
    _onScheduleReload?.call();
  }
}