// main.dart
import 'package:flutter/material.dart';
import 'auth_guard.dart';
import 'screens/login_screen.dart';
import 'services/secure_storage_service.dart';
import 'screens/home_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_detail_screen.dart';
import 'services/goat/goat_service.dart';
import 'models/goat.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthWrapper(), // Use AuthWrapper instead of SplashScreen
      // Define named routes for navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AuthGuard(child: HomeScreen(userEmail: '')),
        '/goat-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final tag = args?['tag'] as String?;

          if (tag != null) {
            return AuthGuard(child: GoatDetailLoader(tag: tag));
          } else {
            return const AuthGuard(
              child: Scaffold(
                body: Center(
                  child: Text('Invalid Goat Tag'),
                ),
              ),
            );
          }
        },
      },
    );
  }
}

/// Authentication Wrapper - Determines the initial screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkAuthStatus() async {
    final token = await SecureStorageService().getToken();
    if (token == null) return false;

    // Verify token is still valid by checking user ID
    final userId = await AuthService.getCurrentUserId();
    return userId != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const HomeScreen(userEmail: 'Authenticated User');
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// Enhanced goat Detail Loader with authentication
class GoatDetailLoader extends StatelessWidget {
  final String tag;

  const GoatDetailLoader({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Goat?>(
      future: _fetchGoatByTag(tag),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading goat details...'),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // Check if error is authentication related
          if (snapshot.error.toString().contains('401') ||
              snapshot.error.toString().contains('Unauthorized')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAuthError(context);
            });
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading goat: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return GoatDetailScreen(goat: snapshot.data!);
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('goat with tag "$tag" not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<Goat?> _fetchGoatByTag(String tag) async {
    try {
      // Check authentication before making API call
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      return await GoatService.getGoatByTag(tag);
    } catch (e) {
      throw Exception('Failed to fetch goat: $e');
    }
  }

  void _handleAuthError(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }
}