import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final String userEmail;

  const DashboardScreen({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Welcome to Dashboard, $userEmail!'),
    );
  }
}
