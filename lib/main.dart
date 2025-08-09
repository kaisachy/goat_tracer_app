import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/secure_storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/nav/cattle/cattle_detail_screen.dart';
import 'services/cattle/cattle_service.dart';
import 'models/cattle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cattle Tracer',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SplashScreen(), // Entry point
      // Define named routes for navigation
      routes: {
        '/cattle-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final tag = args?['tag'] as String?;

          if (tag != null) {
            // Return a FutureBuilder that fetches the cattle data
            return CattleDetailLoader(tag: tag);
          } else {
            // Handle error case - redirect back or show error
            return const Scaffold(
              body: Center(
                child: Text('Invalid cattle tag'),
              ),
            );
          }
        },
      },
    );
  }
}

/// Splash screen that determines whether to show Login or Home
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<bool> _isLoggedIn() async {
    final token = await SecureStorageService().getToken();
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data == true) {
          return const HomeScreen(userEmail: 'Logged in via token');
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// Loader widget that fetches cattle data and navigates to detail screen
class CattleDetailLoader extends StatelessWidget {
  final String tag;

  const CattleDetailLoader({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cattle?>(
      future: _fetchCattleByTag(tag),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading cattle details...'),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading cattle: ${snapshot.error}'),
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
          return CattleDetailScreen(cattle: snapshot.data!);
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Cattle with tag "$tag" not found'),
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

  Future<Cattle?> _fetchCattleByTag(String tag) async {
    try {
      // Use the static method from CattleService
      return await CattleService.getCattleByTag(tag);
    } catch (e) {
      throw Exception('Failed to fetch cattle: $e');
    }
  }
}