import 'package:cattle_tracer_app/models/cattle.dart';

class CattleAgeClassification {
  // Age ranges in months
  static const int CALF_MAX_AGE = 8;
  static const int GROWER_MIN_AGE = 8;
  static const int GROWER_MAX_AGE = 18;
  static const int HEIFER_STEER_MIN_AGE = 18;
  static const int HEIFER_STEER_MAX_AGE = 24; // Upper bound is exclusive in logic below
  static const int COW_BULL_MIN_AGE = 24; // Inclusive: >= 24 months is Cow/Bull

  /// Get the expected classification based on age and gender
  static String getExpectedClassification(int ageInMonths, String gender) {
    if (ageInMonths <= CALF_MAX_AGE) {
      return 'Calf';
    } else if (ageInMonths > GROWER_MIN_AGE && ageInMonths <= GROWER_MAX_AGE) {
      return 'Growers';
    } else if (ageInMonths > HEIFER_STEER_MIN_AGE && ageInMonths < HEIFER_STEER_MAX_AGE) {
      if (gender == 'Female') {
        return 'Heifer';
      } else if (gender == 'Male') {
        return 'Steer';
      }
      return 'Heifer'; // Default fallback
    } else if (ageInMonths >= COW_BULL_MIN_AGE) {
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
      final normalized = ageString.trim().toLowerCase();

      // Handle years: e.g., "2y", "2 yr", "2yrs", "2 year(s)", "2yo"
      final yearsRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(y|yr|yrs|year|years|yo)\b');
      final yearsMatch = yearsRegex.firstMatch(normalized);
      if (yearsMatch != null) {
        final value = double.parse(yearsMatch.group(1)!);
        return (value * 12).round();
      }

      // Handle months: e.g., "24m", "24 mo", "24mos", "24 month(s)"
      final monthsRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(m|mo|mos|month|months)\b');
      final monthsMatch = monthsRegex.firstMatch(normalized);
      if (monthsMatch != null) {
        final value = double.parse(monthsMatch.group(1)!);
        return value.round();
      }

      // Handle explicit words without abbreviations (fallbacks)
      if (normalized.contains('year')) {
        final yearNumberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
        if (yearNumberMatch != null) {
          final value = double.parse(yearNumberMatch.group(1)!);
          return (value * 12).round();
        }
      }
      if (normalized.contains('month')) {
        final monthNumberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
        if (monthNumberMatch != null) {
          final value = double.parse(monthNumberMatch.group(1)!);
          return value.round();
        }
      }

      // Handle plain number format (assume months)
      final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
      if (numberMatch != null) {
        final value = double.parse(numberMatch.group(1)!);
        return value.round();
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
