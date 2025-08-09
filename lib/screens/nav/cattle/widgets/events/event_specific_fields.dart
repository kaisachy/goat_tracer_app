// lib/screens/nav/cattle/widgets/event_specific_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Import event field widgets
import '../../../../../constants/app_colors.dart';
import '../../../../../utils/event_type_utils.dart';
import 'event-fields/treated_event_fields.dart';
import 'event-fields/breeding_event_fields.dart';
import 'event-fields/weighed_event_fields.dart';
import 'event-fields/gives_birth_event_fields.dart';
import 'event-fields/vaccinated_event_fields.dart';
import 'event-fields/pregnant_event_fields.dart';
import 'event-fields/deworming_event_fields.dart';
import 'event-fields/castrated_event_fields.dart';
import 'event-fields/other_event_fields.dart';

class EventSpecificFields extends StatefulWidget {
  final String selectedEventType;
  final Map<String, TextEditingController> controllers;
  final String? cattleTag;
  final Map<String, dynamic>? temporaryCalfData;
  final VoidCallback? onEditCalfPressed;
  final bool showReturnToHeat;

  const EventSpecificFields({
    super.key,
    required this.selectedEventType,
    required this.controllers,
    this.cattleTag,
    this.temporaryCalfData,
    this.onEditCalfPressed,
    required this.showReturnToHeat,
  });

  @override
  EventSpecificFieldsState createState() => EventSpecificFieldsState();
}

class EventSpecificFieldsState extends State<EventSpecificFields> {
  Map<String, dynamic>? _newCalfData;
  final GlobalKey<BreedingEventFieldsState> _breedingFieldsKey = GlobalKey<BreedingEventFieldsState>();
  final GlobalKey<PregnantEventFieldsState> _pregnantFieldsKey = GlobalKey<PregnantEventFieldsState>();

  @override
  void initState() {
    super.initState();
    // Initialize calf data from parent if available
    if (widget.temporaryCalfData != null) {
      _newCalfData = widget.temporaryCalfData;
    }
  }

  @override
  void didUpdateWidget(EventSpecificFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update calf data when parent updates it
    if (widget.temporaryCalfData != oldWidget.temporaryCalfData) {
      setState(() {
        _newCalfData = widget.temporaryCalfData;
      });
    }
  }

  void updateCalfData(Map<String, dynamic>? calfData) {
    setState(() {
      _newCalfData = calfData;
      if (calfData != null) {
        widget.controllers['calf_tag']?.text = calfData['tag_no'] ?? '';
      }
    });
  }

  Widget _buildEventSpecificFields() {
    switch (widget.selectedEventType.toLowerCase()) {
      case 'dry off':
      case 'aborted pregnancy':
      case 'hoof trimming':
      case 'weaned':
        return const SizedBox.shrink();

      case 'treated':
        return TreatedEventFields(
          controllers: widget.controllers,
        );

      case 'breeding':
        return BreedingEventFields(
          key: _breedingFieldsKey,
          controllers: widget.controllers,
        );

      case 'weighed':
        return WeighedEventFields(
          controllers: widget.controllers,
        );

      case 'gives birth':
        return GivesBirthEventFields(
          controllers: widget.controllers,
          cattleTag: widget.cattleTag,
          temporaryCalfData: _newCalfData,
          onEditCalfPressed: widget.onEditCalfPressed,
          onCalfDataChanged: updateCalfData,
        );

      case 'vaccinated':
        return VaccinatedEventFields(
          controllers: widget.controllers,
        );

      case 'pregnant':
        return PregnantEventFields(
          key: _pregnantFieldsKey,
          controllers: widget.controllers,
        );

      case 'deworming':
        return DewormingEventFields(
          controllers: widget.controllers,
        );

      case 'castrated':
        return CastratedEventFields(
          controllers: widget.controllers,
        );

      case 'other':
      default:
        return OtherEventFields(
          controllers: widget.controllers,
        );
    }
  }

  // Public methods for parent widgets
  Map<String, dynamic>? getNewCalfData() {
    return _newCalfData;
  }

  bool hasCalfData() {
    return _newCalfData != null;
  }

  String? getCalfTag() {
    return _newCalfData?['tag_no'];
  }

  Map<String, dynamic>? getFullCalfData() {
    return _newCalfData?['fullCalfData'];
  }

  bool isCalfReadyForRegistration() {
    return _newCalfData != null &&
        _newCalfData!['fullCalfData'] != null &&
        _newCalfData!['pendingOperation'] != null;
  }

  // Method to calculate return to heat date for breeding event
  void calculateAndDisplayReturnToHeatDate(DateTime eventDate) {
    if (widget.selectedEventType.toLowerCase() == 'breeding') {
      _breedingFieldsKey.currentState?.calculateAndDisplayReturnToHeatDate(eventDate);
    }
  }

  // Method to calculate delivery date for pregnant event
  void calculateAndDisplayDeliveryDate(DateTime breedingDate) {
    if (widget.selectedEventType.toLowerCase() == 'pregnant') {
      _pregnantFieldsKey.currentState?.calculateAndDisplayDeliveryDate(breedingDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedEventType == 'Select type of event' ||
        widget.selectedEventType == 'Loading cattle information...') {
      return const SizedBox.shrink();
    }

    final eventFields = _buildEventSpecificFields();

    // If no fields are returned, don't show the container
    if (eventFields is SizedBox && eventFields.width == 0.0) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EventTypeUtils.getEventColor(widget.selectedEventType).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FontAwesomeIcons.clipboardList,
                      color: EventTypeUtils.getEventColor(widget.selectedEventType),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.selectedEventType} Details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: eventFields,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}