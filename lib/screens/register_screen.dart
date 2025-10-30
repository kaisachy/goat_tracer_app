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
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  // Address data and selections
  List<dynamic> _municipalities = [];
  List<dynamic> _barangays = [];

  Map<String, dynamic>? _selectedMunicipality;
  Map<String, dynamic>? _selectedBarangay;

  // Latitude and longitude fields
  double? _latitude;
  double? _longitude;
  bool _isGeocodingInProgress = false;
  Timer? _geocodeTimer;

  // Fixed province data for Isabela
  final Map<String, dynamic> _isabelaProvince = {
    'name': 'Isabela',
    'code': 'ISABELA'
  };

  @override
  void initState() {
    super.initState();
    _loadIsabelaMunicipalities();
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

  Future<void> _loadIsabelaMunicipalities() async {
    setState(() => _isLoadingMunicipalities = true);
    try {
      print('Loading Isabela municipalities...');
      final municipalities = await AddressService.getIsabelaMunicipalities();

      setState(() {
        _municipalities = municipalities;
        _isLoadingMunicipalities = false;
      });
      print('Successfully loaded ${municipalities.length} municipalities');
    } catch (e) {
      print('Error loading municipalities: $e');
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
        print('Barangays loaded, existing barangay selected: ${_selectedBarangay!['name']}, triggering geocoding...');
        _debounceGeocode();
      } else {
        print('Barangays loaded, no barangay selected yet - waiting for user selection');
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
    
    final province = _isabelaProvince['name'];
    final municipality = _selectedMunicipality?['name'];
    final barangay = _selectedBarangay?['name'];
    
    // Only geocode when a barangay is selected to ensure barangay-level coordinates
    if (province == null || municipality == null || barangay == null || barangay.isEmpty) return;
    
    setState(() => _isGeocodingInProgress = true);
    
    try {
      print('=== FLUTTER GEOCODING DEBUG ===');
      print('Province: $province');
      print('Municipality: $municipality');
      print('Barangay: $barangay');
      
      final queryParams = {
        'province': province,
        'municipality': municipality,
        if (barangay != null && barangay.isNotEmpty) 'barangay': barangay,
      };
      
      final uri = Uri.parse('${AppConfig.baseUrl}/api/geocode')
          .replace(queryParameters: queryParams);
      
      print('Geocoding URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      print('Geocoding response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Geocoding response data: $data');
        
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
            print('Coordinates set successfully: $lat, $lng');
          }
        } else {
          print('No coordinates found in response');
        }
      } else {
        print('Geocoding failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Geocoding error: $e');
    } finally {
      setState(() => _isGeocodingInProgress = false);
    }
  }

  Future<void> _registerUser() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Additional validation for required address fields
      if (_selectedMunicipality == null) {
        _showMessage('Select a municipality.', Colors.red);
        return;
      }

      setState(() => _isLoading = true);

      // Attempt geocoding before submission if coordinates are empty and barangay is selected
      if ((_latitude == null || _longitude == null) && _selectedBarangay != null && _selectedBarangay!['name'] != null && _selectedBarangay!['name'].isNotEmpty) {
        print('Coordinates empty before submit, attempting geocoding...');
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
          'province': _isabelaProvince['name'], // Fixed to Isabela
          'municipality': _selectedMunicipality?['name'],
          'barangay': _selectedBarangay?['name'],
        };
        
        // Add coordinates if available
        if (_latitude != null && _longitude != null) {
          requestBody['latitude'] = _latitude!.toStringAsFixed(7);
          requestBody['longitude'] = _longitude!.toStringAsFixed(7);
        }
        
        print('Registration request body: $requestBody');
        
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
          print('Server Error: $errorMessage');
          _showMessage(errorMessage, Colors.red);
        }
      } on http.ClientException catch (e) {
        if (mounted) {
          print('Network Error: ${e.message}');
          _showMessage('Network error: ${e.message}', Colors.red);
        }
      } on FormatException catch (e) {
        if (mounted) {
          print('JSON Parsing Error: $e');
          _showMessage('Invalid response format from server. Please try again.', Colors.red);
        }
      } catch (e) {
        if (mounted) {
          print('Unexpected Error: $e');
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
                    'Join the Cattle Tracer community.',
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
        // Province Field (styled like other input fields)
        TextFormField(
          readOnly: true,
          decoration: _inputDecoration('Province', Icons.location_on, helper: 'Fixed to Isabela')
              .copyWith(
            suffixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(Icons.lock_outline,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
          controller: TextEditingController(text: _isabelaProvince['name']),
        ),
        const SizedBox(height: 20),

        // Municipality Dropdown with loading indicator
        _buildMunicipalityDropdown(),
        const SizedBox(height: 20),

        // Barangay Dropdown with loading indicator
        _buildBarangayDropdown(),
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
          onChanged: _isLoadingMunicipalities
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
                print('🏙️ Municipality selected: ${selectedMunicipality['name']}, loading barangays...');
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
          value == null || value.isEmpty ? 'Select a municipality' : null,
        ),
        if (_isLoadingMunicipalities)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
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
          onChanged: _isLoadingBarangays
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
                print('🎯 Barangay selected: ${selectedBarangay['name']}, starting fresh geocoding...');
                // Clear previous coordinates immediately
                setState(() {
                  _latitude = null;
                  _longitude = null;
                });
                _debounceGeocode();
              } else {
                // Only clear coordinates when barangay is cleared/empty
                print('Barangay cleared, clearing coordinates');
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
              value == null || value.isEmpty ? 'Select a barangay' : null,
        ),
        if (_isLoadingBarangays)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
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
      shadowColor: AppColors.primary.withOpacity(0.4),
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