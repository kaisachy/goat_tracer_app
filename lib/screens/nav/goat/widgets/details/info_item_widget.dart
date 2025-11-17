import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InfoItemData {
  final IconData icon;
  final String title;
  final String value;
  const InfoItemData({
    required this.icon,
    required this.title,
    required this.value,
  });
}

class InfoItemWidget extends StatelessWidget {
  final InfoItemData data;
  final Color color;
  const InfoItemWidget({
    super.key,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              data.icon == FontAwesomeIcons.cow
                  ? Image.asset(
                      'assets/images/goat-icons/goat.png',
                      width: 16,
                      height: 16,
                      color: color,
                    )
                  : Icon(data.icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

