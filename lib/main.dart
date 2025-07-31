import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/secure_storage_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cattle Tracer',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const SplashScreen(), // Entry point
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
