import 'package:flutter/material.dart';
import '../../../../models/schedule.dart';

class SchedulePriorityDropdown extends StatelessWidget {
  final String selectedPriority;
  final Function(String?) onChanged;

  const SchedulePriorityDropdown({
    super.key,
    required this.selectedPriority,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedPriority,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: SchedulePriority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: _getPriorityColor(priority),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(priority),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case SchedulePriority.high:
        return Colors.red;
      case SchedulePriority.medium:
        return Colors.orange;
      case SchedulePriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}