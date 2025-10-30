// lib/screens/nav/cattle/widgets/event_fields/mortality_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';
import '../history_styled_text_field.dart';

class MortalityEventFields extends BaseEventFields {
  const MortalityEventFields({
    super.key,
    required super.controllers,
  });

  @override
  MortalityEventFieldsState createState() => MortalityEventFieldsState();
}

class MortalityEventFieldsState extends BaseEventFieldsState<MortalityEventFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HistoryStyledTextField(
          label: 'Cause of Death',
          controller: widget.controllers['cause_of_death']!,
          hint: 'Enter the cause of death (required)',
          icon: FontAwesomeIcons.heartCrack,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Cause of death is required';
            }
            return null;
          },
        ),

      ],
    );
  }
}


