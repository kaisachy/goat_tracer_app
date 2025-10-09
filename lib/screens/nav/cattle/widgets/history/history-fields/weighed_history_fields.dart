// lib/screens/nav/cattle/widgets/event_fields/weighed_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';
import '../history_styled_text_field.dart';

class WeighedEventFields extends BaseEventFields {
  const WeighedEventFields({
    super.key,
    required super.controllers,
  });

  @override
  WeighedEventFieldsState createState() => WeighedEventFieldsState();
}

class WeighedEventFieldsState extends BaseEventFieldsState<WeighedEventFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HistoryStyledTextField(
          label: 'Weight Result (kg)',
          controller: widget.controllers['weighed_result']!,
          isNumber: true,
          hint: 'Enter weight in kg',
          icon: FontAwesomeIcons.weightScale,
        ),
      ],
    );
  }
}