// lib/screens/nav/cattle/widgets/event_fields/other_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_event_fields.dart';
import '../event_styled_text_field.dart';

class OtherEventFields extends BaseEventFields {
  const OtherEventFields({
    super.key,
    required super.controllers,
  });

  @override
  OtherEventFieldsState createState() => OtherEventFieldsState();
}

class OtherEventFieldsState extends BaseEventFieldsState<OtherEventFields> {
  @override
  bool needsTechnicians() => true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EventStyledTextField(
          label: 'Bull Tag',
          controller: widget.controllers['bull_tag']!,
          hint: 'Related bull tag (optional)',
          icon: FontAwesomeIcons.mars,
        ),
        EventStyledTextField(
          label: 'Calf Tag',
          controller: widget.controllers['calf_tag']!,
          hint: 'Related calf tag (optional)',
          icon: FontAwesomeIcons.baby,
        ),
        buildTechnicianDropdown(),
      ],
    );
  }
}