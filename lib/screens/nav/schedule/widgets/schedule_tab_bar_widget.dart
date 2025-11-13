import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class ScheduleTabBar extends StatelessWidget {
  final TabController tabController;
  final Map<String, int> tabCounts;

  const ScheduleTabBar({
    super.key,
    required this.tabController,
    required this.tabCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(child: _buildTabWithCount('All', tabCounts['all'] ?? 0)),
          Tab(child: _buildTabWithCount('Today', tabCounts['today'] ?? 0)),
          Tab(child: _buildTabWithCount('Upcoming', tabCounts['upcoming'] ?? 0)),
          Tab(child: _buildTabWithCount('Overdue', tabCounts['overdue'] ?? 0)),
          Tab(child: _buildTabWithCount('Completed', tabCounts['completed'] ?? 0)),
        ],
      ),
    );
  }

  Widget _buildTabWithCount(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Custom SliverTabBarDelegate
class ScheduleTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  ScheduleTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(ScheduleTabBarDelegate oldDelegate) {
    // Always rebuild to ensure tab counts are updated
    return true;
  }
}
