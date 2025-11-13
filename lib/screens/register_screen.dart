import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import your app colors and services
import '../constants/app_colors.dart';
import '../config.dart';
import '../services/address_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;
  bool _isLoadingRegions = false;

  // Address data and selections
  List<dynamic> _regions = [];
  List<dynamic> _provinces = [];
  List<dynamic> _municipalities = [];
  List<dynamic> _barangays = [];

  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedMunicipality;
  Map<String, dynamic>? _selectedBarangay;

  // Latitude and longitude fields
  double? _latitude;
  double? _longitude;
  bool _isGeocodingInProgress = false;
  Timer? _geocodeTimer;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _geocodeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      debugPrint('Loading regions...');
      final regions = await AddressService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
      debugPrint('Successfully loaded ${regions.length} regions');
    } catch (e) {
      debugPrint('Error loading regions: $e');
      setState(() => _isLoadingRegions = false);
      _showMessage('Failed to load regions. Please check your internet connection.', Colors.red);
    }
  }

  Future<void> _loadProvincesForRegion(String regionCode) async {
    setState(() => _isLoadingProvinces = true);
    try {
      debugPrint('Loading provinces for region code: $regionCode');
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
      debugPrint('Successfully loaded ${provinces.length} provinces');
    } catch (e) {
      debugPrint('Error loading provinces: $e');
      setState(() => _isLoadingProvinces = false);
      _showMessage('Failed to load provinces. Please check your internet connection.', Colors.red);
    }
  }

  Future<void> _loadMunicipalities(String provinceCode) async {
    setState(() => _isLoadingMunicipalities = true);
    try {
      debugPrint('Loading municipalities for province code: $provinceCode');
      final municipalities = await AddressService.getMunicipalities(provinceCode);

      setState(() {
        _municipalities = municipalities;
        _barangays = [];
        _selectedBarangay = null;
        _selectedMunicipality = null;
        _isLoadingMunicipalities = false;
        // Clear coordinates when province changes
        _latitude = null;
        _longitude = null;
      });
      debugPrint('Successfully loaded ${municipalities.length} municipalities');
    } catch (e) {
      debugPrint('Error loading municipalities: $e');
      setState(() => _isLoadingMunicipalities = false);
      _showMessage(
          'Failed to load municipalities. Please check your internet connection.',
          Colors.red);
    }
  }

  Future<void> _loadBarangays(String municipalityCode) async {
    setState(() => _isLoadingBarangays = true);
    try {
      final barangays = await AddressService.getBarangays(municipalityCode);
      setState(() {
        _barangays = barangays;
        _selectedBarangay = null;
        _isLoadingBarangays = false;
      });
      // Only trigger geocoding if a barangay is already selected (for edit mode)
      if (_selectedBarangay != null && _selectedBarangay!['name'] != null && _selectedBarangay!['name'].isNotEmpty) {
        debugPrint('Barangays loaded, existing barangay selected: ${_selectedBarangay!['name']}, triggering geocoding...');
        _debounceGeocode();
      } else {
        debugPrint('Barangays loaded, no barangay selected yet - waiting for user selection');
      }
    } catch (e) {
      setState(() => _isLoadingBarangays = false);
      _showMessage('Failed to load barangays: $e', Colors.red);
    }
  }

  // Debounced geocoding (matches JavaScript implementation)
  void _debounceGeocode() {
    _geocodeTimer?.cancel();
    _geocodeTimer = Timer(const Duration(milliseconds: 500), () {
      _performGeocode();
    });
  }

  // Geocoding functionality
  Future<void> _performGeocode() async {
    if (_isGeocodingInProgress) return;
    
    final province = _selectedProvince?['name'];
    final municipality = _selectedMunicipality?['name'];
    final barangay = _selectedBarangay?['name'];
    
    // Only geocode when a barangay is selected to ensure barangay-level coordinates
    if (province == null || municipality == null || barangay == null || barangay.isEmpty) return;
    
    setState(() => _isGeocodingInProgress = true);
    
    try {
      debugPrint('=== FLUTTER GEOCODING DEBUG ===');
      debugPrint('Province: $province');
      debugPrint('Municipality: $municipality');
      debugPrint('Barangay: $barangay');
      
      final queryParams = {
        'province': province,
        'municipality': municipality,
        if (barangay != null && barangay.isNotEmpty) 'barangay': barangay,
      };
      
      final uri = Uri.parse('${AppConfig.baseUrl}/api/geocode')
          .replace(queryParameters: queryParams);
      
      debugPrint('Geocoding URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Geocoding response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Geocoding response data: $data');
        
        if (data['success'] == true && 
            data['data'] != null && 
            data['data']['latitude'] != null && 
            data['data']['longitude'] != null) {
          
          final lat = double.tryParse(data['data']['latitude'].toString());
          final lng = double.tryParse(data['data']['longitude'].toString());
          
          if (lat != null && lng != null) {
            setState(() {
              _latitude = lat;
              _longitude = lng;
            });
            debugPrint('Coordinates set successfully: $lat, $lng');
          }
        } else {
          debugPrint('No coordinates found in response');
        }
      } else {
        debugPrint('Geocoding failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    } finally {
      setState(() => _isGeocodingInProgress = false);
    }
  }

  Future<void> _registerUser() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Additional validation for required address fields
      if (_selectedProvince == null) {
        _showMessage('Select a province.', Colors.red);
        return;
      }
      if (_selectedMunicipality == null) {
        _showMessage('Select a municipality.', Colors.red);
        return;
      }

      setState(() => _isLoading = true);

      // Attempt geocoding before submission if coordinates are empty and barangay is selected
      if ((_latitude == null || _longitude == null) && _selectedBarangay != null && _selectedBarangay!['name'] != null && _selectedBarangay!['name'].isNotEmpty) {
        debugPrint('Coordinates empty before submit, attempting geocoding...');
        await _performGeocode();
        // Wait a bit for geocoding to complete
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      try {
        final url = Uri.parse('${AppConfig.baseUrl}/auth/register');
        final requestBody = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': 'farmer', // Default role
        'region': _selectedRegion?['name'] ?? '',
          'province': _selectedProvince?['name'] ?? '',
          'municipality': _selectedMunicipality?['name'],
          'barangay': _selectedBarangay?['name'],
        };
        
        // Add coordinates if available
        if (_latitude != null && _longitude != null) {
          requestBody['latitude'] = _latitude!.toStringAsFixed(7);
          requestBody['longitude'] = _longitude!.toStringAsFixed(7);
        }
        
        debugPrint('Registration request body: $requestBody');
        
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (!mounted) return;

        final data = jsonDecode(response.body);

        if (response.statusCode == 201) {
          final message = data['message'] ?? 'Registration Successful! You can now login to your account.';
          _showMessage(message, AppColors.vibrantGreen);
          // Navigate back to the login screen
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else {
          final errorMessage = data['message'] ?? 'Registration failed. Status: ${response.statusCode}';
          debugPrint('Server Error: $errorMessage');
          _showMessage(errorMessage, Colors.red);
        }
      } on http.ClientException catch (e) {
        if (mounted) {
          debugPrint('Network Error: ${e.message}');
          _showMessage('Network error: ${e.message}', Colors.red);
        }
      } on FormatException catch (e) {
        if (mounted) {
          debugPrint('JSON Parsing Error: $e');
          _showMessage('Invalid response format from server. Please try again.', Colors.red);
        }
      } catch (e) {
        if (mounted) {
          debugPrint('Unexpected Error: $e');
          _showMessage('An unexpected error occurred: ${e.toString()}', Colors.red);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon consistent with registration theme
                  Icon(Icons.person_add_alt_1,
                      size: 80, color: AppColors.primary),
                  const SizedBox(height: 20),

                  // Enhanced Title and Subtitle
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join the community.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(text: 'Fields marked with '),
                          TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          TextSpan(text: ' are required.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Fields
                  _buildNameFields(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      'Email',
                      Icons.email_outlined,
                      hint: 'name@example.com',
                      helper: 'Must be a valid email format (we\'ll send a verification link)'.replaceAll("'", "'"),
                      requiredField: true,
                    ),
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  _buildAddressFields(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 40),

                  // Register Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _registerUser,
                    style: _buttonStyle(),
                    child: _buttonText('Submit'),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              'First Name',
              Icons.person_outline,
              requiredField: true,
            ),
            validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter first name' : null,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              'Last Name',
              Icons.person_outline,
              requiredField: true,
            ),
            validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter last name' : null,
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressFields() {
    return Column(
      children: [
        // Region Dropdown
        _buildRegionDropdown(),
        const SizedBox(height: 20),

        // Province Dropdown
        _buildProvinceDropdown(),
        const SizedBox(height: 20),

        // Municipality Dropdown with loading indicator
        _buildMunicipalityDropdown(),
        const SizedBox(height: 20),

        // Barangay Dropdown with loading indicator
        _buildBarangayDropdown(),
      ],
    );
  }

  Widget _buildRegionDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedRegion?['code']?.toString(),
          decoration: _inputDecoration(
            'Region',
            Icons.map_outlined,
            helper: 'Select your region',
            requiredField: true,
          ),
          items: _regions
              .map((region) => DropdownMenuItem<String>(
                    value: region['code']?.toString(),
                    child: Text(region['name'] ?? 'Unknown Region'),
                  ))
              .toList(),
          onChanged: _isLoadingRegions
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    final selectedRegion = _regions.firstWhere(
                      (region) => region['code']?.toString() == newValue,
                      orElse: () => {},
                    );
                    setState(() {
                      _selectedRegion = selectedRegion.isNotEmpty ? selectedRegion : null;
                      // Clear lower levels
                      _provinces = [];
                      _municipalities = [];
                      _barangays = [];
                      _selectedProvince = null;
                      _selectedMunicipality = null;
                      _selectedBarangay = null;
                      _latitude = null;
                      _longitude = null;
                    });
                    if (selectedRegion.isNotEmpty) {
                      debugPrint('🗺️ Region selected: ${selectedRegion['name']}, loading provinces...');
                      _loadProvincesForRegion(selectedRegion['code']);
                    }
                  } else {
                    setState(() {
                      _selectedRegion = null;
                      _provinces = [];
                      _municipalities = [];
                      _barangays = [];
                      _selectedProvince = null;
                      _selectedMunicipality = null;
                      _selectedBarangay = null;
                      _latitude = null;
                      _longitude = null;
                    });
                  }
                },
          validator: (value) => value == null || value.isEmpty ? 'Select a region' : null,
        ),
        if (_isLoadingRegions)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProvinceDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedProvince?['code']?.toString(),
          decoration: _inputDecoration(
            'Province',
            Icons.location_on,
            helper: 'Select your province',
            requiredField: true,
          ),
          items: _provinces
              .map((province) => DropdownMenuItem<String>(
            value: province['code']?.toString(),
            child: Text(province['name'] ?? 'Unknown Province'),
          ))
              .toList(),
          onChanged: _isLoadingProvinces || _selectedRegion == null
              ? null
              : (String? newValue) {
            if (newValue != null) {
              final selectedProvince = _provinces.firstWhere(
                (province) => province['code']?.toString() == newValue,
                orElse: () => {},
              );
              setState(() {
                _selectedProvince = selectedProvince.isNotEmpty ? selectedProvince : null;
                _municipalities = [];
                _barangays = [];
                _selectedMunicipality = null;
                _selectedBarangay = null;
                // Clear coordinates when province changes
                _latitude = null;
                _longitude = null;
              });
              if (selectedProvince.isNotEmpty) {
                debugPrint('📍 Province selected: ${selectedProvince['name']}, loading municipalities...');
                _loadMunicipalities(selectedProvince['code']);
              }
            } else {
              setState(() {
                _selectedProvince = null;
                _municipalities = [];
                _barangays = [];
                _selectedMunicipality = null;
                _selectedBarangay = null;
                // Clear coordinates when province is cleared
                _latitude = null;
                _longitude = null;
              });
            }
          },
          validator: (value) => _selectedRegion != null && (value == null || value.isEmpty) ? 'Select a province' : null,
          hint: _selectedRegion == null ? const Text('Select region first') : const Text('Select province'),
        ),
        if (_isLoadingProvinces)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMunicipalityDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedMunicipality?['code']?.toString(),
          decoration: _inputDecoration(
            'Municipality/City',
            Icons.location_city,
            helper: 'Select your municipality',
            requiredField: true,
          ),
          items: _municipalities
              .map((municipality) => DropdownMenuItem<String>(
            value: municipality['code']?.toString(),
            child: Text(municipality['name'] ?? 'Unknown Municipality'),
          ))
              .toList(),
          onChanged: _isLoadingMunicipalities || _selectedProvince == null
              ? null
              : (String? newValue) {
            if (newValue != null) {
              final selectedMunicipality = _municipalities.firstWhere(
                (municipality) => municipality['code']?.toString() == newValue,
                orElse: () => {},
              );
              setState(() {
                _selectedMunicipality = selectedMunicipality.isNotEmpty ? selectedMunicipality : null;
                _barangays = [];
                _selectedBarangay = null;
                // Clear coordinates when municipality changes (will be updated when barangay is selected)
                _latitude = null;
                _longitude = null;
              });
              if (selectedMunicipality.isNotEmpty) {
                debugPrint('🏙️ Municipality selected: ${selectedMunicipality['name']}, loading barangays...');
                _loadBarangays(selectedMunicipality['code']);
                // Note: Geocoding will only happen when barangay is selected
              }
            } else {
              setState(() {
                _selectedMunicipality = null;
                _barangays = [];
                _selectedBarangay = null;
                // Clear coordinates when municipality is cleared
                _latitude = null;
                _longitude = null;
              });
            }
          },
          validator: (value) =>
          _selectedProvince != null && (value == null || value.isEmpty) ? 'Select a municipality' : null,
          hint: _selectedProvince == null
              ? const Text('Select province first')
              : const Text('Select municipality'),
        ),
        if (_isLoadingMunicipalities)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBarangayDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedBarangay?['code']?.toString(),
          decoration: _inputDecoration(
            'Barangay',
            Icons.home,
            helper: 'Select your barangay',
            requiredField: true,
          ),
          items: _barangays
              .map((barangay) => DropdownMenuItem<String>(
            value: barangay['code']?.toString(),
            child: Text(barangay['name'] ?? 'Unknown Barangay'),
          ))
              .toList(),
          onChanged: _isLoadingBarangays || _selectedMunicipality == null
              ? null
              : (String? newValue) {
            if (newValue != null) {
              final selectedBarangay = _barangays.firstWhere(
                (barangay) => barangay['code']?.toString() == newValue,
                orElse: () => {},
              );
              setState(() {
                _selectedBarangay = selectedBarangay.isNotEmpty ? selectedBarangay : null;
              });
              // Stop any ongoing geocoding and start fresh
              _geocodeTimer?.cancel();
              
              // Trigger debounced geocoding when barangay is selected (coordinates will be updated)
              if (selectedBarangay.isNotEmpty) {
                debugPrint('🎯 Barangay selected: ${selectedBarangay['name']}, starting fresh geocoding...');
                // Clear previous coordinates immediately
                setState(() {
                  _latitude = null;
                  _longitude = null;
                });
                _debounceGeocode();
              } else {
                // Only clear coordinates when barangay is cleared/empty
                debugPrint('Barangay cleared, clearing coordinates');
                setState(() {
                  _latitude = null;
                  _longitude = null;
                });
              }
            } else {
              setState(() {
                _selectedBarangay = null;
                // Clear coordinates when barangay is cleared
                _latitude = null;
                _longitude = null;
              });
            }
          },
          validator: (value) =>
              _selectedMunicipality != null && (value == null || value.isEmpty) ? 'Select a barangay' : null,
          hint: _selectedMunicipality == null
              ? const Text('Select municipality first')
              : const Text('Select barangay'),
        ),
        if (_isLoadingBarangays)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: _inputDecoration(
        'Password',
        Icons.lock_outline,
        hint: 'At least 6 characters',
        helper: 'Minimum 6 characters',
        requiredField: true,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
      ),
      validator: _validatePassword,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: _inputDecoration(
        'Confirm Password',
        Icons.lock_outline,
        hint: 'Re-enter your password',
        helper: 'Must match the password',
        requiredField: true,
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
          },
        ),
      ),
      validator: _validateConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _registerUser(),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon, String? hint, String? helper, bool requiredField = false}) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: AppColors.textSecondary),
          children: requiredField
              ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
              : const [],
        ),
      ),
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
    );
  }

  Text _buttonText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?",
            style: TextStyle(color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(
            'Login here',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

}
