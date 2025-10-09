import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';

class CattleDetailTabs extends StatelessWidget {
  final TabController controller;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback onCattleUpdated;

  const CattleDetailTabs({
    super.key,
    required this.controller,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onCattleUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: controller,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(
                color: AppColors.primary, // Set the color of the underline
                width: 3.0, // Set the thickness of the underline
              ),
              insets: EdgeInsets.symmetric(horizontal: 24.0), // Optional: adjust the padding
            ),
            labelColor: AppColors.primary, // Change label color for active tab
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Details'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note, size: 20),
                    SizedBox(width: 8),
                    Text('History'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}