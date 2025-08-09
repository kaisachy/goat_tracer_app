// lib/screens/nav/cattle/widgets/event_type_dropdown.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../models/cattle.dart';
import '../../../../constants/app_colors.dart';
import '../../../../utils/event_type_utils.dart';

class EventTypeDropdown extends StatefulWidget {
  final Cattle? cattleDetails;
  final String selectedEventType;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<String?> onEventTypeChanged;
  final Function(DateTime)? onEventDateSelected; // Add callback for event date selection

  const EventTypeDropdown({
    super.key,
    required this.cattleDetails,
    required this.selectedEventType,
    required this.controllers,
    required this.onEventTypeChanged,
    this.onEventDateSelected, // Add this parameter
  });

  @override
  EventTypeDropdownState createState() => EventTypeDropdownState();
}

class EventTypeDropdownState extends State<EventTypeDropdown> {
  List<String> get eventTypes {
    return EventTypeUtils.getEventTypesForGender(widget.cattleDetails?.gender);
  }

  // Helper method to show date picker and update controller
  Future<void> _selectEventDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      controller.text = formattedDate;

      print('Event date selected in dropdown: $formattedDate'); // Debug print

      // FIXED: Trigger the callback to notify parent widget about date selection
      if (widget.onEventDateSelected != null) {
        print('Calling onEventDateSelected callback with date: $picked'); // Debug print
        widget.onEventDateSelected!(picked);
      } else {
        print('onEventDateSelected callback is null!'); // Debug print
      }

      // Force a rebuild to ensure UI updates
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildEventDateField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          // Removed suffixIcon
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _selectEventDate(context, controller),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Event date is required';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15), // Fixed color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note, // Fixed icon
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Event Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Type Dropdown
          DropdownButtonFormField<String>(
            value: eventTypes.contains(widget.selectedEventType) ? widget.selectedEventType : 'Select type of event',
            items: eventTypes.map((type) {
              final isPlaceholder = type == 'Select type of event';
              final isLoading = type == 'Loading cattle information...';

              return DropdownMenuItem(
                value: type,
                enabled: !isLoading,
                child: isPlaceholder || isLoading
                    ? Text(
                  type,
                  style: TextStyle(
                    color: isLoading
                        ? Colors.grey
                        : AppColors.textSecondary.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                )
                    : Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: EventTypeUtils.getEventTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        EventTypeUtils.getEventTypeIcon(type),
                        size: 16,
                        color: EventTypeUtils.getEventTypeColor(type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (BuildContext context) {
              return eventTypes.map<Widget>((String value) {
                if (value == 'Select type of event') {
                  return Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                if (value == 'Loading cattle information...') {
                  return Text(
                    value,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                return Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
            onChanged: widget.cattleDetails == null ? null : widget.onEventTypeChanged,
            decoration: InputDecoration(
              labelText: 'Event Type',
              prefixIcon: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: EventTypeUtils.getEventTypeColor(widget.selectedEventType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.selectedEventType == 'Select type of event'
                        ? Icons.event_note
                        : EventTypeUtils.getEventTypeIcon(widget.selectedEventType),
                    color: widget.selectedEventType == 'Select type of event'
                        ? AppColors.lightGreen
                        : EventTypeUtils.getEventTypeColor(widget.selectedEventType),
                    size: 18,
                  ),
                ),
              ),
              labelStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: AppColors.lightGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppColors.vibrantGreen,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value == 'Select type of event') {
                return 'Please select an event type';
              }
              if (value == 'Loading cattle information...') {
                return 'Please wait for cattle information to load';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Event Date with Calendar Picker
          _buildEventDateField(
            label: 'Event Date',
            controller: widget.controllers['event_date']!,
            hint: 'Select event date',
            icon: FontAwesomeIcons.calendarDays,
          ),
        ],
      ),
    );
  }
}