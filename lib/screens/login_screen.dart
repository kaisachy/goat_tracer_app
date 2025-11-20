import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';
import 'register_screen.dart';
import '../config.dart';
import 'home_screen.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  TextEditingController? _forgotPasswordController;
  TextEditingController? _otpController;
  TextEditingController? _otpNewPasswordController;
  TextEditingController? _otpConfirmPasswordController;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotPasswordController?.dispose();
    _otpController?.dispose();
    _otpNewPasswordController?.dispose();
    _otpConfirmPasswordController?.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'role_required': 'farmer', // Add this to specify farmer login only
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['success'] == true) {
            await SecureStorageService().saveToken(data['token']);

            if (!mounted) return;
            _showMessage('Login Successful!', AppColors.vibrantGreen);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(userEmail: _emailController.text.trim()),
              ),
                  (route) => false,
            );
          } else {
            _showMessage(data['message'] ?? 'Login failed', Colors.red);
          }
        } else {
          final data = jsonDecode(response.body);
          String errorMessage = data['message'] ?? 'Server error: ${response.statusCode}';

          // Show server-provided error message directly (no email verification gating)
          _showMessage(errorMessage, Colors.red);
        }
      } catch (e) {
        if (mounted) {
          _showMessage('Connection error. Please try again.', Colors.red);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    _forgotPasswordController ??= TextEditingController();
    _forgotPasswordController!.text = _emailController.text.trim();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleSubmit() async {
              FocusScope.of(dialogContext).unfocus();
              if (!formKey.currentState!.validate()) return;

              setStateDialog(() => isSubmitting = true);

              try {
                final response = await AuthService.requestPasswordReset(
                  _forgotPasswordController!.text.trim(),
                );

                if (!mounted) return;

                final success = response['success'] == true;
                final message = response['message'] ?? (success
                    ? 'OTP sent to your email.'
                    : 'Failed to send OTP. Please try again.');

                _showMessage(
                  message,
                  success ? AppColors.vibrantGreen : Colors.red,
                );

                if (success) {
                  final email = _forgotPasswordController!.text.trim();
                  Navigator.of(dialogContext).pop();
                  Future.microtask(() {
                    if (mounted && email.isNotEmpty) {
                      _showOtpVerificationDialog(email);
                    }
                  });
                }
              } catch (e) {
                if (mounted) {
                  _showMessage('Unable to send OTP. Please try again.', Colors.red);
                }
              } finally {
                if (mounted) {
                  setStateDialog(() => isSubmitting = false);
                }
              }
            }

            return WillPopScope(
              onWillPop: () async => !isSubmitting,
              child: AlertDialog(
                title: const Text('Forgot Password'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your registered email address to receive a one-time password (OTP).',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _forgotPasswordController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Send OTP'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOtpVerificationDialog(String email) {
    final formKey = GlobalKey<FormState>();
    _otpController ??= TextEditingController();
    _otpNewPasswordController ??= TextEditingController();
    _otpConfirmPasswordController ??= TextEditingController();
    _otpController!.clear();
    _otpNewPasswordController!.clear();
    _otpConfirmPasswordController!.clear();
    bool isSubmitting = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleSubmit() async {
              FocusScope.of(dialogContext).unfocus();
              if (!formKey.currentState!.validate()) return;

              setStateDialog(() => isSubmitting = true);

              try {
                final response = await AuthService.resetPassword(
                  _otpController!.text.trim(),
                  _otpNewPasswordController!.text,
                );

                if (!mounted) return;

                final success = response['success'] == true;
                final message = response['message'] ??
                    (success
                        ? 'Password reset successful! You can now log in.'
                        : 'Failed to reset password. Please try again.');

                _showMessage(
                  message,
                  success ? AppColors.vibrantGreen : Colors.red,
                );

                if (success) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                if (mounted) {
                  _showMessage('Unable to reset password. Please try again.', Colors.red);
                }
              } finally {
                if (mounted) {
                  setStateDialog(() => isSubmitting = false);
                }
              }
            }

            return WillPopScope(
              onWillPop: () async => !isSubmitting,
              child: AlertDialog(
                title: const Text('Enter OTP'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We sent a 6-digit OTP to $email. Enter it below along with your new password.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'OTP Code',
                            prefixIcon: Icon(Icons.shield_outlined),
                            counterText: '',
                          ),
                          validator: _validateOtpCode,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otpNewPasswordController,
                          obscureText: !isNewPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isNewPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setStateDialog(
                                  () => isNewPasswordVisible = !isNewPasswordVisible,
                                );
                              },
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otpConfirmPasswordController,
                          obscureText: !isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isConfirmPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setStateDialog(
                                  () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
                                );
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _otpNewPasswordController!.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Email verification flow removed: login no longer requires verified email

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
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
                  // Branded Icon
                  Image.asset(
                    'assets/images/logo.png',
                    width: 300,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),

                  // Enhanced Welcome Text for Farmers
                  Text(
                    'Welcome Back, Farmer!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your farmer account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email', Icons.email_outlined),
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _loginUser(),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _loginUser,
                    style: _buttonStyle(),
                    child: _buttonText('LOGIN'),
                  ),
                  const SizedBox(height: 24),

                  // Registration Link
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
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
    if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateOtpCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter the OTP';
    final otpRegex = RegExp(r'^\d{6}$');
    if (!otpRegex.hasMatch(value.trim())) return 'OTP must be a 6-digit code';
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

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(
            'Register',
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