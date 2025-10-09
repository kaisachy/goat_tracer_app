// lib/screens/nav/cattle/widgets/event_fields/deworming_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';
import '../history_styled_text_field.dart';

class DewormingEventFields extends BaseEventFields {
  const DewormingEventFields({
    super.key,
    required super.controllers,
  });

  @override
  DewormingEventFieldsState createState() => DewormingEventFieldsState();
}

class DewormingEventFieldsState extends BaseEventFieldsState<DewormingEventFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HistoryStyledTextField(
          label: 'Deworming Medicine',
          controller: widget.controllers['medicine_given']!,
          hint: 'Name and dosage',
          icon: FontAwesomeIcons.pills,
        ),
      ],
    );
  }
}