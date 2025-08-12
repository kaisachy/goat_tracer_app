// widgets/auth_guard.dart
import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

/// Authentication Guard - Protects routes that require login
class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isAuthenticated = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final token = await SecureStorageService().getToken();
      if (token == null) {
        _redirectToLogin();
        return;
      }

      // Verify token is still valid
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        // Token is invalid, clear storage and redirect
        await AuthService.logout();
        _redirectToLogin();
        return;
      }

      setState(() {
        _isAuthenticated = true;
        _isChecking = false;
      });
    } catch (e) {
      print('Authentication check failed: $e');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      setState(() {
        _isChecking = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying access...'),
            ],
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const LoginScreen();
    }

    return widget.child;
  }
}