// lib/screens/nav/cattle/widgets/event_fields/vaccinated_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_event_fields.dart';
import '../event_styled_text_field.dart';

class VaccinatedEventFields extends BaseEventFields {
  const VaccinatedEventFields({
    super.key,
    required super.controllers,
  });

  @override
  VaccinatedEventFieldsState createState() => VaccinatedEventFieldsState();
}

class VaccinatedEventFieldsState extends BaseEventFieldsState<VaccinatedEventFields> {
  @override
  bool needsTechnicians() => true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EventStyledTextField(
          label: 'Vaccine Given',
          controller: widget.controllers['medicine_given']!,
          hint: 'Name of vaccine',
          icon: FontAwesomeIcons.syringe,
        ),
        buildTechnicianDropdown(),
      ],
    );
  }
}