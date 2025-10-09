// lib/screens/nav/cattle/widgets/event_fields/pregnant_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';

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
  void onBullsLoaded() {
    print('DEBUG: PregnantEventFields onBullsLoaded called');
    // If semen_used has a value but bull_tag is empty, try to derive bull tag from semen label
    final semenText = widget.controllers['semen_used']?.text ?? '';
    final bullText = widget.controllers['bull_tag']?.text ?? '';
    print('DEBUG: Current semen: $semenText, bull: $bullText');
    
    if (semenText.isNotEmpty && bullText.isEmpty) {
      print('DEBUG: Extracting bull tag from semen in onBullsLoaded');
      // Expected semen format examples:
      // - "TAG123 (Name) Semen"
      // - "TAG123 Semen"
      // - "TAG123"
      String extracted = semenText.trim();
      // Remove trailing word 'Semen' if present
      if (extracted.toLowerCase().endsWith('semen')) {
        extracted = extracted.substring(0, extracted.length - 5).trim();
      }
      // Take first token as tag (up to first space or '(')
      int stop = extracted.indexOf(' ');
      int paren = extracted.indexOf('(');
      if (stop == -1 || (paren != -1 && paren < stop)) {
        stop = paren;
      }
      final bullTag = stop == -1 ? extracted : extracted.substring(0, stop).trim();
      print('DEBUG: Extracted bull tag: $bullTag');
      if (bullTag.isNotEmpty) {
        widget.controllers['bull_tag']?.text = bullTag;
        print('DEBUG: Set bull_tag controller to: $bullTag');
        if (mounted) setState(() {});
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