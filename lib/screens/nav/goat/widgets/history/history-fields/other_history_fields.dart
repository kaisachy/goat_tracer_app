// lib/screens/nav/goat/widgets/event_fields/other_event_fields.dart

import 'package:flutter/material.dart';
import 'base_history_fields.dart';

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
  bool needsTechnicians() => false;

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // No additional fields for "Other" events - only notes
      ],
    );
  }
}