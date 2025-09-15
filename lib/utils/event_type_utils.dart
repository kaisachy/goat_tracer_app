// lib/screens/nav/cattle/utils/event_type_utils.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';

class EventTypeUtils {
  static List<String> getEventTypesForSex(String? sex, {String? classification}) {
    final baseTypes = ['Select type of event'];

    if (classification == null) {
      return [...baseTypes, 'Loading cattle information...'];
    }

    final classificationLower = classification.toLowerCase().trim();

    // Debug logging
    print('DEBUG: Classification: $classification');
    print('DEBUG: Classification lower: $classificationLower');

    // Determine event types based on classification only (matching PHP web logic)
    List<String> eventTypes = [];

    switch (classificationLower) {
      case 'calf':
      case 'calves':
        eventTypes = ['Treated', 'Weighed', 'Vaccinated', 'Deworming', 'Hoof Trimming', 'Castrated', 'Weaned', 'Lost', 'Deceased', 'Other'];
        print('DEBUG: Using Calf event types');
        break;
        
      case 'heifer':
      case 'heifers':
        eventTypes = ['Treated', 'Weighed', 'Vaccinated', 'Breeding', 'Pregnant', 'Gives Birth', 'Aborted Pregnancy', 'Deworming', 'Hoof Trimming', 'Sold', 'Lost', 'Deceased', 'Other'];
        print('DEBUG: Using Heifer event types');
        break;
        
      case 'cow':
      case 'cows':
        eventTypes = ['Dry off', 'Treated', 'Breeding', 'Weighed', 'Gives Birth', 'Vaccinated', 'Pregnant', 'Aborted Pregnancy', 'Deworming', 'Hoof Trimming', 'Sold', 'Lost', 'Deceased', 'Other'];
        print('DEBUG: Using Cow event types');
        break;
        
      case 'bull':
      case 'bulls':
        eventTypes = ['Treated', 'Weighed', 'Breeding', 'Vaccinated', 'Deworming', 'Hoof Trimming', 'Sold', 'Lost', 'Deceased', 'Other'];
        print('DEBUG: Using Bull event types');
        break;
        
      case 'steer':
      case 'steers':
        eventTypes = ['Treated', 'Weighed', 'Vaccinated', 'Deworming', 'Hoof Trimming', 'Sold', 'Lost', 'Deceased', 'Other'];
        print('DEBUG: Using Steer event types');
        break;
        
      case 'growers':
      case 'grower':
        eventTypes = ['Treated', 'Weighed', 'Vaccinated', 'Deworming', 'Hoof Trimming', 'Sold', 'Lost', 'Deceased', 'Other'];
        print('DEBUG: Using Growers event types');
        break;
        
      default:
        eventTypes = ['Treated', 'Weighed', 'Vaccinated', 'Deworming', 'Hoof Trimming', 'Lost', 'Deceased', 'Other'];
        print('DEBUG: Using default event types for classification: $classificationLower');
        break;
    }

    print('DEBUG: Final event types: ${eventTypes.join(', ')}');
    return [...baseTypes, ...eventTypes];
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
      case 'deceased':
        return FontAwesomeIcons.skull;
      case 'lost':
        return FontAwesomeIcons.magnifyingGlass;
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
      case 'deceased': return Colors.grey.shade700;
      case 'lost': return Colors.amber.shade600;
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