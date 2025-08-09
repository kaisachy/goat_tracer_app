import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/photo_options_modal.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/details/detail_cattle_info_cards.dart';
import 'package:cattle_tracer_app/utils/cattle_detail_utils.dart';

class CattleDetailsTabContent extends StatelessWidget {
  final Cattle cattle;
  final String? cattleImagePath;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;
  final Function(String?) onImageUpdate;
  final bool isUpdatingImage;

  const CattleDetailsTabContent({
    super.key,
    required this.cattle,
    this.cattleImagePath,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
    required this.onImageUpdate,
    this.isUpdatingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lightGreen.withValues(alpha: 0.02),
            Colors.white,
            AppColors.vibrantGreen.withValues(alpha: 0.01),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Hero Section with loading overlay
                  Stack(
                    children: [
                      _buildEnhancedHeroSection(context),
                      if (isUpdatingImage) _buildHeroLoadingOverlay(),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Enhanced Content Section
                  _buildContentSection(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.black.withValues(alpha: 0.6),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkGreen),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Updating Photo...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Please wait while we save your changes',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      children: [
        // Animated cards with staggered animation
        _buildAnimatedCard(
          delay: 100,
          child: CattleBasicInfoCard(cattle: cattle),
        ),

        const SizedBox(height: 20),

        _buildAnimatedCard(
          delay: 200,
          child: CattleLineageCard(cattle: cattle),
        ),

        const SizedBox(height: 20),

        _buildAnimatedCard(
          delay: 300,
          child: CattleManagementCard(cattle: cattle),
        ),

        const SizedBox(height: 20),

        _buildAnimatedCard(
          delay: 400,
          child: CattleNotesSection(cattle: cattle),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard({
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: _buildEnhancedCardWrapper(child),
    );
  }

  Widget _buildEnhancedCardWrapper(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.lightGreen.withValues(alpha: 0.02),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.lightGreen.withValues(alpha: 0.005),
              ],
            ),
            border: Border.all(
              color: AppColors.lightGreen.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEnhancedHeroSection(BuildContext context) {
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
            child: _hasValidImage()
                ? Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: _buildImageWidget(),
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
                  flex: 3,
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                            Flexible(
                              child: Text(
                                '#${cattle.tagNo}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 2,
                  child: Text(
                    cattle.status.toUpperCase(),
                    style: TextStyle(
                      color: CattleDetailUtils.getStatusColor(cattle.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: null,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValidImage() {
    // Check if cattle has a valid picture
    return cattle.hasPicture ||
        (cattleImagePath != null && cattleImagePath!.isNotEmpty);
  }

  Widget _buildImageWidget() {
    try {
      // Priority 1: Check cattle.imageBytes (from the model's getter)
      final imageBytes = cattle.imageBytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        debugPrint('Loading image from cattle.imageBytes');
        return Image.memory(
          imageBytes,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading from imageBytes: $error');
            return _buildErrorPlaceholder();
          },
        );
      }

      // Priority 2: Check cattle.cattlePicture directly
      if (cattle.cattlePicture != null && cattle.cattlePicture!.isNotEmpty) {
        debugPrint('Loading image from cattle.cattlePicture');
        return _buildImageFromBase64(cattle.cattlePicture!);
      }

      // Priority 3: Check cattleImagePath parameter (fallback)
      if (cattleImagePath != null && cattleImagePath!.isNotEmpty) {
        debugPrint('Loading image from cattleImagePath parameter');
        return _buildImageFromBase64(cattleImagePath!);
      }

      debugPrint('No valid image source found');
      return _buildErrorPlaceholder();
    } catch (e) {
      debugPrint('Error in _buildImageWidget: $e');
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      // Handle data URI prefix if present
      final cleanBase64 = base64String.startsWith('data:image')
          ? base64String.split(',')[1]
          : base64String;

      final bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading base64 image: $error');
          return _buildErrorPlaceholder();
        },
      );
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightGreen.withValues(alpha: 0.2),
            AppColors.vibrantGreen.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Image Error',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoModal(BuildContext context) {
    PhotoOptionsModal.show(
      context: context,
      currentImagePath: cattle.cattlePicture ?? cattleImagePath,
      onImageUpdate: onImageUpdate,
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