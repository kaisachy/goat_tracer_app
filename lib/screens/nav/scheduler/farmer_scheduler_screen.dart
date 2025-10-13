import 'package:flutter/material.dart';
import 'farmer_scheduler_content.dart';

class FarmerSchedulerScreen extends StatefulWidget {
  const FarmerSchedulerScreen({super.key});

  @override
  State<FarmerSchedulerScreen> createState() => _FarmerSchedulerScreenState();
}

class _FarmerSchedulerScreenState extends State<FarmerSchedulerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const FarmerSchedulerContentWidget(),
    );
  }
}
