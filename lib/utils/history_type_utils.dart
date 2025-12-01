// lib/screens/nav/goat/utils/history_type_utils.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';

class HistoryTypeUtils {
  static List<String> getHistoryTypesForSex(String? sex, {String? classification}) {
    final baseTypes = ['Select type of history record'];

    if (classification == null) {
      return [...baseTypes, 'Loading goat information...'];
    }

    final classificationLower = classification.toLowerCase().trim();

    // Debug logging
    debugPrint('DEBUG: Classification: $classification');
    debugPrint('DEBUG: Classification lower: $classificationLower');

    // Determine history types based on classification only (matching PHP web logic)
    List<String> historyTypes = [];

    switch (classificationLower) {
      case 'kid':
      case 'kids':
        historyTypes = [
          'Sick',
          'Treated',
          'Weighed',
          'Vaccinated',
          'Deworming',
          'Hoof Trimming',
          'Castrated',
          'Weaned',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        debugPrint('DEBUG: Using Kid history types');
        break;
      case 'doeling':
      case 'doelings':
        historyTypes = [
          'Vaccinated',
          'Sick',
          'Treated',
          'Breeding',
          'Pregnant',
          'Kidding',
          'Aborted',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        debugPrint('DEBUG: Using Doeling history types');
        break;
      case 'doe':
      case 'does':
        historyTypes = [
          'Vaccinated',
          'Sick',
          'Treated',
          'Breeding',
          'Pregnant',
          'Kidding',
          'Aborted',
          'Dry off',
          'Weighed',
          'Deworming',
          'Hoof Trimming',
          'Sold',
          'Mortality',
          'Lost',
          'Other',
        ];
        debugPrint('DEBUG: Using Doe history types');
        break;
      case 'buck':
      case 'bucks':
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
        debugPrint('DEBUG: Using Buck history types');
        break;
      case 'buckling':
      case 'bucklings':
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
        debugPrint('DEBUG: Using Buckling history types');
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
        debugPrint('DEBUG: Using Growers history types');
        break;
      default:
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
        debugPrint('DEBUG: Using default history types for classification: $classificationLower');
        break;
    }

    debugPrint('DEBUG: Final history types: ${historyTypes.join(', ')}');
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
      case 'kidding':
        return FontAwesomeIcons.baby;
      case 'pregnant':
        return FontAwesomeIcons.personPregnant;
      case 'dry off':
        return FontAwesomeIcons.pause;
      case 'aborted':
        return FontAwesomeIcons.heartCrack;
      case 'deworming':
        return FontAwesomeIcons.pills;
      case 'hoof trimming':
        return FontAwesomeIcons.scissors;
      case 'castrated':
        return FontAwesomeIcons.scissors;
      case 'weaned':
        return FontAwesomeIcons.bottleWater;
      case 'mortality':
        return FontAwesomeIcons.skull;
      case 'lost':
        return FontAwesomeIcons.magnifyingGlass;
      case 'sold':
        return FontAwesomeIcons.coins;
      case 'other':
        return FontAwesomeIcons.ellipsis;
      case 'loading goat information...':
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
      case 'kidding': return Colors.blue.shade400;
      case 'vaccinated': return Colors.green.shade500;
      case 'pregnant': return Colors.purple.shade400;
      case 'treated': return Colors.red.shade400;
      case 'dry off': return Colors.grey.shade500;
      case 'deworming': return Colors.yellow.shade600;
      case 'hoof trimming': return Colors.brown.shade400;
      case 'castrated': return Colors.indigo.shade400;
      case 'weaned': return Colors.teal.shade400;
      case 'aborted': return Colors.red.shade600;
      case 'mortality': return Colors.grey.shade700;
      case 'lost': return Colors.amber.shade600;
      case 'sold': return Colors.green.shade600;
      case 'other': return Colors.blueGrey.shade400;
      case 'loading goat information...': return Colors.grey.shade400;
      default: return AppColors.lightGreen;
    }
  }

  /// Returns the image asset path for history types that use custom images
  /// Returns null if the history type should use an icon instead
  static String? getHistoryImagePath(String historyType) {
    // Normalize the history type: trim whitespace, normalize multiple spaces, and convert to lowercase
    final normalized = historyType.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    
    // Handle "pregnant" history type
    if (normalized == 'pregnant') {
      return 'assets/images/goat-icons/pregnant_doe.png';
    }
    
    // Handle "kidding" with various spacing/casing
    // Check for exact match first, then handle variations
    if (normalized == 'kidding') {
      return 'assets/images/goat-icons/lactating.png';
    }
    
    // Handle case where there's no space (e.g., "Kidding" from database)
    final noSpace = normalized.replaceAll(' ', '');
    if (noSpace == 'kidding') {
      return 'assets/images/goat-icons/lactating.png';
    }

    // Use kid.png for weaned events
    if (normalized == 'weaned') {
      return 'assets/images/goat-icons/kid.png';
    }
    
    return null;
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