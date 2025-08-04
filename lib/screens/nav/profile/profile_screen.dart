// lib/screens/nav/profile/profile_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cattle_tracer_app/services/profile/personal_information_service.dart';
import 'package:cattle_tracer_app/services/profile/farm_details_service.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Import widgets
import 'package:cattle_tracer_app/screens/nav/profile/widgets/personal_information_widget.dart';
import 'package:cattle_tracer_app/screens/nav/profile/widgets/farm_details_widget.dart';
import 'package:cattle_tracer_app/screens/nav/profile/widgets/educational_background_widget.dart';
import 'package:cattle_tracer_app/screens/nav/profile/widgets/trainings_seminars_widget.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;

  const ProfileScreen({super.key, required this.userEmail});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> farmerProfileFuture;
  late Future<Map<String, dynamic>?> farmDetailsFuture;
  bool isEditingMode = false;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      farmerProfileFuture = PersonalInformationService.getPersonalInformation();
      farmDetailsFuture = FarmDetailsService.getFarmDetails();
    });
  }

  Future<void> _handleRefresh() async {
    _loadData();
    await Future.wait([farmerProfileFuture, farmDetailsFuture]);
  }

  void _toggleEditMode() async {
    if (isEditingMode) {
      bool saveSuccess = true;

      if (_imageFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading farmer-profile picture...')),
        );
        saveSuccess = await PersonalInformationService.updateProfilePicture(_imageFile!);
      }

      if (saveSuccess) {
        setState(() {
          isEditingMode = false;
          _imageFile = null;
        });
        _handleRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update picture. Please try again.')),
          );
        }
      }
    } else {
      setState(() {
        isEditingMode = true;
      });
    }
  }

  // --- IMAGE HELPER METHODS ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      } else {
        log('No image selected.');
      }
    } catch (e, stackTrace) {
      log('Failed to pick image: $e', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage() async {
    bool success = await PersonalInformationService.deleteProfilePicture();
    if (success) {
      setState(() {
        _imageFile = null;
      });
      _handleRefresh();
    }
  }

  void _showImageSourceActionSheet(BuildContext context, bool hasExistingPicture) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(ImageSource.camera);
                },
              ),
              if (hasExistingPicture || _imageFile != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red[700]),
                  title: Text('Delete Photo', style: TextStyle(color: Colors.red[700])),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Profile Header Widget
  Widget _buildProfileHeader(Map<String, dynamic>? profile, Map<String, dynamic>? farmDetails) {
    final primaryColor = AppColors.primary;
    final primaryWithOpacity = primaryColor.withOpacity(0.7);
    final white02 = const Color.fromRGBO(255, 255, 255, 0.2);
    final white01 = const Color.fromRGBO(255, 255, 255, 0.1);
    final white09 = const Color.fromRGBO(255, 255, 255, 0.9);

    final hasProfilePicture = profile?['profile_picture'] != null && profile!['profile_picture'].isNotEmpty;

    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(File(_imageFile!.path));
    } else if (hasProfilePicture) {
      backgroundImage = MemoryImage(base64Decode(profile['profile_picture']));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryWithOpacity],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header with edit button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile info with flexible space
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: white02,
                              backgroundImage: backgroundImage,
                              child: backgroundImage == null
                                  ? const Icon(Icons.person, size: 32, color: Colors.white)
                                  : null,
                            ),
                            if (isEditingMode)
                              Positioned(
                                bottom: 0,
                                right: -4,
                                child: GestureDetector(
                                  onTap: () => _showImageSourceActionSheet(context, hasProfilePicture),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile?['first_name'] ?? 'Unknown'} ${profile?['last_name'] ?? 'User'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                farmDetails?['farm_name'] ?? 'No Farm Name',
                                style: TextStyle(
                                  color: white09,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  Container(
                    decoration: BoxDecoration(
                      color: white02,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _toggleEditMode,
                      icon: Icon(
                        isEditingMode ? Icons.check : Icons.edit,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Quick info cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: white01,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: white02),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Address',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${profile?['barangay'] ?? 'N/A'}, ${profile?['municipality'] ?? 'N/A'}',
                            style: TextStyle(
                              color: white09,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: white01,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: white02),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.agriculture, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Farm Size',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${farmDetails?['farm_land_area'] ?? 'N/A'} hectares',
                            style: TextStyle(
                              color: white09,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = profileSnapshot.data;
                final farmDetails = farmSnapshot.data;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildProfileHeader(profile, farmDetails),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Section Cards using refactored widgets
                          PersonalInformationWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          const SizedBox(height: 16),
                          FarmDetailsWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          const SizedBox(height: 16),
                          EducationalBackgroundWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          const SizedBox(height: 16),
                          TrainingsSeminarsWidget(
                            isEditingMode: isEditingMode,
                            onRefresh: _handleRefresh,
                          ),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      // Edit mode indicator
      floatingActionButton: isEditingMode
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber[600],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Edit Mode Active',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}