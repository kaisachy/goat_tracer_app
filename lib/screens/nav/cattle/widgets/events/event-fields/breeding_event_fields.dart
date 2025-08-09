// lib/screens/nav/cattle/widgets/event_fields/breeding_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_event_fields.dart';

class BreedingEventFields extends BaseEventFields {
  const BreedingEventFields({
    super.key,
    required super.controllers,
  });

  @override
  BreedingEventFieldsState createState() => BreedingEventFieldsState();
}

class BreedingEventFieldsState extends BaseEventFieldsState<BreedingEventFields> {
  @override
  bool needsBulls() => true; // Still need bulls for semen dropdown

  @override
  bool needsTechnicians() => true;

  @override
  void setupEventDateListeners() {
    // Add listener for event date changes in 'breeding' event type
    if (widget.controllers['event_date'] != null) {
      widget.controllers['event_date']!.removeListener(onEventDateChanged);
      widget.controllers['event_date']!.addListener(onEventDateChanged);
    }

    // Add listener for semen selection changes to update bull_tag
    if (widget.controllers['semen_used'] != null) {
      widget.controllers['semen_used']!.removeListener(onSemenChanged);
      widget.controllers['semen_used']!.addListener(onSemenChanged);
    }
  }

  @override
  void removeEventDateListeners() {
    if (widget.controllers['event_date'] != null) {
      widget.controllers['event_date']!.removeListener(onEventDateChanged);
    }
    if (widget.controllers['semen_used'] != null) {
      widget.controllers['semen_used']!.removeListener(onSemenChanged);
    }
  }

  void onEventDateChanged() {
    final eventDateText = widget.controllers['event_date']?.text ?? '';

    if (eventDateText.isNotEmpty) {
      try {
        DateTime eventDate = DateTime.parse(eventDateText);
        calculateAndDisplayReturnToHeatDate(eventDate);
      } catch (e) {
        if (widget.controllers['estimated_return_date'] != null) {
          widget.controllers['estimated_return_date']!.clear();
          if (mounted) {
            setState(() {});
          }
        }
      }
    } else {
      if (widget.controllers['estimated_return_date'] != null) {
        widget.controllers['estimated_return_date']!.clear();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void onSemenChanged() {
    final semenUsed = widget.controllers['semen_used']?.text ?? '';

    if (semenUsed.isNotEmpty) {
      // Extract bull tag from semen selection (format: "TAG123 (Name) Semen" or "TAG123 Semen")
      String bullTag = '';
      if (semenUsed.contains(' Semen')) {
        String tagPart = semenUsed.replaceAll(' Semen', '');
        // Handle both formats: "TAG123 (Name)" and "TAG123"
        if (tagPart.contains(' (') && tagPart.contains(')')) {
          bullTag = tagPart.split(' (')[0];
        } else {
          bullTag = tagPart;
        }
      }

      // Update the bull_tag controller
      if (widget.controllers['bull_tag'] != null) {
        widget.controllers['bull_tag']!.text = bullTag;
      }

      print('DEBUG: Semen selected: $semenUsed, extracted bull tag: $bullTag');
    } else {
      // Clear bull_tag if no semen selected
      if (widget.controllers['bull_tag'] != null) {
        widget.controllers['bull_tag']!.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: BreedingEventFields build() called');
    print('DEBUG: needsBulls() returns: ${needsBulls()}');
    print('DEBUG: needsTechnicians() returns: ${needsTechnicians()}');
    print('DEBUG: semen_used controller value: "${widget.controllers['semen_used']?.text}"');
    print('DEBUG: bull_tag controller value: "${widget.controllers['bull_tag']?.text}"');

    return Column(
      children: [
        // Semen dropdown (this will populate the bull_tag automatically)
        Builder(
          builder: (context) {
            print('DEBUG: About to call buildSemenDropdown()');
            final semenWidget = buildSemenDropdown();
            print('DEBUG: buildSemenDropdown() returned widget type: ${semenWidget.runtimeType}');
            return semenWidget;
          },
        ),

        // Technician dropdown
        buildTechnicianDropdown(),

        // Estimated return to heat date (read-only, calculated)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDateField(
                label: 'Estimated Return to Heat Date',
                controller: widget.controllers['estimated_return_date']!,
                icon: FontAwesomeIcons.calendar,
                readOnly: true,
                showCalendarIcon: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}