import 'package:goat_tracer_app/screens/nav/goat/widgets/details/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/utils/goat_detail_utils.dart';
import 'info_item_widget.dart';

class GoatBasicInfoCard extends StatefulWidget {
  final Goat goat;

  const GoatBasicInfoCard({super.key, required this.goat});

  /// Create a key that changes when goat data changes
  static Key createKey(Goat goat) {
    return ValueKey('${goat.id}_${goat.dateOfBirth}_${goat.classification}_${goat.sex}');
  }

  @override
  State<GoatBasicInfoCard> createState() => _GoatBasicInfoCardState();
}

class _GoatBasicInfoCardState extends State<GoatBasicInfoCard> {
  @override
  void didUpdateWidget(GoatBasicInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when goat data changes by checking key fields
    if (_shouldRebuild(oldWidget.goat, widget.goat)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  bool _shouldRebuild(Goat oldGoat, Goat newGoat) {
    return oldGoat.dateOfBirth != newGoat.dateOfBirth ||
        oldGoat.classification != newGoat.classification ||
        oldGoat.sex != newGoat.sex ||
        oldGoat.breed != newGoat.breed ||
        oldGoat.weight != newGoat.weight ||
        oldGoat.status != newGoat.status;
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
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
              value: GoatDetailUtils.getAgeFromDob(widget.goat.dateOfBirth),
            ),
            InfoItemData(
              icon: Icons.event,
              title: 'Date of Birth',
              value: GoatDetailUtils.formatDate(widget.goat.dateOfBirth),
            ),
            InfoItemData(
              icon: GoatDetailUtils.getGenderIcon(widget.goat.sex),
              title: 'Sex',
              value: widget.goat.sex,
            ),
            InfoItemData(
              icon: Icons.category,
              title: 'Classification',
              value: GoatDetailUtils.getClassificationDisplay(widget.goat.classification),
            ),
            InfoItemData(
              icon: FontAwesomeIcons.cow,
              title: 'Breed',
              value: GoatDetailUtils.getBreedDisplay(widget.goat.breed),
            ),
            InfoItemData(
              icon: Icons.monitor_weight,
              title: 'Weight',
              value: GoatDetailUtils.formatWeight(widget.goat.weight),
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

