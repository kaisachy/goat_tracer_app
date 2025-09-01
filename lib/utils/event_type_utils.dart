// lib/screens/nav/cattle/utils/event_type_utils.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';

class EventTypeUtils {
  static List<String> getEventTypesForGender(String? gender, {String? classification}) {
    final baseTypes = ['Select type of event'];

    if (gender == null) {
      return [...baseTypes, 'Loading cattle information...'];
    }

    final genderLower = gender.toLowerCase().trim();
    final classificationLower = classification?.toLowerCase().trim();

    // Debug logging
    print('DEBUG: Gender: $gender, Classification: $classification');
    print('DEBUG: Gender lower: $genderLower, Classification lower: $classificationLower');

    // If cattle is a Calf, exclude breeding-related events
    final isCalf = classificationLower == 'calf';
    print('DEBUG: Is Calf: $isCalf');

    if (genderLower == 'female') {
      final femaleEvents = [
        ...baseTypes,
        'Dry off',
        'Treated',
        'Weighed',
        'Vaccinated',
        'Deworming',
        'Hoof Trimming',
        'Other',
      ];

      // Only add breeding-related events if not a Calf
      if (!isCalf) {
        femaleEvents.addAll([
          'Breeding',
          'Gives Birth',
          'Pregnant',
          'Aborted Pregnancy',
        ]);
        print('DEBUG: Added breeding events for non-calf female');
      } else {
        print('DEBUG: Excluded breeding events for calf female');
      }

      print('DEBUG: Final female events: ${femaleEvents.join(', ')}');
      return femaleEvents;
    } else if (genderLower == 'male') {
      return [
        ...baseTypes,
        'Treated',
        'Weighed',
        'Vaccinated',
        'Deworming',
        'Hoof Trimming',
        'Castrated',
        'Weaned',
        'Other'
      ];
    } else {
      return [
        ...baseTypes,
        'Treated',
        'Weighed',
        'Vaccinated',
        'Deworming',
        'Hoof Trimming',
        'Other'
      ];
    }
  }

  static IconData getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'breeding':
        return FontAwesomeIcons.heart;
      case 'treated':
        return FontAwesomeIcons.userDoctor;
      case 'vaccinated':
        return FontAwesomeIcons.syringe;
      case 'weighed':
        return FontAwesomeIcons.weightScale;
      case 'gives birth':
        return FontAwesomeIcons.baby;
      case 'pregnant':
        return FontAwesomeIcons.personPregnant;
      case 'dry off':
        return FontAwesomeIcons.pause;
      case 'aborted pregnancy':
        return FontAwesomeIcons.heartCrack;
      case 'deworming':
        return FontAwesomeIcons.pills;
      case 'hoof trimming':
        return FontAwesomeIcons.scissors;
      case 'castrated':
        return FontAwesomeIcons.mars;
      case 'weaned':
        return FontAwesomeIcons.bottleWater;
      case 'other':
        return FontAwesomeIcons.ellipsis;
      case 'loading cattle information...':
        return FontAwesomeIcons.spinner;
      default:
        return FontAwesomeIcons.fileLines;
    }
  }

  static Color getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'breeding': return Colors.pink.shade400;
      case 'weighed': return Colors.orange.shade500;
      case 'gives birth': return Colors.blue.shade400;
      case 'vaccinated': return Colors.green.shade500;
      case 'pregnant': return Colors.purple.shade400;
      case 'treated': return Colors.red.shade400;
      case 'dry off': return Colors.grey.shade500;
      case 'deworming': return Colors.yellow.shade600;
      case 'hoof trimming': return Colors.brown.shade400;
      case 'castrated': return Colors.indigo.shade400;
      case 'weaned': return Colors.teal.shade400;
      case 'aborted pregnancy': return Colors.red.shade600;
      case 'other': return Colors.blueGrey.shade400;
      case 'loading cattle information...': return Colors.grey.shade400;
      default: return AppColors.lightGreen;
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}