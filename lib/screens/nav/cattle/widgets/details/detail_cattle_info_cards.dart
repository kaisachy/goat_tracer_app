import 'package:cattle_tracer_app/screens/nav/cattle/widgets/details/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/utils/cattle_detail_utils.dart';
import 'info_item_widget.dart';

class CattleBasicInfoCard extends StatefulWidget {
  final Cattle cattle;

  const CattleBasicInfoCard({super.key, required this.cattle});

  /// Create a key that changes when cattle data changes
  static Key createKey(Cattle cattle) {
    return ValueKey('${cattle.id}_${cattle.dateOfBirth}_${cattle.classification}_${cattle.gender}');
  }

  @override
  State<CattleBasicInfoCard> createState() => _CattleBasicInfoCardState();
}

class _CattleBasicInfoCardState extends State<CattleBasicInfoCard> {
  @override
  void didUpdateWidget(CattleBasicInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when cattle data changes by checking key fields
    if (_shouldRebuild(oldWidget.cattle, widget.cattle)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  bool _shouldRebuild(Cattle oldCattle, Cattle newCattle) {
    return oldCattle.dateOfBirth != newCattle.dateOfBirth ||
        oldCattle.classification != newCattle.classification ||
        oldCattle.gender != newCattle.gender ||
        oldCattle.breed != newCattle.breed ||
        oldCattle.weight != newCattle.weight ||
        oldCattle.status != newCattle.status ||
        oldCattle.name != newCattle.name;
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
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
            icon: Icons.info_outline,
            title: 'Basic Information',
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          _buildInfoGrid([
            InfoItemData(
              icon: Icons.cake,
              title: 'Age',
              value: CattleDetailUtils.getAgeFromDob(widget.cattle.dateOfBirth),
            ),
            InfoItemData(
              icon: Icons.event,
              title: 'Date of Birth',
              value: CattleDetailUtils.formatDate(widget.cattle.dateOfBirth),
            ),
            InfoItemData(
              icon: CattleDetailUtils.getGenderIcon(widget.cattle.gender),
              title: 'Gender',
              value: widget.cattle.gender,
            ),
            InfoItemData(
              icon: Icons.category,
              title: 'Classification',
              value: CattleDetailUtils.getClassificationDisplay(widget.cattle.classification),
            ),
            InfoItemData(
              icon: FontAwesomeIcons.cow,
              title: 'Breed',
              value: CattleDetailUtils.getBreedDisplay(widget.cattle.breed),
            ),
            InfoItemData(
              icon: Icons.monitor_weight,
              title: 'Weight',
              value: CattleDetailUtils.formatWeight(widget.cattle.weight),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<InfoItemData> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 16 : 0),
            child: Row(
              children: [
                Expanded(
                  child: InfoItemWidget(
                    data: items[i],
                    color: AppColors.primary,
                  ),
                ),
                if (i + 1 < items.length) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoItemWidget(
                      data: items[i + 1],
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
