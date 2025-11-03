// lib/screens/nav/cattle/utils/history_type_utils.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';

class HistoryTypeUtils {
  static List<String> getHistoryTypesForSex(String? sex, {String? classification}) {
    final baseTypes = ['Select type of history record'];

    if (classification == null) {
      return [...baseTypes, 'Loading cattle information...'];
    }

    final classificationLower = classification.toLowerCase().trim();

    // Debug logging
    print('DEBUG: Classification: $classification');
    print('DEBUG: Classification lower: $classificationLower');

    // Determine history types based on classification only (matching PHP web logic)
    List<String> historyTypes = [];

    switch (classificationLower) {
      case 'calf':
      case 'calves':
        historyTypes = [
          'Sick',
          'Treated',
          'Weighed',
          'Vaccinated',
          'Deworming',
          'Hoof Trimming',
          'Castrated',
          'Weaned',
          'Mortality',
          'Lost',
          'Other',
        ];
        print('DEBUG: Using Calf history types');
        break;
      case 'heifer':
      case 'heifers':
        historyTypes = [
          'Vaccinated',
          'Sick',
          'Treated',
          'Breeding',
          'Pregnant',
          'Gives Birth',
          'Aborted Pregnancy',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        print('DEBUG: Using Heifer history types');
        break;
      case 'cow':
      case 'cows':
        historyTypes = [
          'Vaccinated',
          'Sick',
          'Treated',
          'Breeding',
          'Pregnant',
          'Gives Birth',
          'Aborted Pregnancy',
          'Dry off',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        print('DEBUG: Using Cow history types');
        break;
      case 'bull':
      case 'bulls':
        historyTypes = [
          'Vaccinated',
          'Sick',
          'Treated',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        print('DEBUG: Using Bull history types');
        break;
      case 'steer':
      case 'steers':
        historyTypes = [
          'Vaccinated',
          'Sick',
          'Treated',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        print('DEBUG: Using Steer history types');
        break;
      case 'growers':
      case 'grower':
        historyTypes = [
          'Vaccinated',
          'Sick',
          'Treated',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        print('DEBUG: Using Growers history types');
        break;
      default:
        historyTypes = [
          'Vaccinated',
          'Treated',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Mortality',
          'Lost',
          'Other',
        ];
        print('DEBUG: Using default history types for classification: $classificationLower');
        break;
    }

    print('DEBUG: Final history types: ${historyTypes.join(', ')}');
    return [...baseTypes, ...historyTypes];
  }

  static IconData getHistoryIcon(String historyType) {
    switch (historyType.toLowerCase()) {
      case 'sick':
        return FontAwesomeIcons.virus;
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
      case 'mortality':
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

  static Color getHistoryColor(String historyType) {
    switch (historyType.toLowerCase()) {
      case 'sick': return Colors.red.shade600;
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
      case 'mortality': return Colors.grey.shade700;
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