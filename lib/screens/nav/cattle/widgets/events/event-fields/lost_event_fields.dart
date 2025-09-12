// lib/screens/nav/cattle/widgets/event_fields/lost_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_event_fields.dart';
import '../event_styled_text_field.dart';

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
        EventStyledTextField(
          label: 'Last Known Location',
          controller: widget.controllers['last_known_location'] ?? TextEditingController(),
          hint: 'Enter the last known location where the cattle was seen',
          icon: FontAwesomeIcons.locationDot,
          maxLines: 2,
        ),
      ],
    );
  }
}
