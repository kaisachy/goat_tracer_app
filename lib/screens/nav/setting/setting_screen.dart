import 'package:flutter/material.dart';
import 'package:goat_tracer_app/services/user_service.dart';
import 'package:goat_tracer_app/services/auth_service.dart';
import 'package:goat_tracer_app/services/address_service.dart';
import 'package:goat_tracer_app/models/user.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Controllers for user info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Controllers for password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  User? _currentUser;
  bool _isLoading = true;
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Address-related variables
  List<dynamic> _regions = [];
  List<dynamic> _provinces = [];
  List<dynamic> _municipalities = [];
  List<dynamic> _barangays = [];
  String? _selectedRegion; // region name
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;
  bool _isLoadingRegions = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;
  bool _isDataReady = false; // New flag to track when data is ready for dropdowns
  bool _isInitializing = false; // Flag to prevent infinite loops during initialization

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Add listener to new password controller to trigger confirm password validation
    _newPasswordController.addListener(() {
      if (_passwordFormKey.currentState != null) {
        _passwordFormKey.currentState!.validate();
      }
    });
    
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (_isInitializing) {
      debugPrint('Already initializing, skipping...');
      return;
    }
    
    try {
      _isInitializing = true;
      setState(() => _isLoading = true); // Ensure loading is true at start
      
      // Load regions first - wait for it to complete
      await _loadRegions();
      
      // Ensure regions are loaded before proceeding
      if (_regions.isEmpty) {
        debugPrint('Regions not loaded, waiting...');
        // Wait a bit and retry if needed
        await Future.delayed(const Duration(milliseconds: 500));
        if (_regions.isEmpty) {
          debugPrint('Regions still not loaded after wait');
        }
      }
      
      // Then load user data (which will load municipalities and barangays based on province)
      await _loadUserData();
    } catch (e) {
      debugPrint('Error initializing data: $e');
      setState(() {
        _isLoading = false;
        _isDataReady = false;
      });
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadRegions() async {
    try {
      setState(() => _isLoadingRegions = true);
      final regions = await AddressService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() => _isLoadingRegions = false);
      debugPrint('Error loading regions: $e');
    }
  }

  Future<void> _loadProvincesForRegion(String regionCode) async {
    try {
      setState(() => _isLoadingProvinces = true);
      final provinces = await AddressService.getProvinces(regionCode);
      setState(() {
        _provinces = provinces;
        _municipalities = [];
        _barangays = [];
        _selectedProvince = null;
        _selectedMunicipality = null;
        _selectedBarangay = null;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
      debugPrint('Error loading provinces for region: $e');
    }
  }

  Future<void> _loadMunicipalities(String provinceCode) async {
    try {
      setState(() => _isLoadingMunicipalities = true);
      final municipalities = await AddressService.getMunicipalities(provinceCode);
      setState(() {
        _municipalities = municipalities;
        _barangays = [];
        _selectedBarangay = null;
        _selectedMunicipality = null;
        _isLoadingMunicipalities = false;
      });
      
      // If user data is already loaded, set municipality and barangay if available
      // Don't call _loadUserData() again as it causes infinite loops
      if (_currentUser != null && !_isInitializing) {
        // Set municipality and barangay from user data if available
        final userMunicipality = _currentUser!.municipality;
        final userBarangay = _currentUser!.barangay;
        
        if (userMunicipality != null && userMunicipality.isNotEmpty) {
          final municipalityExists = municipalities.any((m) => m['name'] == userMunicipality);
          if (municipalityExists) {
            setState(() {
              _selectedMunicipality = userMunicipality;
            });
            
            // Load barangays for the selected municipality
            try {
              final municipality = municipalities.firstWhere(
                (m) => m['name'] == userMunicipality,
              );
              await _loadBarangays(municipality['code']);
              
              // Set barangay if available
              if (userBarangay != null && userBarangay.isNotEmpty) {
                setState(() {
                  _selectedBarangay = userBarangay;
                });
              }
            } catch (e) {
              debugPrint('Municipality not found: $userMunicipality');
            }
          }
        }
      } else if (_currentUser == null && !_isInitializing) {
        // If user data is not loaded yet and not initializing, mark data as ready
        setState(() {
          _isDataReady = true;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMunicipalities = false);
      debugPrint('Error loading municipalities: $e');
    }
  }

  Future<void> _loadBarangays(String municipalityCode) async {
    try {
      setState(() => _isLoadingBarangays = true);
      final barangays = await AddressService.getBarangays(municipalityCode);
      setState(() {
        _barangays = barangays;
        _isLoadingBarangays = false;
      });
    } catch (e) {
      setState(() => _isLoadingBarangays = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Try to get user ID from stored data first, then from token as fallback
      String? userIdString = await AuthService.getUserId();
      
      // If not found in storage, try to get from token
      if (userIdString == null || userIdString.isEmpty) {
        userIdString = await AuthService.getCurrentUserId();
      }

      if (userIdString == null || userIdString.isEmpty) {
        throw Exception('User session not found. Please login again.');
      }

      // Convert user ID to int
      final int userIdInt = int.parse(userIdString);

      // Fetch user data from server
      final user = await _userService.getUser(userIdInt);

      setState(() {
        _currentUser = user;
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        // Don't set _isLoading = false yet - wait for address data to load
      });

      // If we have user's province, find and set its region first, then load provinces
      if (user.province != null && user.province!.isNotEmpty && _regions.isNotEmpty) {
        try {
          // Find region for user's province by scanning regions' provinces
          String? matchedRegionName;
          String? matchedRegionCode;
          for (final r in _regions) {
            try {
              final provs = await AddressService.getProvinces(r['code']);
              if (provs.any((p) => p['name'] == user.province)) {
                matchedRegionName = r['name'];
                matchedRegionCode = r['code']?.toString();
                break;
              }
            } catch (_) {}
          }
          if (matchedRegionName != null && matchedRegionCode != null) {
            setState(() {
              _selectedRegion = matchedRegionName;
            });
            await _loadProvincesForRegion(matchedRegionCode);
          }
        } catch (e) {
          debugPrint('Failed to auto-detect region for user province: $e');
        }
      }

      // Wait for provinces to be loaded before setting address selection
      // If user has no province or provinces couldn't be loaded, still mark as ready
      if (_provinces.isEmpty) {
        debugPrint('Provinces not loaded yet, skipping address initialization');
        // Ensure regions are loaded before marking as ready
        if (_regions.isNotEmpty) {
          setState(() {
            _isDataReady = true;
            _isLoading = false; // Set loading to false only when regions are ready
          });
        } else {
          debugPrint('Regions not loaded yet, keeping loading state');
          // Keep loading state true - regions should be loading
        }
        return;
      }

      // Set province and load address data in sequence
      if (user.province != null && user.province!.isNotEmpty) {
        setState(() {
          _selectedProvince = user.province;
        });
        
        // Load municipalities for the selected province
        try {
          final province = _provinces.firstWhere(
            (p) => p['name'] == _selectedProvince,
            orElse: () => <String, dynamic>{},
          );
          if (province.isNotEmpty && province['code'] != null) {
            await _loadMunicipalities(province['code']);
            
            // Wait a bit for municipalities to load
            await Future.delayed(const Duration(milliseconds: 200));
            
            // Now set municipality and barangay if available
            if (user.municipality != null && user.municipality!.isNotEmpty && _municipalities.isNotEmpty) {
              final municipalityExists = _municipalities.any((m) => m['name'] == user.municipality);
              if (municipalityExists) {
                setState(() {
                  _selectedMunicipality = user.municipality;
                });
                
                // Load barangays for the selected municipality
                try {
                  final municipality = _municipalities.firstWhere(
                    (m) => m['name'] == user.municipality,
                  );
                  if (municipality['code'] != null) {
                    await _loadBarangays(municipality['code']);
                    
                    // Wait a bit for barangays to load
                    await Future.delayed(const Duration(milliseconds: 200));
                    
                    // Set barangay if available
                    if (user.barangay != null && user.barangay!.isNotEmpty) {
                      setState(() {
                        _selectedBarangay = user.barangay;
                      });
                    }
                  }
                } catch (e) {
                  debugPrint('Municipality not found in list: ${user.municipality}, error: $e');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Province not found: ${user.province}, error: $e');
        }
      }

       // Mark data as ready for dropdowns and stop loading animation
       // Only stop loading when regions are loaded (required for dropdowns)
       if (_regions.isNotEmpty) {
       setState(() {
         _isDataReady = true;
           _isLoading = false; // Only set loading to false when all address data is ready
       });
       _animationController.forward();
       } else {
         debugPrint('Regions not loaded yet, keeping loading state');
         // Keep loading state - regions should be loading or will be loaded
       }
         } catch (e) {
      setState(() {
        _isLoading = false;
        _isDataReady = false; // Reset data ready flag on error
      });

      String errorMessage;
      if (e.toString().contains('User session not found') ||
          e.toString().contains('Please login again')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        _showLoginRequiredDialog();
      } else {
        errorMessage = 'Failed to load user data: ${e.toString().replaceFirst('Exception: ', '')}';
        _showErrorSnackBar(errorMessage);
      }
    }
   }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Your session has expired. Please login again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login screen - adjust route name as needed
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for required address fields
    if (_selectedProvince == null) {
      _showErrorSnackBar('Please select a province');
      return;
    }
    if (_selectedMunicipality == null) {
      _showErrorSnackBar('Please select a municipality');
      return;
    }

    try {
      _showLoadingDialog('Updating profile...');

      final updatedUser = await _userService.updateUser(
        _currentUser!.id,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _currentUser!.email, // Keep existing email
        province: _selectedProvince,
        municipality: _selectedMunicipality,
        barangay: _selectedBarangay,
      );

      if (!mounted) return;
      setState(() {
        _currentUser = updatedUser;
        _isEditingProfile = false;
      });

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _changePassword() async {
    // Validate the password form
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    // Additional validation checks
    if (_currentPasswordController.text.trim().isEmpty) {
      _showErrorSnackBar('Current password is required');
      return;
    }

    if (_newPasswordController.text.trim().isEmpty) {
      _showErrorSnackBar('New password is required');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('New password must be at least 6 characters');
      return;
    }

    // New password must be different from current password
    if (_newPasswordController.text.trim() == _currentPasswordController.text.trim()) {
      _showErrorSnackBar('New password must be different from current password');
      return;
    }

    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    try {
      _showLoadingDialog('Changing password...');

      final success = await _userService.changePassword(
        _currentUser!.id,
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (success) {
        if (!mounted) return;
        setState(() => _isChangingPassword = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        // Reset form validation
        _passwordFormKey.currentState?.reset();

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        _showSuccessSnackBar('Password changed successfully!');
      } else {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        _showErrorSnackBar('Failed to change password');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      String raw = e.toString().replaceFirst('Exception: ', '');
      final lower = raw.toLowerCase();
      // Map common API error messages to friendly, specific snackbars
      if (lower.contains('incorrect current password') || lower.contains('wrong password') || lower.contains('invalid current password')) {
        _showErrorSnackBar('Incorrect current password');
      } else if (lower.contains('same as current') || lower.contains('must be different') || lower.contains('reuse')) {
        _showErrorSnackBar('New password must be different from current password');
      } else if (lower.contains('at least') && lower.contains('characters')) {
        _showErrorSnackBar('New password must be at least 6 characters');
      } else if (lower.contains('session expired') || lower.contains('unauthorized')) {
        _showErrorSnackBar('Session expired. Login again.');
      } else {
        _showErrorSnackBar(raw);
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                                 Text(
                   'Profile Information',
                   style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: AppColors.textPrimary,
                   ),
                 ),
                                 TextButton.icon(
                   onPressed: () {
                     setState(() {
                       if (_isEditingProfile) {
                         // Cancel editing - restore original values
                         _firstNameController.text = _currentUser?.firstName ?? '';
                         _lastNameController.text = _currentUser?.lastName ?? '';
                         _selectedProvince = _currentUser?.province;
                         _selectedMunicipality = _currentUser?.municipality;
                         _selectedBarangay = _currentUser?.barangay;
                         // Reload municipalities for the restored province
                         if (_selectedProvince != null) {
                           final province = _provinces.firstWhere(
                             (p) => p['name'] == _selectedProvince,
                             orElse: () => null,
                           );
                           if (province != null) {
                             _loadMunicipalities(province['code']);
                           }
                         }
                       }
                       _isEditingProfile = !_isEditingProfile;
                     });
                   },
                   icon: Icon(
                     _isEditingProfile ? Icons.close : Icons.edit,
                     size: 20,
                     color: AppColors.primary,
                   ),
                   label: Text(
                     _isEditingProfile ? 'Cancel' : 'Edit',
                     style: TextStyle(fontSize: 14, color: AppColors.primary),
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Wide layout: row for names
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                                         Expanded(
                               child: _buildNameField(
                                 controller: _firstNameController,
                                 label: 'First Name',
                                 icon: FontAwesomeIcons.signature,
                                 enabled: _isEditingProfile,
                               ),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: _buildNameField(
                                 controller: _lastNameController,
                                 label: 'Last Name',
                                 icon: FontAwesomeIcons.signature,
                                 enabled: _isEditingProfile,
                               ),
                             ),
                          ],
                        );
                      } else {
                        // Narrow layout: column for names
                        return Column(
                                                     children: [
                             _buildNameField(
                               controller: _firstNameController,
                               label: 'First Name',
                               icon: FontAwesomeIcons.signature,
                               enabled: _isEditingProfile,
                             ),
                             const SizedBox(height: 16),
                             _buildNameField(
                               controller: _lastNameController,
                               label: 'Last Name',
                               icon: FontAwesomeIcons.signature,
                               enabled: _isEditingProfile,
                             ),
                           ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Region dropdown
                  _isDataReady ? DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Region',
                      labelStyle: TextStyle(color: AppColors.darkGreen),
                      prefixIcon: Icon(Icons.map_outlined, color: AppColors.darkGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: !_isEditingProfile,
                      fillColor: !_isEditingProfile ? Colors.grey[50] : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    items: _regions.map<DropdownMenuItem<String>>((region) {
                      return DropdownMenuItem<String>(
                        value: region['name'],
                        child: Text(region['name']),
                      );
                    }).toList(),
                    value: (_selectedRegion != null &&
                           _regions.any((r) => r['name'] == _selectedRegion))
                        ? _selectedRegion
                        : null,
                    onChanged: _isEditingProfile ? (String? newValue) async {
                      setState(() {
                        _selectedRegion = newValue;
                        _selectedProvince = null;
                        _selectedMunicipality = null;
                        _selectedBarangay = null;
                        _provinces = [];
                        _municipalities = [];
                        _barangays = [];
                      });
                      if (newValue != null) {
                        final region = _regions.firstWhere((r) => r['name'] == newValue, orElse: () => null);
                        if (region != null && region['code'] != null) {
                          await _loadProvincesForRegion(region['code']);
                        }
                      }
                    } : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a region';
                      }
                      return null;
                    },
                  ) : Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map_outlined, color: AppColors.darkGreen),
                        const SizedBox(width: 12),
                        Text(
                          _isLoadingRegions ? 'Loading regions...' : 'Region',
                          style: TextStyle(color: AppColors.darkGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Province dropdown
                  _isDataReady ? DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Province',
                      labelStyle: TextStyle(color: AppColors.darkGreen),
                      prefixIcon: Icon(Icons.location_on, color: AppColors.darkGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: !_isEditingProfile,
                      fillColor: !_isEditingProfile ? Colors.grey[50] : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    items: _provinces.map<DropdownMenuItem<String>>((province) {
                      return DropdownMenuItem<String>(
                        value: province['name'],
                        child: Text(province['name']),
                      );
                    }).toList(),
                    value: (_selectedProvince != null && 
                           _provinces.any((p) => p['name'] == _selectedProvince))
                      ? _selectedProvince
                      : null,
                    onChanged: _isEditingProfile ? (String? newValue) async {
                      setState(() {
                        _selectedProvince = newValue;
                        _selectedMunicipality = null; // Reset municipality when province changes
                        _selectedBarangay = null; // Reset barangay when province changes
                      });
                      
                      if (newValue != null) {
                        try {
                          final province = _provinces.firstWhere(
                            (p) => p['name'] == newValue,
                          );
                          await _loadMunicipalities(province['code']);
                        } catch (e) {
                          debugPrint('Province not found: $newValue');
                        }
                      }
                    } : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a province';
                      }
                      return null;
                    },
                  ) : Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.darkGreen),
                        const SizedBox(width: 12),
                        Text(
                          _isLoadingProvinces ? 'Loading provinces...' : 'Province',
                          style: TextStyle(color: AppColors.darkGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                                                                          // Municipality dropdown
                    _isDataReady ? DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Municipality',
                        labelStyle: TextStyle(color: AppColors.darkGreen),
                        prefixIcon: Icon(Icons.location_city, color: AppColors.darkGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: !_isEditingProfile,
                        fillColor: !_isEditingProfile ? Colors.grey[50] : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    items: _municipalities.map<DropdownMenuItem<String>>((municipality) {
                        return DropdownMenuItem<String>(
                          value: municipality['name'],
                          child: Text(municipality['name']),
                        );
                      }).toList(),
                    value: (_selectedMunicipality != null && 
                           _municipalities.any((m) => m['name'] == _selectedMunicipality))
                        ? _selectedMunicipality
                        : null,
                    hint: _isLoadingMunicipalities
                        ? const Text('Loading municipalities...')
                        : _selectedProvince == null
                            ? const Text('Select province first')
                            : const Text('Municipality'),
                    onChanged: (_isEditingProfile && _selectedProvince != null) ? (String? newValue) async {
                      setState(() {
                        _selectedMunicipality = newValue;
                        _selectedBarangay = null; // Reset barangay when municipality changes
                      });
                      
                      if (newValue != null) {
                        try {
                          final municipality = _municipalities.firstWhere(
                            (m) => m['name'] == newValue,
                          );
                          await _loadBarangays(municipality['code']);
                        } catch (e) {
                          debugPrint('Municipality not found: $newValue');
                        }
                      }
                    } : null,
                                         validator: (value) {
                       if (_selectedProvince != null && (value == null || value.isEmpty)) {
                         return 'Please select a municipality';
                       }
                       return null;
                     },
                                                           ) : Container(
                       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey[300]!),
                         borderRadius: BorderRadius.circular(12),
                         color: Colors.grey[50],
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.location_city, color: AppColors.darkGreen),
                           const SizedBox(width: 12),
                           Text(
                             _isLoadingMunicipalities 
                                 ? 'Loading municipalities...' 
                                 : _selectedProvince == null 
                                     ? 'Select province first' 
                                     : 'Municipality',
                             style: TextStyle(color: AppColors.darkGreen),
                           ),
                         ],
                       ),
                     ),
                  const SizedBox(height: 16),
                                                                          // Barangay dropdown
                    _isDataReady ? DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Barangay',
                        labelStyle: TextStyle(color: AppColors.darkGreen),
                        prefixIcon: Icon(Icons.home, color: AppColors.darkGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: !_isEditingProfile || _selectedProvince == null || _selectedMunicipality == null,
                        fillColor: (!_isEditingProfile || _selectedProvince == null || _selectedMunicipality == null) ? Colors.grey[50] : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    items: _barangays.map<DropdownMenuItem<String>>((barangay) {
                        return DropdownMenuItem<String>(
                          value: barangay['name'],
                          child: Text(barangay['name']),
                        );
                      }).toList(),
                    value: (_selectedBarangay != null && 
                           _barangays.any((b) => b['name'] == _selectedBarangay))
                        ? _selectedBarangay
                        : null,
                    onChanged: (_isEditingProfile && _selectedProvince != null && _selectedMunicipality != null) ? (String? newValue) {
                      setState(() {
                        _selectedBarangay = newValue;
                      });
                    } : null,
                    hint: _isLoadingBarangays
                        ? const Text('Loading barangays...')
                        : _selectedProvince == null || _selectedMunicipality == null
                            ? const Text('Select municipality first')
                            : const Text('Barangay'),
                                         validator: (value) {
                       if (_selectedMunicipality != null && (value == null || value.isEmpty)) {
                         return 'Please select a barangay';
                       }
                       return null;
                     },
                                                                                                                                                               ) : Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.home, color: AppColors.darkGreen),
                            const SizedBox(width: 12),
                            Text(
                              _isLoadingBarangays 
                                  ? 'Loading barangays...' 
                                  : _selectedProvince == null || _selectedMunicipality == null
                                      ? 'Select municipality first'
                                      : 'Barangay',
                              style: TextStyle(color: AppColors.darkGreen),
                            ),
                          ],
                        ),
                      ),
                  if (_isEditingProfile) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.darkGreen),
        prefixIcon: Icon(icon, color: AppColors.darkGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey[50] : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                                 Text(
                   'Password & Security',
                   style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: AppColors.textPrimary,
                   ),
                 ),
                                                   TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_isChangingPassword) {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          // Reset form validation
                          _passwordFormKey.currentState?.reset();
                        }
                        _isChangingPassword = !_isChangingPassword;
                      });
                    },
                   icon: Icon(
                     _isChangingPassword ? Icons.close : Icons.lock,
                     size: 20,
                     color: AppColors.primary,
                   ),
                   label: Text(
                     _isChangingPassword ? 'Cancel' : 'Change',
                     style: TextStyle(fontSize: 14, color: AppColors.primary),
                   ),
                 ),
              ],
            ),
            if (!_isChangingPassword) ...[
              const SizedBox(height: 16),
                                                                                                                       Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: AppColors.lightBackground,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.3)),
                   ),
                   child: Row(
                     children: [
                       Icon(Icons.info_outline, color: AppColors.darkGreen),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           'Keep your account secure by using a strong password.',
                           style: TextStyle(color: AppColors.darkGreen),
                         ),
                       ),
                     ],
                   ),
                 ),
            ] else ...[
              const SizedBox(height: 16),
              Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: AppColors.darkGreen),
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.darkGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off, color: AppColors.darkGreen),
                      onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
                                                           TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: AppColors.darkGreen),
                    prefixIcon: Icon(Icons.lock, color: AppColors.darkGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off, color: AppColors.darkGreen),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Minimum 6 characters',
                    helperStyle: TextStyle(color: AppColors.darkGreen),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'New password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
                                                           TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: AppColors.darkGreen),
                    prefixIcon: Icon(Icons.lock, color: AppColors.darkGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, color: AppColors.darkGreen),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Confirm your new password';
                    }
                    if (value != _newPasswordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                  ),
                  child: const Text(
                    'Change Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
                         Text(
               'Loading account information...',
               style: TextStyle(color: AppColors.textSecondary),
             ),
          ],
        ),
      )
          : _currentUser == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                         Icon(
               Icons.error_outline,
               size: 64,
               color: AppColors.textSecondary,
             ),
            const SizedBox(height: 16),
                         Text(
               'Unable to load user data',
               style: TextStyle(
                 fontSize: 18,
                 color: AppColors.textSecondary,
                 fontWeight: FontWeight.w500,
               ),
             ),
            const SizedBox(height: 8),
                         Text(
               'Please try refreshing or login again',
               style: TextStyle(color: AppColors.textSecondary),
             ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileSection(),
                const SizedBox(height: 20),
                _buildPasswordSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
