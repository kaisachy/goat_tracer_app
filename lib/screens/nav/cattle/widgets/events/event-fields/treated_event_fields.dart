// lib/screens/nav/cattle/widgets/event_fields/treated_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_event_fields.dart';
import '../event_styled_text_field.dart';

class TreatedEventFields extends BaseEventFields {
  const TreatedEventFields({
    super.key,
    required super.controllers,
  });

  @override
  TreatedEventFieldsState createState() => TreatedEventFieldsState();
}

class TreatedEventFieldsState extends BaseEventFieldsState<TreatedEventFields> {
  @override
  bool needsTechnicians() => true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EventStyledTextField(
          label: 'Sickness Symptoms',
          controller: widget.controllers['sickness_symptoms']!,
          maxLines: 3,
          hint: 'Describe the symptoms...',
          icon: FontAwesomeIcons.thermometer,
        ),
        EventStyledTextField(
          label: 'Diagnosis',
          controller: widget.controllers['diagnosis']!,
          maxLines: 2,
          hint: 'Medical diagnosis...',
          icon: FontAwesomeIcons.stethoscope,
        ),
        buildTechnicianDropdown(),
        EventStyledTextField(
          label: 'Medicine Given',
          controller: widget.controllers['medicine_given']!,
          hint: 'Name and dosage of medicine',
          icon: FontAwesomeIcons.pills,
        ),
      ],
    );
  }
}