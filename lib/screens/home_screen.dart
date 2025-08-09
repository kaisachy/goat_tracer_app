import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../services/profile/personal_information_service.dart';
import '../services/secure_storage_service.dart';
import 'login_screen.dart';
import 'nav/cattle/cattle_screen.dart';
import 'nav/dashboard/dashboard_screen.dart';
import 'nav/profile/profile_screen.dart';
import 'nav/milk/milk_screen.dart';
import 'nav/schedule/schedule_screen.dart';
import 'nav/setting/setting_screen.dart';
import 'nav/event/event_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;

  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  late final List<Widget> _pages;

  // Profile data variables
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(),
      const CattleScreen(),
      EventScreen(),
      MilkScreen(),
      ScheduleScreen(),
      ProfileScreen(userEmail: widget.userEmail),
      SettingScreen(),
    ];
    _loadProfileData();
  }

  // Updated method to load profile data using PersonalInformationService
  Future<void> _loadProfileData() async {
    try {
      final profileData = await PersonalInformationService.getPersonalInformation();

      if (mounted) {
        setState(() {
          _profile = profileData;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // Method to refresh profile data (useful when profile is updated)
  Future<void> refreshProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    await _loadProfileData();
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    Navigator.of(context).pop();
    final navigator = Navigator.of(context);
    await SecureStorageService().deleteToken();
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Cattle';
      case 2:
        return 'Events';
      case 3:
        return 'Milk Production';
      case 4:
        return 'Schedule';
      case 5:
        return 'User Profile';
      case 6:
        return 'Settings';
      default:
        return 'Cattle Tracer';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  text: 'Dashboard',
                  index: 0,
                  onTap: () => _onNavItemTapped(0),
                ),
                _buildDrawerItem(
                  icon: FontAwesomeIcons.cow,
                  text: 'Cattle',
                  index: 1,
                  onTap: () => _onNavItemTapped(1),
                ),
                _buildDrawerItem(
                  icon: Icons.event_note_rounded,
                  text: 'Events',
                  index: 2,
                  onTap: () => _onNavItemTapped(2),
                ),
                _buildDrawerItem(
                  icon: Icons.opacity_rounded,
                  text: 'Milk Production',
                  index: 3,
                  onTap: () => _onNavItemTapped(3),
                ),
                _buildDrawerItem(
                  icon: Icons.schedule_rounded,
                  text: 'Schedule',
                  index: 4,
                  onTap: () => _onNavItemTapped(4),
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  text: 'Profile',
                  index: 5,
                  onTap: () => _onNavItemTapped(5),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  text: 'Settings',
                  index: 6,
                  onTap: () => _onNavItemTapped(6),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            text: 'Logout',
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(
        _isLoadingProfile
            ? 'Loading...'
            : _getDisplayName(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      accountEmail: Text(
        widget.userEmail,
        style: const TextStyle(color: Colors.white70),
      ),
      currentAccountPicture: _buildProfilePicture(),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
    );
  }

  String _getDisplayName() {
    if (_profile == null) return 'Unknown User';

    final firstName = _profile!['first_name']?.toString() ?? '';
    final lastName = _profile!['last_name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return 'Unknown User';
    }

    return '${firstName.trim()} ${lastName.trim()}'.trim();
  }

  Widget _buildProfilePicture() {
    if (_isLoadingProfile) {
      return const CircleAvatar(
        backgroundColor: AppColors.cardBackground,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    // Check if profile picture exists and is valid
    final profilePicture = _profile?['profile_picture'];

    if (profilePicture != null &&
        profilePicture is String &&
        profilePicture.isNotEmpty) {

      try {
        // Decode the base64 image
        final imageBytes = base64Decode(profilePicture);

        return CircleAvatar(
          backgroundColor: AppColors.cardBackground,
          backgroundImage: MemoryImage(imageBytes),
          onBackgroundImageError: (exception, stackTrace) {
            // Handle image loading error
            print('Error loading profile image: $exception');
          },
        );
      } catch (e) {
        print('Error decoding profile image: $e');
        // Fall through to default avatar
      }
    }

    // Default avatar when no profile picture is available
    return const CircleAvatar(
      backgroundColor: AppColors.cardBackground,
      child: FaIcon(
        FontAwesomeIcons.user,
        color: AppColors.primary,
        size: 35,
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    int? index,
  }) {
    final bool isSelected = index != null && index == _selectedIndex;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColors.accent.withOpacity(0.15),
    );
  }
}
