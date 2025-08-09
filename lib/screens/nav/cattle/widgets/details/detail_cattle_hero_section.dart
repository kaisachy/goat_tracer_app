// lib/screens/nav/cattle/widgets/detail_cattle_hero_section.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/photo_options_modal.dart';
import 'package:cattle_tracer_app/utils/cattle_detail_utils.dart';

class CattleHeroSection extends StatelessWidget {
  final Cattle cattle;
  final String? cattleImagePath;
  final Function(String?) onImageUpdate;

  const CattleHeroSection({
    super.key,
    required this.cattle,
    required this.cattleImagePath,
    required this.onImageUpdate,
  });

  void _showPhotoModal(BuildContext context) {
    PhotoOptionsModal.show(
      context: context,
      currentImagePath: cattleImagePath,
      onImageUpdate: onImageUpdate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.vibrantGreen.withValues(alpha: 0.05),
            blurRadius: 50,
            offset: const Offset(0, 20),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo Section
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: cattleImagePath != null
                ? Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Image.asset(
                    cattleImagePath!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: _buildFloatingButton(
                    icon: Icons.camera_alt,
                    onTap: () => _showPhotoModal(context),
                  ),
                ),
              ],
            )
                : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.lightGreen.withValues(alpha: 0.2),
                    AppColors.vibrantGreen.withValues(alpha: 0.1),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.lightGreen.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.cow,
                        size: 50,
                        color: AppColors.lightGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showPhotoModal(context),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadowColor: AppColors.darkGreen.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Info Section
          Padding(
            padding: const EdgeInsets.all(30),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cattle.name ?? 'Unnamed Cattle',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '#${cattle.tagNo}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: CattleDetailUtils.getStatusColor(cattle.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: CattleDetailUtils.getStatusColor(cattle.status).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    cattle.status.toUpperCase(),
                    style: TextStyle(
                      color: CattleDetailUtils.getStatusColor(cattle.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}