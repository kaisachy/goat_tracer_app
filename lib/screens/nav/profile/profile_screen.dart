import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cattle_tracer_app/services/profile_service.dart';
import 'package:cattle_tracer_app/models/profile.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/profile/profile_widgets.dart';
import 'package:cattle_tracer_app/utils/sliver_tab_bar_delegate.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;

  const ProfileScreen({super.key, required this.userEmail});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>?> farmerProfileFuture;
  late Future<List<Map<String, dynamic>>> educationFuture;
  late Future<List<Map<String, dynamic>>> trainingFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      farmerProfileFuture = ProfileService.getFarmerProfile();
      educationFuture = ProfileService.getEducationalBackground();
      trainingFuture = ProfileService.getTrainingsAndSeminars();
    });
  }

  Future<void> _handleRefresh() async {
    _loadData();
    await Future.wait([farmerProfileFuture, educationFuture, trainingFuture]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildProfileTab(Map<String, dynamic>? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          InfoCard(
            title: 'Personal Information',
            icon: Icons.person_pin_circle_outlined,
            items: [
              InfoRow('Gender', profile?['gender']),
              InfoRow('Birthdate', profile?['birthdate']),
              InfoRow('Marital Status', profile?['marital_status']),
              InfoRow('Contact Number', profile?['contact_number']),
            ],
          ),
          const SizedBox(height: 20),
          InfoCard(
            title: 'Farm Information',
            icon: Icons.grass_outlined,
            items: [
              InfoRow('Farm Land Area', '${profile?['farm_land_area'] ?? 'None'}'),
              InfoRow('Cooperative Affiliation', profile?['cooperative_affiliation']),
            ],
          ),
          const SizedBox(height: 20),
          InfoCard(
            title: 'Address',
            icon: Icons.location_on_outlined,
            items: [
              InfoRow('Province', profile?['province']),
              InfoRow('Municipality', profile?['municipality']),
              InfoRow('Barangay', profile?['barangay']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducationTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: educationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProfileLoading();
        }
        if (snapshot.hasError) {
          return ProfileError(
            error: snapshot.error.toString(),
            onRetry: _handleRefresh,
          );
        }

        final educationList = snapshot.data ?? [];
        const levels = [
          'Elementary',
          'Secondary',
          'Vocational',
          'College',
          'Graduate Studies'
        ];

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: levels.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final level = levels[index];
            final eduMap = educationList.firstWhere(
                  (edu) => (edu['level'] as String?)?.toLowerCase() == level.toLowerCase(),
              orElse: () => {},
            );

            if (eduMap.isEmpty) {
              return InfoCard(
                title: level,
                icon: Icons.school_outlined,
                items: [
                  InfoRow('School', null),
                  InfoRow('Course', null),
                  InfoRow('Year Graduated', null),
                  InfoRow('Honors', null),
                ],
              );
            }

            final edu = EducationalBackground.fromJson(eduMap);
            return EducationItem(edu: edu);
          },
        );
      },
    );
  }

  Widget _buildTrainingTab() {
    return Stack(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: trainingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ProfileLoading();
            }
            if (snapshot.hasError) {
              return ProfileError(
                error: snapshot.error.toString(),
                onRetry: _handleRefresh,
              );
            }

            final trainingList = snapshot.data ?? [];

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: trainingList.isEmpty ? 1 : trainingList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (trainingList.isEmpty) {
                  return InfoCard(
                    title: 'Training & Seminar',
                    icon: Icons.star_border_purple500_outlined,
                    items: [
                      InfoRow('Conducted By', null),
                      InfoRow('Duration', null),
                      InfoRow('Location', null),
                      InfoRow('Certificate', null),
                    ],
                  );
                }

                final training = TrainingSeminar.fromJson(trainingList[index]);
                return TrainingItem(training: training);
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showAddTrainingModal,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white), // Child moved to end
          ),
        ),
      ],
    );
  }

  void _showAddTrainingModal() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final conductedByController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? dateFrom;
    DateTime? dateTo;
    bool certificateIssued = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                      const Text(
                        'Add Training & Seminar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: conductedByController,
                        decoration: const InputDecoration(labelText: 'Conducted By'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  modalSetState(() => dateFrom = picked);
                                }
                              },
                              child: Text(
                                dateFrom == null
                                    ? 'Date From'
                                    : 'From: ${dateFrom!.toLocal().toString().split(' ')[0]}', // Only date part
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  modalSetState(() => dateTo = picked);
                                }
                              },
                              child: Text(
                                dateTo == null
                                    ? 'Date To'
                                    : 'To: ${dateTo!.toLocal().toString().split(' ')[0]}', // Only date part
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
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            // TODO: Save to backend or state
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Training added (mock).')),
                            );
                          }
                        },
                        child: const Text('Submit'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: farmerProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ProfileLoading();
            }
            if (snapshot.hasError) {
              return ProfileError(
                error: snapshot.error.toString(),
                onRetry: _handleRefresh,
              );
            }

            final profile = snapshot.data;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 240.0,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    iconTheme: const IconThemeData(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      background: ProfileHeader(
                        profile: profile,
                        userEmail: widget.userEmail,
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.accent,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: AppColors.accent,
                        tabs: const [
                          Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
                          Tab(icon: Icon(Icons.school_outlined), text: 'Education'),
                          Tab(icon: Icon(Icons.star_outline), text: 'Training'),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(profile),
                  _buildEducationTab(),
                  _buildTrainingTab(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}