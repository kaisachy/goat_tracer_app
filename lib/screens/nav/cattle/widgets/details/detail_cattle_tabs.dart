// lib/screens/nav/cattle/widgets/detail_cattle_tabs.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';

class CattleDetailTabs extends StatelessWidget {
  final TabController controller;

  const CattleDetailTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.vibrantGreen,
        indicatorWeight: 3,
        labelColor: AppColors.vibrantGreen,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline),
            text: 'Details',
          ),
          Tab(
            icon: Icon(Icons.event_note),
            text: 'Events',
          ),
        ],
      ),
    );
  }
}