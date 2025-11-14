import 'package:goat_tracer_app/screens/nav/goat/widgets/details/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/utils/goat_detail_utils.dart';

class goatNotesSection extends StatelessWidget {
  final goat goat;
  const goatNotesSection({super.key, required this.goat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
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
            icon: Icons.note_alt,
            title: 'Additional Notes',
            color: AppColors.accent,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              goatDetailUtils.getNotesDisplay(goat.notes),
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: goatDetailUtils.hasNotes(goat.notes)
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontStyle: goatDetailUtils.hasNotes(goat.notes)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

