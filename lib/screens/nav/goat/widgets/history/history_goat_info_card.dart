import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../models/goat.dart';
import '../../../../../constants/app_colors.dart';

class HistorygoatInfoCard extends StatelessWidget {
  final goat? goatDetails;
  final String? goatTag;

  const HistorygoatInfoCard({
    super.key,
    required this.goatDetails,
    required this.goatTag,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return const Color(0xFF22C55E);// Modern green
      case 'sick':
        return const Color(0xFFFFA500); // Modern orange
      case 'lactating':
        return const Color(0xFF3B82F6); // Modern blue
      case 'pregnant':
        return const Color(0xFF8B5CF6); // Purple
      case 'lactating & pregnant':
        return const Color(0xFFEC4899); // Pink (combination status)
      case 'sold':
        return const Color(0xFF7F7F7F); //Gray
      case 'mortality':
        return const Color(0xFFEF4444); // Modern red
      default:
        return const Color(0xFF10B981); // Emerald green (fallback)
    }
  }

  @override
  Widget build(BuildContext context) {
    // REFACTORED: The parent screen now controls the loading indicator.
    // This widget now only handles the "data available" vs "data not found/error" state.
    if (goatDetails == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load goat information',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tag: ${goatTag ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.vibrantGreen.withValues(alpha: 0.1),
            AppColors.lightGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightGreen.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  FontAwesomeIcons.Doe,
                  color: AppColors.vibrantGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goatDetails!.tagNo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goatDetails!.classification.isNotEmpty == true
                          ? goatDetails!.classification
                          : 'Classification',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(goatDetails!.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(goatDetails!.status).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  goatDetails!.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(goatDetails!.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
