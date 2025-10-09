// lib/screens/nav/cattle/widgets/event_fields/treated_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';
import '../history_styled_text_field.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_history_service.dart';

class TreatedEventFields extends BaseEventFields {
  const TreatedEventFields({
    super.key,
    required super.controllers,
    this.cattleTag,
  });

  final String? cattleTag;

  @override
  TreatedEventFieldsState createState() => TreatedEventFieldsState();
}

class TreatedEventFieldsState extends BaseEventFieldsState<TreatedEventFields> {
  bool _loadingDisease = false;

  @override
  void initState() {
    super.initState();
    _prefillDiseaseTypeFromLatestSickEvent();
  }

  Future<void> _prefillDiseaseTypeFromLatestSickEvent() async {
    final tag = widget.cattleTag?.trim();
    if (tag == null || tag.isEmpty) return;
    setState(() => _loadingDisease = true);
    try {
      final events = await CattleHistoryService.getCattleHistoryByTag(tag);
      events.sort((a, b) {
        final ad = DateTime.tryParse(a['event_date']?.toString() ?? '') ?? DateTime(1900);
        final bd = DateTime.tryParse(b['event_date']?.toString() ?? '') ?? DateTime(1900);
        return bd.compareTo(ad);
      });
      final latestSick = events.firstWhere(
        (e) => (e['event_type']?.toString().toLowerCase() ?? '') == 'sick',
        orElse: () => {},
      );
      if (latestSick.isNotEmpty) {
        final dt = latestSick['disease_type']?.toString() ?? '';
        if (dt.isNotEmpty) {
          widget.controllers['disease_type']?.text = dt;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingDisease = false);
  }
  @override
  bool needsTechnicians() => true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Disease type (auto-filled from latest Sick event, locked)
        HistoryStyledTextField(
          label: 'Type of Disease',
          controller: widget.controllers['disease_type']!,
          hint: _loadingDisease ? 'Loading latest disease...' : 'Type of disease',
          icon: FontAwesomeIcons.virus,
          readOnly: true,
        ),
        HistoryStyledTextField(
          label: 'Diagnosis',
          controller: widget.controllers['diagnosis']!,
          maxLines: 2,
          hint: 'Medical diagnosis...',
          icon: FontAwesomeIcons.stethoscope,
        ),
        buildTechnicianDropdown(),
        HistoryStyledTextField(
          label: 'Medicine Given',
          controller: widget.controllers['medicine_given']!,
          hint: 'Name and dosage of medicine',
          icon: FontAwesomeIcons.pills,
        ),
      ],
    );
  }
}