// lib/screens/nav/goat/widgets/event_fields/castrated_event_fields.dart

import 'package:flutter/material.dart';
import 'base_history_fields.dart';

class CastratedEventFields extends BaseEventFields {
  const CastratedEventFields({
    super.key,
    required super.controllers,
  });

  @override
  CastratedEventFieldsState createState() => CastratedEventFieldsState();
}

class CastratedEventFieldsState extends BaseEventFieldsState<CastratedEventFields> {
  @override
  bool needsTechnicians() => true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTechnicianDropdown(),
      ],
    );
  }
}