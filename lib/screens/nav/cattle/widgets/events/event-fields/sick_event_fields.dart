// lib/screens/nav/cattle/widgets/events/event-fields/sick_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_event_fields.dart';
import '../event_styled_text_field.dart';

class SickEventFields extends BaseEventFields {
  const SickEventFields({
    super.key,
    required super.controllers,
  });

  @override
  SickEventFieldsState createState() => SickEventFieldsState();
}

class SickEventFieldsState extends BaseEventFieldsState<SickEventFields> {
  @override
  bool needsTechnicians() => false;

  @override
  Widget build(BuildContext context) {
    final diseases = <String>[
      'Bovine Respiratory Disease',
      'Mastitis in Cows',
      'Calf Scour',
      'Pink Eye',
      'Bovine Viral Diarrhea (BVD)',
      'Mad Cow Diseases',
      'Footrot',
      'Foot and Mouth Disease (FMD)',
      'Blackleg',
      'Lumpy Skin Disease',
      'Ringworm',
      'Brucellosis',
      'Milk Fever in Cows',
      'Bovine tuberculosis (TB)',
      'Anaplasmosis',
      'Leptospirosis',
      'Coccidiosis',
      'Infectious Bovine Rhinotracheitis (IBR)',
      'Other',
    ];

    final TextEditingController diseaseTypeCtrl = widget.controllers['disease_type']!;
    final TextEditingController diseaseOtherCtrl = widget.controllers['disease_type_other']!;
    final String selected = diseaseTypeCtrl.text.isNotEmpty ? diseaseTypeCtrl.text : diseases.first;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: diseases.contains(selected) ? selected : 'Other',
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: diseases
                  .map((d) => DropdownMenuItem<String>(
                        value: d,
                        child: Row(
                          children: [
                            const Icon(Icons.coronavirus_rounded, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(d, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  diseaseTypeCtrl.text = val;
                  if (val != 'Other') {
                    diseaseOtherCtrl.text = '';
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if ((diseaseTypeCtrl.text.isEmpty && diseases.first == 'Other') || diseaseTypeCtrl.text == 'Other')
          EventStyledTextField(
            label: 'If Other, please specify',
            controller: diseaseOtherCtrl,
            hint: 'Enter disease name...',
            icon: FontAwesomeIcons.keyboard,
          ),
      ],
    );
  }
}


