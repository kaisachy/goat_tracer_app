import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/event/event_content.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/schedule_content.dart' as schedule_content;
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_event_form_screen.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/cattle_schedule_form.dart';
import 'package:cattle_tracer_app/screens/nav/event/cattle_selection_modal.dart';

class EventScheduleScreen extends StatefulWidget {
  final int initialTabIndex;

  const EventScheduleScreen({super.key, this.initialTabIndex = 0});

  @override
  State<EventScheduleScreen> createState() => _EventScheduleScreenState();
}

class _EventScheduleScreenState extends State<EventScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VoidCallback? _onScheduleReload;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 1));
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.event_note_rounded),
                  text: 'Events',
                ),
                Tab(
                  icon: Icon(Icons.schedule_rounded),
                  text: 'Schedule',
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const EventContent(),
                schedule_content.ScheduleContentWidget(
                  onReloadCallback: (callback) {
                    _onScheduleReload = callback;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        if (_tabController.index == 0) {
          // Events tab - show cattle selection modal first
          final selectedCattleTag = await showDialog<String>(
            context: context,
            builder: (context) => const CattleSelectionModal(),
          );

          // If a cattle was selected, open the event form with the selected cattle
          if (selectedCattleTag != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CattleEventFormScreen(cattleTag: selectedCattleTag),
              ),
            );
          }
        } else {
          // Schedule tab
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CattleScheduleForm(
                onScheduleAdded: () {
                  // Trigger reload of schedule content
                  _reloadScheduleContent();
                },
              ),
            ),
          );
        }
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: Icon(_tabController.index == 0 ? Icons.add_rounded : Icons.add, size: 20),
      label: Text(
        _tabController.index == 0 ? 'Add Event' : 'Add Schedule',
        style: const TextStyle(
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
