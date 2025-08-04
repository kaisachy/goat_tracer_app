import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cattle_tracer_app/services/profile_service.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;

  const ProfileScreen({super.key, required this.userEmail});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> farmerProfileFuture;
  late Future<Map<String, dynamic>?> farmDetailsFuture;
  late Future<List<Map<String, dynamic>>> educationFuture;
  late Future<List<Map<String, dynamic>>> trainingFuture;
  bool isEditingMode = false;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      farmerProfileFuture = ProfileService.getFarmerProfile();
      farmDetailsFuture = ProfileService.getFarmDetails();
      educationFuture = ProfileService.getEducationalBackground();
      trainingFuture = ProfileService.getTrainingsAndSeminars();
    });
  }

  Future<void> _handleRefresh() async {
    _loadData();
    await Future.wait([farmerProfileFuture, farmDetailsFuture, educationFuture, trainingFuture]);
  }

  void _toggleEditMode() async {
    if (isEditingMode) {
      bool saveSuccess = true;

      if (_imageFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading farmer-profile picture...')),
        );
        saveSuccess = await ProfileService.updateProfilePicture(_imageFile!);
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
    bool success = await ProfileService.deleteProfilePicture();
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
                onTap: () async { // <-- Make the function async
                  Navigator.of(context).pop(); // <-- Pop the sheet FIRST
                  await _pickImage(ImageSource.gallery); // <-- THEN await the picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async { // <-- Make the function async
                  Navigator.of(context).pop(); // <-- Pop the sheet FIRST
                  await _pickImage(ImageSource.camera); // <-- THEN await the picker
                },
              ),
              if (hasExistingPicture || _imageFile != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red[700]),
                  title: Text('Delete Photo', style: TextStyle(color: Colors.red[700])),
                  onTap: () { // This can stay synchronous
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

  // Dashboard Section Card Widget
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? count,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Profile Header Widget
  Widget _buildProfileHeader(Map<String, dynamic>? profile, Map<String, dynamic>? farmDetails) {
    final primaryColor = AppColors.primary;
    final primaryWithOpacity = primaryColor.withOpacity(0.7); // Simplified color calculation
    final white02 = const Color.fromRGBO(255, 255, 255, 0.2);
    final white01 = const Color.fromRGBO(255, 255, 255, 0.1);
    final white09 = const Color.fromRGBO(255, 255, 255, 0.9);

    final hasProfilePicture = profile?['profile_picture'] != null && profile!['profile_picture'].isNotEmpty;

    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(File(_imageFile!.path));
    } else if (hasProfilePicture) {
      // Assuming the BLOB is sent as a Base64 encoded string
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
                crossAxisAlignment: CrossAxisAlignment.start, // Use start alignment
                children: [
                  // Profile info with flexible space
                  Expanded(
                    child: Row(
                      children: [
                        Stack( // Wrap with a Stack
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

  // Modal methods
  void _showPersonalInfoModal(Map<String, dynamic>? profile) {
    _showProfileModal(context, profile, section: 'personal');
  }

  void _showFarmInfoModal(Map<String, dynamic>? farmDetails) {
    _showProfileModal(context, farmDetails, section: 'farm');
  }

  void _showEducationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildEducationBottomSheet(),
    );
  }

  void _showTrainingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTrainingBottomSheet(),
    );
  }

  // Education bottom sheet
  Widget _buildEducationBottomSheet() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: educationFuture,
      builder: (context, snapshot) {
        final educationList = snapshot.data ?? [];
        const levels = ['Elementary', 'Secondary', 'Vocational', 'College', 'Graduate'];

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Educational Background',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (isEditingMode)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    final eduMap = educationList.firstWhere(
                          (edu) => (edu['level'] as String?)?.toLowerCase() == level.toLowerCase(),
                      orElse: () => {},
                    );

                    // Handle year display properly
                    String? yearDisplay;
                    if (eduMap.isNotEmpty && eduMap['year_graduated'] != null) {
                      final year = eduMap['year_graduated'].toString();
                      if (year.isNotEmpty && year != '0' && year != '0000') {
                        yearDisplay = 'Graduated: $year';
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[600],
                          child: const Icon(Icons.school, color: Colors.white),
                        ),
                        title: Text(level, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: eduMap.isNotEmpty
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eduMap['school_name'] ?? 'N/A'),
                            if (yearDisplay != null) Text(yearDisplay),
                          ],
                        )
                            : const Text(''),
                        trailing: isEditingMode
                            ? IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEducationFormBottomSheet(level: level, eduMap: eduMap);
                          },
                        )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Training bottom sheet
  Widget _buildTrainingBottomSheet() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: trainingFuture,
      builder: (context, snapshot) {
        // Wrap in StatefulBuilder for local state management
        return StatefulBuilder(
          builder: (context, setLocalState) {
            // Use local copy of training list that we can modify
            List<Map<String, dynamic>> trainingList = snapshot.data ?? [];

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trainings & Seminars',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          if (isEditingMode)
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showTrainingFormModal();
                              },
                              icon: const Icon(Icons.add),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: trainingList.isEmpty
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No trainings added yet'),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: trainingList.length,
                      itemBuilder: (context, index) {
                        final training = trainingList[index];
                        final certificateIssued = training['certificate_issued'] == true ||
                            training['certificate_issued'] == 1;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[600],
                              child: const Icon(Icons.workspace_premium, color: Colors.white),
                            ),
                            title: Text(
                              training['title'] ?? 'No Title',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(training['conducted_by'] ?? 'N/A'),
                                Text(training['location'] ?? 'N/A'),
                                if (certificateIssued)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, size: 12, color: Colors.green[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Certified',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isEditingMode
                                ? SizedBox(
                              width: 96,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showTrainingFormModal(trainingMap: training);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Confirm Deletion'),
                                          content: const Text('Are you sure you want to delete this training/seminar?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        final success = await ProfileService.deleteTrainingsAndSeminars(training['id']);
                                        if (context.mounted) {
                                          if (success) {
                                            // UPDATE LOCAL STATE - Remove item immediately
                                            setLocalState(() {
                                              trainingList.removeAt(index);
                                            });

                                            // Refresh parent data
                                            _handleRefresh();

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Training deleted successfully!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed to delete training.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTrainingFormModal({Map<String, dynamic>? trainingMap}) {
    _showTrainingFormBottomSheet(trainingMap: trainingMap, onSaveSuccess: _handleRefresh);
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
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: educationFuture,
                  builder: (context, educationSnapshot) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: trainingFuture,
                      builder: (context, trainingSnapshot) {
                        if (profileSnapshot.connectionState == ConnectionState.waiting ||
                            farmSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final profile = profileSnapshot.data;
                        final farmDetails = farmSnapshot.data;
                        final trainingList = trainingSnapshot.data ?? [];

                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildProfileHeader(profile, farmDetails),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.all(20),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  // Section Cards
                                  _buildSectionCard(
                                    icon: Icons.person,
                                    title: 'Personal Information',
                                    subtitle: 'Basic details and contact info',
                                    color: Colors.blue[600]!,
                                    onTap: () => _showPersonalInfoModal(profile),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSectionCard(
                                    icon: Icons.agriculture,
                                    title: 'Farm Details',
                                    subtitle: 'Farm information and classification',
                                    color: Colors.green[600]!,
                                    onTap: () => _showFarmInfoModal(farmDetails),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSectionCard(
                                    icon: Icons.school,
                                    title: 'Educational Background',
                                    subtitle: 'Academic achievements',
                                    color: Colors.purple[600]!,
                                    onTap: _showEducationModal,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSectionCard(
                                    icon: Icons.workspace_premium,
                                    title: 'Trainings & Seminars',
                                    subtitle: 'Professional development',
                                    color: Colors.orange[600]!,
                                    count: '${trainingList.length} items',
                                    onTap: _showTrainingModal,
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

  // Profile Modal
  void _showProfileModal(BuildContext context, Map<String, dynamic>? profile,
      {required String section}) {
    final formKey = GlobalKey<FormState>();

    final genderController = TextEditingController(text: profile?['gender'] ?? '');
    final birthdateController = TextEditingController(text: profile?['birthdate'] ?? '');
    final statusController = TextEditingController(text: profile?['marital_status'] ?? '');
    final contactController = TextEditingController(text: profile?['contact_number'] ?? '');
    final provinceController = TextEditingController(text: profile?['province'] ?? '');
    final muniController = TextEditingController(text: profile?['municipality'] ?? '');
    final brgyController = TextEditingController(text: profile?['barangay'] ?? '');

    final farmNameController = TextEditingController(text: profile?['farm_name'] ?? '');
    final farmTypeController = TextEditingController(text: profile?['farm_type'] ?? '');
    final farmClassificationController = TextEditingController(text: profile?['farm_classification'] ?? '');
    final farmAreaController = TextEditingController(text: profile?['farm_land_area']?.toString() ?? '');
    final coopController = TextEditingController(text: profile?['cooperative_affiliation'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit ${section[0].toUpperCase()}${section.substring(1)} Information',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Personal + Address Section
                  if (section == 'personal') ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Personal Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: genderController,
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                    TextFormField(
                      controller: birthdateController,
                      decoration: const InputDecoration(labelText: 'Birthdate'),
                    ),
                    TextFormField(
                      controller: statusController,
                      decoration: const InputDecoration(labelText: 'Marital Status'),
                    ),
                    TextFormField(
                      controller: contactController,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Address',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: provinceController,
                      decoration: const InputDecoration(labelText: 'Province'),
                    ),
                    TextFormField(
                      controller: muniController,
                      decoration: const InputDecoration(labelText: 'Municipality'),
                    ),
                    TextFormField(
                      controller: brgyController,
                      decoration: const InputDecoration(labelText: 'Barangay'),
                    ),
                  ],

                  // Farm Section
                  if (section == 'farm') ...[
                    TextFormField(
                      controller: farmNameController,
                      decoration: const InputDecoration(labelText: 'Farm Name'),
                    ),
                    TextFormField(
                      controller: farmTypeController,
                      decoration: const InputDecoration(labelText: 'Farm Type'),
                    ),
                    TextFormField(
                      controller: farmClassificationController,
                      decoration: const InputDecoration(labelText: 'Farm Classification'),
                    ),
                    TextFormField(
                      controller: farmAreaController,
                      decoration: const InputDecoration(labelText: 'Farm Land Area'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: coopController,
                      decoration: const InputDecoration(labelText: 'Cooperative Affiliation'),
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final Map<String, dynamic> updateData = {};
                        bool success = false;

                        if (section == 'personal') {
                          updateData.addAll({
                            'gender': genderController.text,
                            'birthdate': birthdateController.text,
                            'marital_status': statusController.text,
                            'contact_number': contactController.text,
                            'province': provinceController.text,
                            'municipality': muniController.text,
                            'barangay': brgyController.text,
                          });

                          if (profile?['id'] == null) {
                            success = await ProfileService.storeFarmerProfile(updateData);
                          } else {
                            success = await ProfileService.updateFarmerProfile(updateData);
                          }
                        } else if (section == 'farm') {
                          updateData.addAll({
                            'farm_name': farmNameController.text,
                            'farm_type': farmTypeController.text,
                            'farm_classification': farmClassificationController.text,
                            'farm_land_area': farmAreaController.text,
                            'cooperative_affiliation': coopController.text,
                          });

                          if (profile?['id'] == null) {
                            success = await ProfileService.storeFarmDetails(updateData);
                          } else {
                            success = await ProfileService.updateFarmDetails(updateData);
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Profile saved successfully!'
                                  : 'Save failed. Please try again.'),
                            ),
                          );
                          if (success) _handleRefresh();
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Education Form Bottom Sheet
  void _showEducationFormBottomSheet({
    required String level,
    Map<String, dynamic>? eduMap,
  }) {
    final formKey = GlobalKey<FormState>();

    final schoolController = TextEditingController(text: eduMap?['school_name'] ?? '');
    final courseController = TextEditingController(text: eduMap?['course'] ?? '');

    // Handle year properly - don't show 0000 for empty years
    final yearController = TextEditingController(
      text: (eduMap?['year_graduated'] != null &&
          eduMap!['year_graduated'].toString() != '0' &&
          eduMap['year_graduated'].toString() != '0000')
          ? eduMap['year_graduated'].toString()
          : '',
    );

    final honorsController = TextEditingController(text: eduMap?['honors_received'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit $level Education',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: schoolController,
                    decoration: const InputDecoration(labelText: 'School'),
                  ),
                  TextFormField(
                    controller: courseController,
                    decoration: const InputDecoration(labelText: 'Course'),
                  ),
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: 'Year Graduated'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null) return 'Enter a valid year';
                        if (year < 1900 || year > DateTime.now().year + 5) {
                          return 'Enter a valid year between 1900-${DateTime.now().year + 5}';
                        }
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: honorsController,
                    decoration: const InputDecoration(labelText: 'Honors'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        // Check if all fields are empty
                        final allFieldsEmpty = schoolController.text.isEmpty &&
                            courseController.text.isEmpty &&
                            yearController.text.isEmpty &&
                            honorsController.text.isEmpty;

                        // Don't save if all fields are empty
                        if (allFieldsEmpty) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No data to save.'),
                              ),
                            );
                          }
                          return;
                        }

                        // Prepare data - only include year if it's valid and non-zero
                        final Map<String, dynamic> updateData = {
                          'level': level,
                          'school_name': schoolController.text,
                          'course': courseController.text,
                          'honors_received': honorsController.text,
                        };

                        // Add year only if it's non-empty and valid
                        if (yearController.text.isNotEmpty) {
                          final year = int.tryParse(yearController.text);
                          if (year != null && year > 0) {
                            updateData['year_graduated'] = year.toString();
                          }
                        }

                        bool success;
                        if (eduMap?['id'] == null) {
                          success = await ProfileService.storeEducationalBackground(updateData);
                        } else {
                          updateData['id'] = eduMap!['id'];
                          success = await ProfileService.updateEducationalBackground(updateData);
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Education saved successfully!'
                                  : 'Save failed. Please try again.'),
                            ),
                          );
                          if (success) _handleRefresh();
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Training Form Bottom Sheet
  void _showTrainingFormBottomSheet({
    Map<String, dynamic>? trainingMap,
    VoidCallback? onSaveSuccess,
  }) {
    final bool isEditing = trainingMap != null;

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: trainingMap?['title'] ?? '');
    final conductedByController = TextEditingController(text: trainingMap?['conducted_by'] ?? '');
    final locationController = TextEditingController(text: trainingMap?['location'] ?? '');

    DateTime? dateFrom = DateTime.tryParse(trainingMap?['date_from'] ?? '');
    DateTime? dateTo = DateTime.tryParse(trainingMap?['date_to'] ?? '');

    bool certificateIssued = false;
    if (isEditing) {
      final certificateValue = trainingMap['certificate_issued'];
      if (certificateValue is bool) {
        certificateIssued = certificateValue;
      } else if (certificateValue is int) {
        certificateIssued = certificateValue == 1;
      } else if (certificateValue is String) {
        certificateIssued = ['true', '1', 'yes', 'issued'].contains(certificateValue.toLowerCase());
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Edit Training & Seminar' : 'Add Training & Seminar',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                      ),
                      TextFormField(
                        controller: conductedByController,
                        decoration: const InputDecoration(labelText: 'Conducted By'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dateFrom ?? DateTime.now(),
                                  firstDate: DateTime(1980),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  modalSetState(() => dateFrom = picked);
                                }
                              },
                              label: Text(
                                dateFrom == null
                                    ? 'Date From'
                                    : dateFrom!.toLocal().toString().split(' ')[0],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dateTo ?? dateFrom ?? DateTime.now(),
                                  firstDate: dateFrom ?? DateTime(1980),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  modalSetState(() => dateTo = picked);
                                }
                              },
                              label: Text(
                                dateTo == null
                                    ? 'Date To'
                                    : dateTo!.toLocal().toString().split(' ')[0],
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Location'),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: certificateIssued,
                            onChanged: (val) {
                              modalSetState(() {
                                certificateIssued = val ?? false;
                              });
                            },
                          ),
                          const Text('Certificate Issued'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final data = {
                              'title': titleController.text,
                              'conducted_by': conductedByController.text.trim().isNotEmpty ? conductedByController.text.trim() : null,
                              'location': locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
                              'date_from': dateFrom?.toIso8601String().split('T')[0],
                              'date_to': dateTo?.toIso8601String().split('T')[0],
                              'certificate_issued': certificateIssued ? 1 : 0,
                            };

                            bool success = false;
                            if (isEditing) {
                              data['id'] = trainingMap['id'];
                              success = await ProfileService.updateTrainingsAndSeminars(data);
                            } else {
                              success = await ProfileService.storeTrainingsAndSeminars(data);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Training saved successfully!'
                                      : 'Failed to save training.'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                              if (success) {
                                onSaveSuccess?.call();
                              }
                            }
                          }
                        },
                        child: Text(isEditing ? 'Save Changes' : 'Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}