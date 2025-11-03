// lib/screens/nav/cattle/widgets/history/history-fields/sick_history_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_history_fields.dart';
import '../history_styled_text_field.dart';

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
    final String? selected = diseaseTypeCtrl.text.isNotEmpty && diseases.contains(diseaseTypeCtrl.text) 
        ? diseaseTypeCtrl.text 
        : null;

    // Create dropdown items with empty state option
    final List<DropdownMenuItem<String?>> dropdownItems = [
      DropdownMenuItem<String?>(
        value: null,
        child: Row(
          children: [
            Icon(Icons.arrow_drop_down_circle_outlined, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select type of disease',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
      ...diseases.map((d) => DropdownMenuItem<String?>(
            value: d,
            child: Row(
              children: [
                const Icon(Icons.coronavirus_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          )),
    ];

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
            child: DropdownButton<String?>(
              value: selected,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: dropdownItems,
              onChanged: (val) {
                setState(() {
                  if (val == null) {
                    diseaseTypeCtrl.text = '';
                    diseaseOtherCtrl.text = '';
                  } else {
                    diseaseTypeCtrl.text = val;
                    if (val != 'Other') {
                      diseaseOtherCtrl.text = '';
                    }
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (diseaseTypeCtrl.text == 'Other')
          HistoryStyledTextField(
            label: 'If Other, please specify',
            controller: diseaseOtherCtrl,
            hint: 'Enter disease name...',
            icon: FontAwesomeIcons.keyboard,
          ),
      ],
    );
  }
}


