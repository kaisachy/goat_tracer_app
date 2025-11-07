import 'package:cattle_tracer_app/screens/nav/cattle/widgets/details/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/utils/cattle_detail_utils.dart';
import 'info_item_widget.dart';


class CattleManagementCard extends StatelessWidget {
  final Cattle cattle;
  const CattleManagementCard({super.key, required this.cattle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightGreen.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderWidget(
            icon: Icons.manage_accounts,
            title: 'Management Information',
            color: AppColors.lightGreen,
          ),
          const SizedBox(height: 24),
          _buildInfoGrid([
            InfoItemData(
              icon: Icons.home,
              title: 'Source',
              value: CattleDetailUtils.getSourceDisplay(cattle.source, cattle.sourceDetails),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<InfoItemData> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: InfoItemWidget(
              data: items[i],
              color: AppColors.lightGreen,
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}
