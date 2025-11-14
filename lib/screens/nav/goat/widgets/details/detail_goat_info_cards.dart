import 'package:goat_tracer_app/screens/nav/goat/widgets/details/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/utils/goat_detail_utils.dart';
import 'info_item_widget.dart';

class goatBasicInfoCard extends StatefulWidget {
  final goat goat;

  const goatBasicInfoCard({super.key, required this.goat});

  /// Create a key that changes when goat data changes
  static Key createKey(goat goat) {
    return ValueKey('${goat.id}_${goat.dateOfBirth}_${goat.classification}_${goat.sex}');
  }

  @override
  State<goatBasicInfoCard> createState() => _goatBasicInfoCardState();
}

class _goatBasicInfoCardState extends State<goatBasicInfoCard> {
  @override
  void didUpdateWidget(goatBasicInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when goat data changes by checking key fields
    if (_shouldRebuild(oldWidget.goat, widget.goat)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  bool _shouldRebuild(goat oldgoat, goat newgoat) {
    return oldgoat.dateOfBirth != newgoat.dateOfBirth ||
        oldgoat.classification != newgoat.classification ||
        oldgoat.sex != newgoat.sex ||
        oldgoat.breed != newgoat.breed ||
        oldgoat.weight != newgoat.weight ||
        oldgoat.status != newgoat.status;
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
              value: goatDetailUtils.getAgeFromDob(widget.goat.dateOfBirth),
            ),
            InfoItemData(
              icon: Icons.event,
              title: 'Date of Birth',
              value: goatDetailUtils.formatDate(widget.goat.dateOfBirth),
            ),
            InfoItemData(
              icon: goatDetailUtils.getGenderIcon(widget.goat.sex),
              title: 'Sex',
              value: widget.goat.sex,
            ),
            InfoItemData(
              icon: Icons.category,
              title: 'Classification',
              value: goatDetailUtils.getClassificationDisplay(widget.goat.classification),
            ),
            InfoItemData(
              icon: FontAwesomeIcons.Doe,
              title: 'Breed',
              value: goatDetailUtils.getBreedDisplay(widget.goat.breed),
            ),
            InfoItemData(
              icon: Icons.monitor_weight,
              title: 'Weight',
              value: goatDetailUtils.formatWeight(widget.goat.weight),
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

