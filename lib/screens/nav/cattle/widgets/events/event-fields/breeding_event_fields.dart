// lib/screens/nav/cattle/widgets/event_fields/breeding_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/services/auth_service.dart';
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
  String? _currentUserRole;
  bool _isLoadingRole = true;

  // Getter to access breeding type from parent
  String get breedingType => _breedingType;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final role = await AuthService.getUserRole();
      setState(() {
        _currentUserRole = role?.toLowerCase();
        _isLoadingRole = false;
      });
    } catch (e) {
      setState(() {
        _currentUserRole = 'farmer'; // Default to farmer if error
        _isLoadingRole = false;
      });
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

  void _onBreedingTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _breedingType = value;
        
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

  bool _canPerformBreedingType() {
    if (_isLoadingRole || _currentUserRole == null) return false;
    
    if (_breedingType == 'artificial_insemination') {
      // Only technician and pvo can perform AI
      return _currentUserRole == 'technician' || _currentUserRole == 'pvo';
    } else {
      // Only farmer can perform natural breeding
      return _currentUserRole == 'farmer';
    }
  }

  // Check if current user can perform the selected breeding type
  bool _canCurrentUserPerformBreeding() {
    if (_isLoadingRole || _currentUserRole == null) return false;
    
    if (_breedingType == 'artificial_insemination') {
      // Only technician and pvo can perform AI
      return _currentUserRole == 'technician' || _currentUserRole == 'pvo';
    } else {
      // Only farmer can perform natural breeding
      return _currentUserRole == 'farmer';
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