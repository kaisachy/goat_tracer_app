// lib/screens/nav/goat/widgets/event_fields/lost_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';
import '../history_styled_text_field.dart';

class LostEventFields extends BaseEventFields {
  const LostEventFields({
    super.key,
    required super.controllers,
  });

  @override
  LostEventFieldsState createState() => LostEventFieldsState();
}

class LostEventFieldsState extends BaseEventFieldsState<LostEventFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HistoryStyledTextField(
          label: 'Last Known Location',
          controller: widget.controllers['last_known_location'] ?? TextEditingController(),
          hint: 'Enter the last known location where the goat was seen',
          icon: FontAwesomeIcons.locationDot,
          maxLines: 2,
        ),
      ],
    );
  }
}
