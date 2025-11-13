// lib/screens/nav/cattle/modals/photo_options_modal.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoOptionsModal {
  static void show({
    required BuildContext context,
    required String? currentImagePath,
    required Function(String?) onImageUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PhotoOptionsContent(
        currentImagePath: currentImagePath,
        onImageUpdate: onImageUpdate,
      ),
    );
  }
}

class _PhotoOptionsContent extends StatelessWidget {
  final String? currentImagePath;
  final Function(String?) onImageUpdate;
  final ImagePicker _picker = ImagePicker();

  _PhotoOptionsContent({
    required this.currentImagePath,
    required this.onImageUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Update Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              // Photo Library Option
              _buildModernImageOption(
                context: context,
                icon: Icons.photo_library_outlined,
                title: 'Photo Library',
                subtitle: 'Choose from your photos',
                color: Colors.blue,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _selectFromGallery(context);
                },
              ),
              const SizedBox(height: 16),

              // Camera Option
              _buildModernImageOption(
                context: context,
                icon: Icons.camera_alt_outlined,
                title: 'Camera',
                subtitle: 'Take a new photo',
                color: Colors.green,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _takePhoto(context);
                },
              ),

              // Delete Option (if photo exists)
              if (currentImagePath != null) ...[
                const SizedBox(height: 16),
                _buildModernImageOption(
                  context: context,
                  icon: Icons.delete_outline,
                  title: 'Delete Photo',
                  subtitle: 'Remove current picture',
                  color: Colors.red,
                  onTap: () {
                    Navigator.of(context).pop();
                    _deletePhoto(context);
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernImageOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final String base64String = await _convertImageToBase64(image);
        onImageUpdate(base64String);

        if (context.mounted) {
          _showModernSnackBar(
            context,
            'Photo selected successfully!',
            Icons.photo_library_outlined,
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showModernSnackBar(
          context,
          'Failed to select photo',
          Icons.error_outline,
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final String base64String = await _convertImageToBase64(image);
        onImageUpdate(base64String);

        if (context.mounted) {
          _showModernSnackBar(
            context,
            'Photo captured successfully!',
            Icons.camera_alt_outlined,
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showModernSnackBar(
          context,
          'Failed to capture photo',
          Icons.error_outline,
          isSuccess: false,
        );
      }
    }
  }

  Future<String> _convertImageToBase64(XFile image) async {
    final File imageFile = File(image.path);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  void _deletePhoto(BuildContext context) {
    onImageUpdate(null);
    _showModernSnackBar(
      context,
      'Photo removed successfully!',
      Icons.delete_outline,
      isSuccess: true,
    );
  }

  void _showModernSnackBar(
      BuildContext context,
      String message,
      IconData icon, {
        required bool isSuccess,
      }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
