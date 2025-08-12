import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import your app colors
import '../constants/app_colors.dart';
import '../config.dart';

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

  // State variables for address fields
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;

  // Placeholder data for demonstration.
  // You should replace this with a real API call to fetch your data.
  final List<String> _provinces = ['Province A', 'Province B', 'Province C'];
  final Map<String, List<String>> _municipalities = {
    'Province A': ['Municipality A1', 'Municipality A2'],
    'Province B': ['Municipality B1', 'Municipality B2'],
    'Province C': ['Municipality C1', 'Municipality C2'],
  };
  final Map<String, List<String>> _barangays = {
    'Municipality A1': ['Brgy A1-1', 'Brgy A1-2'],
    'Municipality A2': ['Brgy A2-1', 'Brgy A2-2'],
    'Municipality B1': ['Brgy B1-1', 'Brgy B1-2'],
    'Municipality B2': ['Brgy B2-1', 'Brgy B2-2'],
    'Municipality C1': ['Brgy C1-1', 'Brgy C1-2'],
    'Municipality C2': ['Brgy C2-1', 'Brgy C2-2'],
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Additional validation for the required province field
      if (_selectedProvince == null) {
        _showMessage('Please select a province.', Colors.red);
        return;
      }

      setState(() => _isLoading = true);

      try {
        final url = Uri.parse('${AppConfig.baseUrl}/auth/register');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'role': 'farmer', // Default role
            'province': _selectedProvince,
            'municipality': _selectedMunicipality,
            'barangay': _selectedBarangay,
          }),
        );

        if (!mounted) return;

        // Check if the response body is a valid JSON before decoding
        final data = jsonDecode(response.body);

        if (response.statusCode == 201) {
          _showMessage(
              'Registration Successful! Please login.', AppColors.vibrantGreen);
          // Navigate back to the login screen
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else {
          // Use the error message from the server if available
          final errorMessage = data['message'] ?? 'Registration failed. Status: ${response.statusCode}';
          print('Server Error: $errorMessage');
          _showMessage(
              errorMessage,
              Colors.red);
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
        print('Error parsing JSON response: $e');
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
        // Add a back button with a consistent color
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
                    'Join the Cattle Connect community',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Fields
                  _buildNameFields(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                    _inputDecoration('Email', Icons.email_outlined),
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
                    child: _buttonText('CREATE ACCOUNT'),
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
            decoration: _inputDecoration('First Name', Icons.person_outline),
            validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            decoration: _inputDecoration('Last Name', Icons.person_outline),
            validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressFields() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: _inputDecoration('Province', Icons.location_city),
          items: _provinces
              .map((String value) => DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          ))
              .toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedProvince = newValue;
              // Reset municipalities and barangays when province changes
              _selectedMunicipality = null;
              _selectedBarangay = null;
            });
          },
          validator: (value) => value == null ? 'Please select a province' : null,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedMunicipality,
          decoration: _inputDecoration('Municipality', Icons.location_on),
          items: _selectedProvince != null
              ? _municipalities[_selectedProvince!]
              ?.map((String value) => DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          ))
              .toList()
              : [],
          onChanged: (String? newValue) {
            setState(() {
              _selectedMunicipality = newValue;
              _selectedBarangay = null; // Reset barangay when municipality changes
            });
          },
          validator: (value) {
            // This is optional based on your backend logic
            return null;
          },
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedBarangay,
          decoration: _inputDecoration('Barangay', Icons.location_on_outlined),
          items: _selectedMunicipality != null
              ? _barangays[_selectedMunicipality!]
              ?.map((String value) => DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          ))
              .toList()
              : [],
          onChanged: (String? newValue) {
            setState(() {
              _selectedBarangay = newValue;
            });
          },
          validator: (value) {
            // This is optional based on your backend logic
            return null;
          },
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
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(
                    () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
          },
        ),
      ),
      validator: _validateConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _registerUser(),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
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
