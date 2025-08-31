import 'package:cattle_tracer_app/models/cattle.dart';

class CattleAgeClassification {
  // Age ranges in months
  static const int CALF_MAX_AGE = 8;
  static const int GROWER_MIN_AGE = 8;
  static const int GROWER_MAX_AGE = 18;
  static const int HEIFER_STEER_MIN_AGE = 18;
  static const int HEIFER_STEER_MAX_AGE = 24;
  static const int COW_BULL_MIN_AGE = 24;

  /// Get the expected classification based on age and gender
  static String getExpectedClassification(int ageInMonths, String gender) {
    if (ageInMonths <= CALF_MAX_AGE) {
      return 'Calf';
    } else if (ageInMonths > GROWER_MIN_AGE && ageInMonths <= GROWER_MAX_AGE) {
      return 'Growers';
    } else if (ageInMonths > HEIFER_STEER_MIN_AGE && ageInMonths <= HEIFER_STEER_MAX_AGE) {
      if (gender == 'Female') {
        return 'Heifer';
      } else if (gender == 'Male') {
        return 'Steer';
      }
      return 'Heifer'; // Default fallback
    } else if (ageInMonths > COW_BULL_MIN_AGE) {
      if (gender == 'Female') {
        return 'Cow';
      } else if (gender == 'Male') {
        return 'Bull';
      }
      return 'Cow'; // Default fallback
    }
    
    // Fallback for edge cases
    return 'Unknown';
  }

  /// Check if the current classification matches the expected classification based on age
  static bool isClassificationAccurate(Cattle cattle) {
    final displayAge = cattle.displayAge;
    if (displayAge == null || displayAge.isEmpty) {
      return true; // Can't validate without age
    }

    try {
      final ageInMonths = _parseAgeToMonths(displayAge);
      if (ageInMonths == null) {
        return true; // Can't parse age, assume accurate
      }
      
      final expectedClassification = getExpectedClassification(ageInMonths, cattle.gender);
      return cattle.classification == expectedClassification;
    } catch (e) {
      // If age parsing fails, assume it's accurate
      return true;
    }
  }

  /// Parse various age formats to months
  static int? _parseAgeToMonths(String ageString) {
    if (ageString.isEmpty) return null;
    
    try {
      // Handle "X months" format
      if (ageString.toLowerCase().contains('month')) {
        final monthMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(ageString);
        if (monthMatch != null) {
          final ageValue = double.parse(monthMatch.group(1)!);
          return ageValue.round();
        }
      }
      
      // Handle "X years" format
      if (ageString.toLowerCase().contains('year')) {
        final yearMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(ageString);
        if (yearMatch != null) {
          final ageValue = double.parse(yearMatch.group(1)!);
          return (ageValue * 12).round();
        }
      }
      
      // Handle plain number format (assume months)
      final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(ageString);
      if (numberMatch != null) {
        final ageValue = double.parse(numberMatch.group(1)!);
        return ageValue.round();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the validation message for inaccurate classification
  static String getValidationMessage(Cattle cattle) {
    final displayAge = cattle.displayAge;
    if (displayAge == null || displayAge.isEmpty) {
      return 'Age information not available for validation';
    }

    try {
      final ageInMonths = _parseAgeToMonths(displayAge);
      if (ageInMonths == null) {
        return 'Unable to parse age format: $displayAge';
      }
      
      final expectedClassification = getExpectedClassification(ageInMonths, cattle.gender);
      
      if (cattle.classification == expectedClassification) {
        return 'Classification is accurate for age';
      } else {
        return 'Age: ${ageInMonths} months suggests classification should be "$expectedClassification" instead of "${cattle.classification}"';
      }
    } catch (e) {
      return 'Unable to validate age classification';
    }
  }


}
