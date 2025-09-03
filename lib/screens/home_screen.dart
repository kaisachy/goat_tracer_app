// screens/home_screen.dart - Enhanced with Authentication
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../auth_guard.dart';
import '../constants/app_colors.dart';
import '../services/profile/personal_information_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'nav/cattle/cattle_screen.dart';
import 'nav/dashboard/dashboard_screen.dart';
import 'nav/profile/profile_screen.dart';
import 'nav/milk/milk_screen.dart';
import 'nav/event_schedule/event_schedule_screen.dart';
import 'nav/vaccination/vaccination_schedule_screen.dart';
import 'nav/setting/setting_screen.dart';
import 'nav/map/map_screen.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_status_service.dart';
import 'package:cattle_tracer_app/services/refresh_service.dart';

class HomeScreen extends StatefulWidget {
  final String? userEmail;
  final int? initialSelectedIndex;
  final int? initialEventScheduleTabIndex;

  const HomeScreen({super.key, this.userEmail, this.initialSelectedIndex, this.initialEventScheduleTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  late final List<Widget> _pages;

  // Profile data variables
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialSelectedIndex ?? 0;
    _initializePages();
    _loadProfileData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check authentication when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _checkAuthenticationStatus();
      _checkCattleStatusUpdates();
    }
  }

  void _initializePages() {
    _pages = [
      AuthGuard(child: MapScreen()),
      AuthGuard(child: DashboardScreen()),
      const AuthGuard(child: CattleScreen()),
      AuthGuard(child: EventScheduleScreen(initialTabIndex:  widget.initialEventScheduleTabIndex ?? 0)),
      AuthGuard(child: VaccinationScheduleScreen()),
      AuthGuard(child: MilkScreen()),
      AuthGuard(child: ProfileScreen(userEmail: widget.userEmail ?? '')),
      AuthGuard(child: SettingScreen()),
    ];
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        await AuthService.logout();
        _redirectToLogin();
      }
    } catch (e) {
      print('Authentication check failed: $e');
      // On error, assume authentication is compromised
      await AuthService.logout();
      _redirectToLogin();
    }
  }

  Future<void> _checkCattleStatusUpdates() async {
    try {
      // Check for cattle that need status updates (Breeding -> Healthy)
      final updatedCattle = await CattleStatusService.checkAndUpdateBreedingStatus();
      
      if (updatedCattle.isNotEmpty && mounted) {
        // Show a notification to the user about the status updates
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedCattle.length} cow(s) status automatically updated to Healthy'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error checking cattle status updates: $e');
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  // Updated method to load profile data using PersonalInformationService
  Future<void> _loadProfileData() async {
    try {
      // Check authentication before loading profile
      final token = await AuthService.getToken();
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final profileData = await PersonalInformationService.getPersonalInformation();

      if (mounted) {
        setState(() {
          _profile = profileData;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');

      // Check if error is authentication related
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('Token')) {
        await AuthService.logout();
        _redirectToLogin();
        return;
      }

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

  Future<void> _handleRefresh() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Refreshing all data...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 3),
        ),
      );

      // Perform comprehensive refresh for all data
      final refreshResults = await RefreshService.refreshAllData();
      
      // Dismiss loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show appropriate success message
      final message = RefreshService.getRefreshMessage(refreshResults);
      final hasErrors = refreshResults['errors'].isNotEmpty;
      final hasCattleUpdates = refreshResults['cattleStatusUpdates'].isNotEmpty;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: hasErrors ? Colors.orange[600] : 
                          hasCattleUpdates ? Colors.green[600] : AppColors.lightGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 4),
        ),
      );

      // Force refresh of the current page by triggering a rebuild
      setState(() {
        // This will trigger a rebuild of the current page
      });

    } catch (e) {
      // Dismiss loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing data: ${e.toString()}'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }



  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    // Show modern confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      Navigator.of(context).pop(); // Close drawer

      // Show modern loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Logging out...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we sign you out securely',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      try {
        await AuthService.logout();

        if (mounted) {
          // Close loading dialog and navigate to login
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Show modern error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Logout Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unable to logout at this time.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${e.toString()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All App Data',
            onPressed: _handleRefresh,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Map';
      case 1:
        return 'Dashboard';
      case 2:
        return 'My Cattle';
      case 3:
        return 'Events & Schedule';
      case 4:
        return 'Milk Production';
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
                  icon: Icons.map_rounded,
                  text: 'Map',
                  index: 0,
                  onTap: () => _onNavItemTapped(0),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  text: 'Dashboard',
                  index: 1,
                  onTap: () => _onNavItemTapped(1),
                ),
                _buildDrawerItem(
                  icon: FontAwesomeIcons.cow,
                  text: 'Cattle',
                  index: 2,
                  onTap: () => _onNavItemTapped(2),
                ),
                _buildDrawerItem(
                  icon: Icons.event_note_rounded,
                  text: 'Events & Schedule',
                  index: 3,
                  onTap: () => _onNavItemTapped(3),
                ),
                _buildDrawerItem(
                  icon: Icons.opacity_rounded,
                  text: 'Milk Production',
                  index: 4,
                  onTap: () => _onNavItemTapped(5),
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  text: 'Profile',
                  index: 5,
                  onTap: () => _onNavItemTapped(6),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  text: 'Settings',
                  index: 6,
                  onTap: () => _onNavItemTapped(7),
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
        widget.userEmail ?? '',
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