// lib/screens/nav/profile/profile_screen.dart
import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cattle_tracer_app/services/profile/personal_information_service.dart';
import 'package:cattle_tracer_app/services/profile/farm_details_service.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/profile/widgets/personal_information_widget.dart';
import 'package:cattle_tracer_app/screens/nav/profile/widgets/farm_details_widget.dart';
import 'package:cattle_tracer_app/screens/nav/profile/widgets/educational_background_widget.dart';
import 'package:cattle_tracer_app/screens/nav/profile/widgets/trainings_seminars_widget.dart';
import 'package:cattle_tracer_app/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;

  const ProfileScreen({super.key, required this.userEmail});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  Future<Map<String, dynamic>?> farmerProfileFuture = Future.value(null);
  Future<Map<String, dynamic>?> farmDetailsFuture = Future.value(null);
  bool isEditingMode = false;
  XFile? _imageFile;
  late AnimationController _editModeController;
  late AnimationController _headerController;
  late AnimationController _cardController;
  late Animation<double> _editModeAnimation;
  late Animation<double> _cardAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;
  String? _storedFirstName;
  String? _storedLastName;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeAnimations();
    _scrollController.addListener(_handleScroll);
  }

  void _initializeAnimations() {
    _editModeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _editModeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _editModeController, curve: Curves.elasticOut),
    );


    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutQuart),
    );

    // Start animations
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardController.forward();
    });
  }

  void _handleScroll() {
    const double threshold = 100.0;
    bool shouldCollapse = _scrollController.offset > threshold;

    if (shouldCollapse != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = shouldCollapse;
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _editModeController.dispose();
    _headerController.dispose();
    _cardController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() async {
    // Load stored user data as fallback
    _storedFirstName = await AuthService.getUserFirstName();
    _storedLastName = await AuthService.getUserLastName();
    
    log('🔍 ProfileScreen DEBUG: Loaded stored names - First: $_storedFirstName, Last: $_storedLastName');
    
    // Check if user is authenticated
    final isAuthenticated = await AuthService.isAuthenticated();
    log('🔍 ProfileScreen DEBUG: User authenticated: $isAuthenticated');
    
    setState(() {
      farmerProfileFuture = PersonalInformationService.getPersonalInformation();
      farmDetailsFuture = FarmDetailsService.getFarmDetails();
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    
    // Reload stored user data as fallback
    _storedFirstName = await AuthService.getUserFirstName();
    _storedLastName = await AuthService.getUserLastName();
    
    final newFarmerFuture = PersonalInformationService.getPersonalInformation();
    final newFarmFuture = FarmDetailsService.getFarmDetails();
    if (mounted) {
      setState(() {
        farmerProfileFuture = newFarmerFuture;
        farmDetailsFuture = newFarmFuture;
      });
    }
    await newFarmerFuture;
    await newFarmFuture;
  }

  void _toggleEditMode() async {
    HapticFeedback.mediumImpact();

    if (isEditingMode) {
      bool saveSuccess = true;

      if (_imageFile != null) {
        _showModernLoadingDialog('Uploading profile picture...');
        saveSuccess = await PersonalInformationService.updateProfilePicture(_imageFile!);
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (saveSuccess) {
        if (mounted) {
          setState(() {
            isEditingMode = false;
            _imageFile = null;
          });
        }
        _editModeController.reverse();
        await _handleRefresh();
        if (mounted) {
          _showModernSnackBar('Profile updated successfully!', isSuccess: true);
        }
      } else if (mounted) {
        _showModernSnackBar('Failed to update picture. Please try again.', isSuccess: false);
      }
    } else {
      if (mounted) {
        setState(() {
          isEditingMode = true;
        });
      }
      _editModeController.forward();
    }
  }

  void _showModernLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModernSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 20,
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _imageFile = pickedFile;
          });
        }
        if (mounted) {
          _showModernSnackBar('Image selected successfully!', isSuccess: true);
        }
      }
    } catch (e, stackTrace) {
      log('Failed to pick image: $e', stackTrace: stackTrace);
      if (mounted) {
        _showModernSnackBar('Failed to pick image: $e', isSuccess: false);
      }
    }
  }

  Future<void> _deleteImage() async {
    bool? confirmDelete = await _showModernConfirmationDialog(
      'Delete Profile Picture',
      'Are you sure you want to delete your profile picture?',
      'Delete',
      Colors.red,
    );

    if (confirmDelete == true) {
      bool success = await PersonalInformationService.deleteProfilePicture();
      if (success) {
        if (mounted) {
          setState(() {
            _imageFile = null;
          });
        }
        await _handleRefresh();
        if (mounted) {
          _showModernSnackBar('Profile picture deleted successfully!', isSuccess: true);
        }
      } else if (mounted) {
        _showModernSnackBar('Failed to delete profile picture.', isSuccess: false);
      }
    }
  }

  Future<bool?> _showModernConfirmationDialog(
      String title, String content, String actionText, Color actionColor) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: actionColor, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          actionText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModernImagePicker(BuildContext context, bool hasExistingPicture) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update Profile Picture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildModernImageOption(
                    icon: Icons.photo_library_outlined,
                    title: 'Photo Library',
                    subtitle: 'Choose from your photos',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _pickImage(ImageSource.gallery);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildModernImageOption(
                    icon: Icons.camera_alt_outlined,
                    title: 'Camera',
                    subtitle: 'Take a new photo',
                    color: Colors.green,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _pickImage(ImageSource.camera);
                    },
                  ),
                  if (hasExistingPicture || _imageFile != null) ...[
                    const SizedBox(height: 16),
                    _buildModernImageOption(
                      icon: Icons.delete_outline,
                      title: 'Delete Photo',
                      subtitle: 'Remove current picture',
                      color: Colors.red,
                      onTap: () {
                        Navigator.of(context).pop();
                        _deleteImage();
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader(
      Map<String, dynamic>? profile, Map<String, dynamic>? farmDetails, {String? firstName, String? lastName}) {
    final hasProfilePicture =
        profile?['profile_picture'] != null && profile!['profile_picture'].isNotEmpty;

    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(File(_imageFile!.path));
    } else if (hasProfilePicture) {
      backgroundImage = MemoryImage(base64Decode(profile['profile_picture']));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      // Header Section with Edit Button
      Stack(
      children: [
      Row(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture Section
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: backgroundImage,
                      child: backgroundImage == null
                          ? Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: Colors.grey.shade400,
                      )
                          : null,
                    ),
                  ),
                  if (isEditingMode)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showModernImagePicker(context, hasProfilePicture),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Profile Info Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 50), // Add padding to prevent overlap with edit button
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    '${firstName ?? profile?['first_name'] ?? _storedFirstName ?? 'Unknown'} ${lastName ?? profile?['last_name'] ?? _storedLastName ?? 'User'}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // Farm Classification Badge (hidden if null/empty)
                ((farmDetails?['farm_classification']?.toString().isNotEmpty ?? false)
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.agriculture_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                farmDetails!['farm_classification'].toString(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ],
      ),

      // Edit Button in Top Right
      Positioned(
        top: 0,
        right: 0,
      child: GestureDetector(
      onTap: _toggleEditMode,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEditingMode ? Colors.green : AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isEditingMode ? Icons.check_rounded : Icons.edit_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    ),
    ],
    ),

    const SizedBox(height: 24),

    // Information Cards Section
    Row(
    children: [
    Expanded(
    child: _buildInfoCard(
    icon: Icons.location_on_outlined,
    iconColor: Colors.green,
    title: 'Farm Location',
    value: _formatFarmLocation(farmDetails),
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: _buildInfoCard(
    icon: Icons.landscape_outlined,
    iconColor: Colors.green,
    title: 'Farm Size',
    value: _formatFarmSize(farmDetails),
    ),
    ),
    ],
    ),
    ],
    ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatFarmLocation(Map<String, dynamic>? farmDetails) {
    if (farmDetails == null) {
      return 'Location not specified';
    }
    // Support both new structured fields and legacy key just in case
    final barangay = farmDetails['farm_barangay']?.toString() ?? '';
    // Handle possible typo key 'farm_municipalit' as well as correct 'farm_municipality'
    final municipality = (farmDetails['farm_municipality'] ?? farmDetails['farm_municipalit'])?.toString() ?? '';
    final province = farmDetails['farm_province']?.toString() ?? '';

    final parts = <String>[];
    if (barangay.isNotEmpty) parts.add(barangay);
    if (municipality.isNotEmpty) parts.add(municipality);
    if (province.isNotEmpty) parts.add(province);

    if (parts.isEmpty) {
      // Fallback to legacy single field if still present
      final legacy = farmDetails['farm_location']?.toString();
      return (legacy == null || legacy.isEmpty) ? 'Location not specified' : legacy;
    }
    return parts.join(', ');
  }

  String _formatFarmSize(Map<String, dynamic>? farmDetails) {
    final farmSize = farmDetails?['farm_land_area'];
    if (farmSize == null || farmSize.toString().isEmpty) {
      return 'Size not specified';
    }
    return farmSize.toString();
  }



  Widget _buildModernSectionCard(Widget child, int index) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, _) {
        final delay = index * 0.1;
        final animationValue = Curves.easeOutQuart.transform(
          (_cardAnimation.value - delay).clamp(0.0, 1.0) / (1.0 - delay),
        );

        // Clamp the opacity value
        final clampedOpacity = animationValue.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: clampedOpacity,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: farmerProfileFuture,
          builder: (context, profileSnapshot) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: farmDetailsFuture,
              builder: (context, farmSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting ||
                    farmSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Loading your profile...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final profile = profileSnapshot.data;
                final farmDetails = farmSnapshot.data;
                
                // Debug logging
                log('Profile data: $profile');
                log('Farm details data: $farmDetails');
                log('Stored first name: $_storedFirstName');
                log('Stored last name: $_storedLastName');
                
                // Check if we have any name data
                final firstName = profile?['first_name'] ?? _storedFirstName ?? 'Unknown';
                final lastName = profile?['last_name'] ?? _storedLastName ?? 'User';
                log('Final name display: $firstName $lastName');

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildModernProfileHeader(profile, farmDetails, firstName: firstName, lastName: lastName),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 8),
                        _buildModernSectionCard(
                          PersonalInformationWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          0,
                        ),
                        _buildModernSectionCard(
                          FarmDetailsWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          1,
                        ),
                        _buildModernSectionCard(
                          EducationalBackgroundWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          2,
                        ),
                        _buildModernSectionCard(
                          TrainingsSeminarsWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          3,
                        ),
                        const SizedBox(height: 100), // Extra space for floating elements
                      ]),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      // Enhanced floating edit mode indicator
      floatingActionButton: AnimatedBuilder(
        animation: _editModeAnimation,
        builder: (context, child) {
          // Clamp the animation value
          final clampedValue = _editModeAnimation.value.clamp(0.0, 1.0);

          return isEditingMode
              ? SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _editModeController,
              curve: Curves.elasticOut,
            )),
            child: Transform.scale(
              scale: clampedValue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.amber[400],
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Mode Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              : const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}