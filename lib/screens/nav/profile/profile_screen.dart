import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String userEmail;

  const ProfileScreen({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Welcome to Profile, $userEmail!'),
    );
  }
}
