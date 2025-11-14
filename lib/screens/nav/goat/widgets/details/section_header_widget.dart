// lib/screens/nav/goat/widgets/shared/section_header_widget.dart
import 'package:flutter/cupertino.dart';

class SectionHeaderWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const SectionHeaderWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}