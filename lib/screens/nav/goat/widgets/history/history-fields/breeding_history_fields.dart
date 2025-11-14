// lib/screens/nav/goat/widgets/event_fields/breeding_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';

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
        debugPrint('DEBUG: Using existing breeding_type from controller: $existingValue');
      } else {
        // Set default value (for new history)
        widget.controllers['breeding_type']!.text = _breedingType;
        debugPrint('DEBUG: Initialized breeding_type controller with default: $_breedingType');
      }

      // Listen for external updates to breeding_type (e.g., inference during edit)
      widget.controllers['breeding_type']!.addListener(_onExternalBreedingTypeControllerChanged);
    } else {
      debugPrint('DEBUG: breeding_type controller is null!');
    }
  }

  @override
  void onBucksLoaded() {
    // Ensure semen dropdown preselects stored value when editing AI history
    if (_breedingType == 'artificial_insemination') {
      final currentSemen = widget.controllers['semen_used']?.text ?? '';
      if (currentSemen.isNotEmpty && mounted) {
        setState(() {});
      }
    }
  }

  @override
  bool needsBucks() => true; // Still need Bucks for semen dropdown

  @override
  bool needsTechnicians() => _breedingType == 'artificial_insemination';

  @override
  void setupEventDateListeners() {
    // Add listener for event date changes in 'breeding' event type
    if (widget.controllers['history_date'] != null) {
      widget.controllers['history_date']!.removeListener(onEventDateChanged);
      widget.controllers['history_date']!.addListener(onEventDateChanged);
    }

    // Add listener for semen selection changes to update Buck_tag
    if (widget.controllers['semen_used'] != null) {
      widget.controllers['semen_used']!.removeListener(onSemenChanged);
      widget.controllers['semen_used']!.addListener(onSemenChanged);
    }
  }

  @override
  void removeEventDateListeners() {
    if (widget.controllers['history_date'] != null) {
      widget.controllers['history_date']!.removeListener(onEventDateChanged);
    }
    if (widget.controllers['semen_used'] != null) {
      widget.controllers['semen_used']!.removeListener(onSemenChanged);
    }
    if (widget.controllers['breeding_type'] != null) {
      widget.controllers['breeding_type']!.removeListener(_onExternalBreedingTypeControllerChanged);
    }
  }

  void onEventDateChanged() {
    final eventDateText = widget.controllers['history_date']?.text ?? '';

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
      // Do not mirror semen to Buck_tag for AI (Buck_tag is only for Natural Breeding)
      debugPrint('DEBUG: Semen selected (pure tag): $semenUsed');
    } else {
      // Clear Buck_tag if no semen selected
      if (widget.controllers['Buck_tag'] != null) {
        widget.controllers['Buck_tag']!.clear();
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
          debugPrint('DEBUG: Updated breeding_type controller with: $value');
        } else {
          debugPrint('DEBUG: breeding_type controller is null in _onBreedingTypeChanged!');
        }
        
        // Clear fields when switching breeding types
        if (value == 'natural_breeding') {
          // Clear AI-specific fields
          widget.controllers['semen_used']?.clear();
          widget.controllers['technician']?.clear();
        } else {
          // Clear natural breeding fields
          widget.controllers['Buck_tag']?.clear();
        }
      });
    }
  }

  // Respond to external changes to the breeding_type controller (e.g., when editing)
  void _onExternalBreedingTypeControllerChanged() {
    final controllerValue = widget.controllers['breeding_type']?.text ?? '';
    if (controllerValue.isEmpty) return;
    if (controllerValue != _breedingType) {
      debugPrint('DEBUG: External breeding_type change detected: "$controllerValue" (was $_breedingType)');
      setState(() {
        _breedingType = controllerValue;
        // When switching types externally, do not nuke user data unnecessarily;
        // just ensure dependent UI updates (listeners already handle field syncs)
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: BreedingEventFields build() called');
    debugPrint('DEBUG: needsBucks() returns: ${needsBucks()}');
    debugPrint('DEBUG: needsTechnicians() returns: ${needsTechnicians()}');
    debugPrint('DEBUG: semen_used controller value: "${widget.controllers['semen_used']?.text}"');
    debugPrint('DEBUG: Buck_tag controller value: "${widget.controllers['Buck_tag']?.text}"');

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
                     title: const Text(
                       'Artificial Insemination',
                       overflow: TextOverflow.ellipsis,
                       maxLines: 1,
                     ),
                     value: 'artificial_insemination',
                     groupValue: _breedingType,
                     onChanged: _onBreedingTypeChanged,
                     contentPadding: EdgeInsets.zero,
                     visualDensity: VisualDensity.compact,
                   ),
                   RadioListTile<String>(
                     title: const Text(
                       'Natural Breeding',
                       overflow: TextOverflow.ellipsis,
                       maxLines: 1,
                     ),
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
          // Semen dropdown (this will populate the Buck_tag automatically)
          Builder(
            builder: (context) {
              debugPrint('DEBUG: About to call buildSemenDropdown()');
              final semenWidget = buildSemenDropdown();
              debugPrint('DEBUG: buildSemenDropdown() returned widget type: ${semenWidget.runtimeType}');
              return semenWidget;
            },
          ),

          // Technician dropdown
          buildTechnicianDropdown(),
        ],

        // Natural breeding fields
        if (_breedingType == 'natural_breeding') ...[
          // Buck selection dropdown (without farmer field, simplified label)
          buildBuckDropdownForNaturalBreeding(),
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