// lib/screens/nav/cattle/widgets/event_fields/pregnant_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_event_fields.dart';

class PregnantEventFields extends BaseEventFields {
  const PregnantEventFields({
    super.key,
    required super.controllers,
  });

  @override
  PregnantEventFieldsState createState() => PregnantEventFieldsState();
}

class PregnantEventFieldsState extends BaseEventFieldsState<PregnantEventFields> {
  @override
  bool needsBulls() => true;

  @override
  void setupEventDateListeners() {
    // Add listener for breeding date changes in 'pregnant' event type
    if (widget.controllers['breeding_date'] != null) {
      widget.controllers['breeding_date']!.removeListener(onBreedingDateChanged);
      widget.controllers['breeding_date']!.addListener(onBreedingDateChanged);
    }
  }

  @override
  void removeEventDateListeners() {
    if (widget.controllers['breeding_date'] != null) {
      widget.controllers['breeding_date']!.removeListener(onBreedingDateChanged);
    }
  }

  void onBreedingDateChanged() {
    final breedingDateText = widget.controllers['breeding_date']?.text ?? '';

    if (breedingDateText.isNotEmpty) {
      try {
        final breedingDate = DateTime.parse(breedingDateText);
        calculateAndDisplayDeliveryDate(breedingDate);
      } catch (e) {
        if (widget.controllers['expected_delivery_date'] != null) {
          widget.controllers['expected_delivery_date']!.clear();
          if (mounted) {
            setState(() {});
          }
        }
      }
    } else {
      if (widget.controllers['expected_delivery_date'] != null) {
        widget.controllers['expected_delivery_date']!.clear();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildDateField(
          label: 'Breeding Date',
          controller: widget.controllers['breeding_date']!,
          icon: FontAwesomeIcons.calendar,
          showCalendarIcon: true,
          onDateSelected: (date) => calculateAndDisplayDeliveryDate(date),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDateField(
                label: 'Expected Delivery Date',
                controller: widget.controllers['expected_delivery_date']!,
                icon: FontAwesomeIcons.calendarDays,
                readOnly: true,
                showCalendarIcon: false,
              ),
            ],
          ),
        ),
        buildBullDropdown(),
      ],
    );
  }
}