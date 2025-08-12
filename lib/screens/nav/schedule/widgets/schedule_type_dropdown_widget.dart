import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../models/schedule.dart';

class ScheduleTypeDropdown extends StatelessWidget {
  final String selectedType;
  final Function(String?) onChanged;

  const ScheduleTypeDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: ScheduleType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  _getTypeIcon(type),
                  const SizedBox(width: 12),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a type';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _getTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case ScheduleType.vaccination:
        icon = FontAwesomeIcons.syringe;
        color = Colors.green;
        break;
      case ScheduleType.feed:
        icon = FontAwesomeIcons.seedling;
        color = Colors.brown;
        break;
      case ScheduleType.weigh:
        icon = FontAwesomeIcons.weight;
        color = Colors.blue;
        break;
      case ScheduleType.deworming:
        icon = FontAwesomeIcons.kitMedical;
        color = Colors.orange;
        break;
      case ScheduleType.hoofTrimming:
        icon = FontAwesomeIcons.scissors;
        color = Colors.purple;
        break;
      default:
        icon = FontAwesomeIcons.calendar;
        color = Colors.grey;
    }

    return FaIcon(icon, color: color, size: 20);
  }
}