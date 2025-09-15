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
  String _breedingType = 'artificial_insemination'; // Default to AI

  // Getter to access breeding type from parent
  String get breedingType => _breedingType;

  @override
  void initState() {
    super.initState();
    // Initialize breeding type in controller
    if (widget.controllers['breeding_type'] != null) {
      final existingValue = widget.controllers['breeding_type']!.text;
      if (existingValue.isNotEmpty) {
        // Use existing value (for editing)
        _breedingType = existingValue;
        print('DEBUG: Using existing breeding_type from controller: $existingValue');
      } else {
        // Set default value (for new events)
        widget.controllers['breeding_type']!.text = _breedingType;
        print('DEBUG: Initialized breeding_type controller with default: $_breedingType');
      }

      // Listen for external updates to breeding_type (e.g., inference during edit)
      widget.controllers['breeding_type']!.addListener(_onExternalBreedingTypeControllerChanged);
    } else {
      print('DEBUG: breeding_type controller is null!');
    }
  }

  @override
  void onBullsLoaded() {
    // Ensure semen dropdown preselects stored value when editing AI events
    if (_breedingType == 'artificial_insemination') {
      final currentSemen = widget.controllers['semen_used']?.text ?? '';
      if (currentSemen.isNotEmpty && mounted) {
        setState(() {});
      }
    }
  }

  @override
  bool needsBulls() => true; // Still need bulls for semen dropdown

  @override
  bool needsTechnicians() => _breedingType == 'artificial_insemination';

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
    if (widget.controllers['breeding_type'] != null) {
      widget.controllers['breeding_type']!.removeListener(_onExternalBreedingTypeControllerChanged);
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
      // Do not mirror semen to bull_tag for AI (bull_tag is only for Natural Breeding)
      print('DEBUG: Semen selected (pure tag): $semenUsed');
    } else {
      // Clear bull_tag if no semen selected
      if (widget.controllers['bull_tag'] != null) {
        widget.controllers['bull_tag']!.clear();
      }
    }
  }

  void _onBreedingTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _breedingType = value;
        
        // Store breeding type in controller for form submission
        if (widget.controllers['breeding_type'] != null) {
          widget.controllers['breeding_type']!.text = value;
          print('DEBUG: Updated breeding_type controller with: $value');
        } else {
          print('DEBUG: breeding_type controller is null in _onBreedingTypeChanged!');
        }
        
        // Clear fields when switching breeding types
        if (value == 'natural_breeding') {
          // Clear AI-specific fields
          widget.controllers['semen_used']?.clear();
          widget.controllers['technician']?.clear();
        } else {
          // Clear natural breeding fields
          widget.controllers['bull_tag']?.clear();
        }
      });
    }
  }

  // Respond to external changes to the breeding_type controller (e.g., when editing)
  void _onExternalBreedingTypeControllerChanged() {
    final controllerValue = widget.controllers['breeding_type']?.text ?? '';
    if (controllerValue.isEmpty) return;
    if (controllerValue != _breedingType) {
      print('DEBUG: External breeding_type change detected: "$controllerValue" (was $_breedingType)');
      setState(() {
        _breedingType = controllerValue;
        // When switching types externally, do not nuke user data unnecessarily;
        // just ensure dependent UI updates (listeners already handle field syncs)
      });
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
        // Breeding Type Selection
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Breeding Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
                             Column(
                 children: [
                   RadioListTile<String>(
                     title: const Text('Artificial Insemination'),
                     value: 'artificial_insemination',
                     groupValue: _breedingType,
                     onChanged: _onBreedingTypeChanged,
                     contentPadding: EdgeInsets.zero,
                     visualDensity: VisualDensity.compact,
                   ),
                   RadioListTile<String>(
                     title: const Text('Natural Breeding'),
                     value: 'natural_breeding',
                     groupValue: _breedingType,
                     onChanged: _onBreedingTypeChanged,
                     contentPadding: EdgeInsets.zero,
                     visualDensity: VisualDensity.compact,
                   ),
                 ],
               ),
            ],
          ),
        ),

        // AI-specific fields
        if (_breedingType == 'artificial_insemination') ...[
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
        ],

        // Natural breeding fields
        if (_breedingType == 'natural_breeding') ...[
          // Bull selection dropdown (without farmer field, simplified label)
          buildBullDropdownForNaturalBreeding(),
        ],

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