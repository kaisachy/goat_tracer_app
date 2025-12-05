// screens/home_screen.dart - Enhanced with Authentication
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../auth_guard.dart';
import '../constants/app_colors.dart';
import '../services/profile/personal_information_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'nav/goat/goat_screen.dart';
import 'nav/dashboard/dashboard_screen.dart';
import 'nav/profile/profile_screen.dart';
import 'nav/milk/milk_screen.dart';
import 'nav/history/history_screen.dart';
import 'nav/scheduler/farmer_scheduler_screen.dart';
import 'nav/messages/messages_screen.dart';
import 'nav/setting/setting_screen.dart';
import 'package:goat_tracer_app/services/goat/goat_status_service.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/services/refresh_service.dart';

class HomeScreen extends StatefulWidget {
  final String? userEmail;
  final int? initialSelectedIndex;
  const HomeScreen({super.key, this.userEmail, this.initialSelectedIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();
  final GlobalKey<GoatScreenState> _goatKey = GlobalKey<GoatScreenState>();
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();
  final GlobalKey<FarmerSchedulerScreenState> _schedulerKey =
      GlobalKey<FarmerSchedulerScreenState>();
  final GlobalKey<SettingScreenState> _settingKey = GlobalKey<SettingScreenState>();
  final GlobalKey<MessagesScreenState> _messagesKey = GlobalKey<MessagesScreenState>();

  int _selectedIndex = 0;
  late final List<Widget> _pages;

  // Profile data variables
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialSelectedIndex ?? 2; // Default to Dashboard
    _userEmail = widget.userEmail;
    _initializePages();
    _loadProfileData();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    // If email is not provided, fetch it from token
    if (_userEmail == null || _userEmail!.isEmpty) {
      try {
        final email = await AuthService.getCurrentUserEmail();
        if (mounted) {
          setState(() {
            _userEmail = email ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading user email: $e');
      }
    }
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
      _checkgoatStatusUpdates();
      // Refresh profile data when app resumes
      _loadProfileData();
      // Refresh user email when app resumes
      _loadUserEmail();
    }
  }

  void _initializePages() {
    _pages = [
      AuthGuard(child: ProfileScreen(key: _profileKey, userEmail: widget.userEmail ?? '')),
      AuthGuard(child: GoatScreen(key: _goatKey)),
      AuthGuard(child: DashboardScreen(key: _dashboardKey)),
      AuthGuard(child: HistoryScreen(key: _historyKey)),
      AuthGuard(child: FarmerSchedulerScreen(key: _schedulerKey)),
      AuthGuard(child: MilkScreen()),
      AuthGuard(child: MessagesScreen(key: _messagesKey)),
      AuthGuard(child: SettingScreen(key: _settingKey)),
    ];
  }
  
  void _startDashboardUserGuide() {
    if (_dashboardKey.currentState != null) {
      _dashboardKey.currentState!.startUserGuide();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the dashboard to load, then try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _startProfileUserGuide() {
    if (_profileKey.currentState != null) {
      _profileKey.currentState!.startUserGuide();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the profile to load, then try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startGoatUserGuide() {
    if (_goatKey.currentState != null) {
      _goatKey.currentState!.startUserGuide();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the goat screen to load, then try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startHistoryUserGuide() {
    if (_historyKey.currentState != null) {
      _historyKey.currentState!.startUserGuide();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the history screen to load, then try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startSchedulerUserGuide() {
    if (_schedulerKey.currentState != null) {
      _schedulerKey.currentState!.startUserGuide();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the scheduler to load, then try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startMessagesUserGuide() {
    if (_messagesKey.currentState != null) {
      _messagesKey.currentState!.startUserGuide();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the messages screen to load, then try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startSettingUserGuide() {
    if (_settingKey.currentState != null) {
      _settingKey.currentState!.startUserGuide();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the settings screen to load, then try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
      debugPrint('Authentication check failed: $e');
      // On error, assume authentication is compromised
      await AuthService.logout();
      _redirectToLogin();
    }
  }

  Future<void> _checkgoatStatusUpdates() async {
    try {
      // Check for goat that need status updates (Breeding -> Healthy)
      final updatedgoat = await GoatStatusService.checkAndUpdateBreedingStatus();
      
      if (updatedgoat.isNotEmpty && mounted) {
        // Show a notification to the user about the status updates
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedgoat.length} Doe(s) status automatically updated to Healthy'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Auto-update goat classifications based on age
      final _ = await GoatService.autoUpdategoatClassifications();
      
      // Snackbar removed - auto-update runs silently in background
    } catch (e) {
      debugPrint('Error checking goat status updates: $e');
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
          _profile = profileData ?? {};
          _isLoadingProfile = false;
        });
        
        // Debug log to check if profile_picture is present
        if (profileData != null) {
          debugPrint('Profile loaded - profile_picture present: ${profileData['profile_picture'] != null && profileData['profile_picture'].toString().isNotEmpty}');
          if (profileData['profile_picture'] != null) {
            debugPrint('Profile picture length: ${profileData['profile_picture'].toString().length}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');

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
      if (!mounted) return;
      
      // Refresh profile data to ensure drawer shows latest profile picture
      await _loadProfileData();
      if (!mounted) return;
      
      // Also auto-update goat classifications
      final _ = await GoatService.autoUpdategoatClassifications();
      
      // Dismiss loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show appropriate success message
      final message = RefreshService.getRefreshMessage(refreshResults);
      final hasErrors = refreshResults['errors'].isNotEmpty;
      final hasgoatUpdates = refreshResults['goatStatusUpdates'].isNotEmpty;
      
      // Classification update info removed from snackbar message
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: hasErrors ? Colors.orange[600] : 
                          hasgoatUpdates ? Colors.green[600] : AppColors.lightGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 4),
        ),
      );

      // Refresh the current screen
      try {
        final screenKeys = {
          'profile': _profileKey,
          'goat': _goatKey,
          'dashboard': _dashboardKey,
          'history': _historyKey,
          'scheduler': _schedulerKey,
          'messages': _messagesKey,
          'settings': _settingKey,
        };
        
        // Refresh current screen based on selected index
        switch (_selectedIndex) {
          case 0: // Profile
            if (screenKeys['profile']?.currentState != null) {
              await (screenKeys['profile']!.currentState as dynamic).refresh();
            }
            break;
          case 1: // Goat
            if (screenKeys['goat']?.currentState != null) {
              await (screenKeys['goat']!.currentState as dynamic).refresh();
            }
            break;
          case 2: // Dashboard
            if (screenKeys['dashboard']?.currentState != null) {
              await (screenKeys['dashboard']!.currentState as dynamic).refresh();
            }
            break;
          case 3: // History
            if (screenKeys['history']?.currentState != null) {
              await (screenKeys['history']!.currentState as dynamic).refresh();
            }
            break;
          case 4: // Scheduler
            if (screenKeys['scheduler']?.currentState != null) {
              await (screenKeys['scheduler']!.currentState as dynamic).refresh();
            }
            break;
          case 6: // Messages
            if (screenKeys['messages']?.currentState != null) {
              await (screenKeys['messages']!.currentState as dynamic).refresh();
            }
            break;
          case 7: // Settings
            if (screenKeys['settings']?.currentState != null) {
              await (screenKeys['settings']!.currentState as dynamic).refresh();
            }
            break;
        }
      } catch (e) {
        debugPrint('Error refreshing current screen: $e');
      }
      
      // Force refresh of the current page by triggering a rebuild
      setState(() {
        // This will trigger a rebuild of the current page
      });

    } catch (e) {
      if (!mounted) return;
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
                color: Colors.red.withValues(alpha: 0.1),
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

    if (!mounted) return;

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
                    color: Colors.blue.withValues(alpha: 0.1),
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
                      color: Colors.red.withValues(alpha: 0.1),
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
          onPressed: () {
            // Refresh profile data when opening drawer
            _loadProfileData();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All App Data',
            onPressed: _handleRefresh,
          ),
          // Show help button on Profile
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Start User Guide',
              onPressed: _startProfileUserGuide,
            ),
          // Show help button on Goat Screen
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Start User Guide',
              onPressed: _startGoatUserGuide,
            ),
          // Show help button on Dashboard
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Start User Guide',
              onPressed: _startDashboardUserGuide,
            ),
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Start User Guide',
              onPressed: _startHistoryUserGuide,
            ),
          if (_selectedIndex == 4)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Start User Guide',
              onPressed: _startSchedulerUserGuide,
            ),
          if (_selectedIndex == 6)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Start User Guide',
              onPressed: _startMessagesUserGuide,
            ),
          if (_selectedIndex == 7)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Start User Guide',
              onPressed: _startSettingUserGuide,
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
        return 'User Profile';
      case 1:
        return 'Production Record';
      case 2:
        return 'Dashboard';
      case 3:
        return 'Goat History';
      case 4:
        return 'Scheduled Activities';
      case 5:
        return 'Milk Production';
      case 6:
        return 'Messages';
      case 7:
        return 'Settings';
      default:
        return '';
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
                  index: 2,
                  onTap: () => _onNavItemTapped(2),
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  text: 'My Profile',
                  index: 0,
                  onTap: () => _onNavItemTapped(0),
                ),
                _buildDrawerItem(
                  icon: FontAwesomeIcons.cow,
                  text: 'Production Record',
                  index: 1,
                  onTap: () => _onNavItemTapped(1),
                ),
                _buildDrawerItem(
                  icon: Icons.history_rounded,
                  text: 'Goat History',
                  index: 3,
                  onTap: () => _onNavItemTapped(3),
                ),
                _buildDrawerItem(
                  icon: Icons.event_available_rounded,
                  text: 'Scheduled Activities',
                  index: 4,
                  onTap: () => _onNavItemTapped(4),
                ),
                _buildDrawerItem(
                  icon: Icons.message_rounded,
                  text: 'Messages',
                  index: 6,
                  onTap: () => _onNavItemTapped(6),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  text: 'Settings',
                  index: 7,
                  onTap: () => _onNavItemTapped(7),
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  text: 'Logout',
                  onTap: _logout,
                ),
              ],
            ),
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
        _userEmail ?? widget.userEmail ?? '',
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
        // Remove data URL prefix if present (e.g., "data:image/png;base64,")
        String base64String = profilePicture;
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        
        // Trim whitespace
        base64String = base64String.trim();
        
        // Decode the base64 image
        final imageBytes = base64Decode(base64String);

        if (imageBytes.isNotEmpty) {
          return CircleAvatar(
            backgroundColor: AppColors.cardBackground,
            backgroundImage: MemoryImage(imageBytes),
            onBackgroundImageError: (exception, stackTrace) {
              // Handle image loading error
              debugPrint('Error loading profile image: $exception');
              debugPrint('Stack trace: $stackTrace');
            },
          );
        } else {
          debugPrint('Decoded image bytes are empty');
        }
      } catch (e) {
        debugPrint('Error decoding profile image: $e');
        debugPrint('Profile picture value (first 50 chars): ${profilePicture.substring(0, profilePicture.length > 50 ? 50 : profilePicture.length)}');
        // Fall through to default avatar
      }
    } else {
      debugPrint('Profile picture is null or empty. Profile data: ${_profile?.keys.toList()}');
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
    final bool useGoatIcon = icon == FontAwesomeIcons.cow;

    return ListTile(
      leading: useGoatIcon
          ? Image.asset(
              'assets/images/goat-icons/goat.png',
              width: 24,
              height: 24,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            )
          : Icon(
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
      selectedTileColor: AppColors.accent.withValues(alpha: 0.15),
    );
  }
}