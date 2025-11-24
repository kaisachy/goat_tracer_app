import 'package:flutter/material.dart';
import 'farmer_scheduler_content.dart';

class FarmerSchedulerScreen extends StatefulWidget {
  const FarmerSchedulerScreen({super.key});

  @override
  FarmerSchedulerScreenState createState() => FarmerSchedulerScreenState();
}

class FarmerSchedulerScreenState extends State<FarmerSchedulerScreen> {
  final GlobalKey<FarmerSchedulerContentWidgetState> _contentKey =
      GlobalKey<FarmerSchedulerContentWidgetState>();

  void startUserGuide() {
    _contentKey.currentState?.startUserGuide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FarmerSchedulerContentWidget(key: _contentKey),
    );
  }
}
