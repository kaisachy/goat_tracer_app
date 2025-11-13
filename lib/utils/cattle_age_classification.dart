import 'package:flutter/foundation.dart';
import 'package:cattle_tracer_app/models/cattle.dart';

class CattleAgeClassification {
  // Age ranges in months
  static const int calfMaxAge = 8;
  static const int growerMinAge = 8;
  static const int growerMaxAge = 18;
  static const int heiferSteerMinAge = 18;
  static const int heiferSteerMaxAge = 24; // Upper bound is exclusive in logic below
  static const int cowBullMinAge = 24; // Inclusive: >= 24 months is Cow/Bull

  /// Get the expected classification based on age and sex
  static String getExpectedClassification(int ageInMonths, String sex) {
    if (ageInMonths <= calfMaxAge) {
      return 'Calf';
    } else if (ageInMonths > growerMinAge && ageInMonths <= growerMaxAge) {
      return 'Growers';
    } else if (ageInMonths > heiferSteerMinAge && ageInMonths < heiferSteerMaxAge) {
      if (sex == 'Female') {
        return 'Heifer';
      } else if (sex == 'Male') {
        return 'Steer';
      }
      return 'Heifer'; // Default fallback
    } else if (ageInMonths >= cowBullMinAge) {
      if (sex == 'Female') {
        return 'Cow';
      } else if (sex == 'Male') {
        return 'Bull';
      }
      return 'Cow'; // Default fallback
    }
    
    // Fallback for edge cases
    return 'Unknown';
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

  /// Auto-update cattle classification if it doesn't match the age
  /// Returns the cattle with updated classification, or null if no update needed
  static Cattle? autoUpdateClassificationIfNeeded(Cattle cattle) {
    final displayAge = cattle.displayAge;
    if (displayAge == null || displayAge.isEmpty) {
      return null; // Can't auto-update without age information
    }

    try {
      final ageInMonths = _parseAgeToMonths(displayAge);
      if (ageInMonths == null) {
        return null; // Can't parse age
      }

      final expectedClassification = getExpectedClassification(ageInMonths, cattle.sex);

      // Check if current classification is accurate
      if (cattle.classification == expectedClassification) {
        return null; // No update needed
      }

      // Classification needs to be updated
      debugPrint('🔄 Auto-updating cattle ${cattle.tagNo} classification: "${cattle.classification}" -> "$expectedClassification" (Age: $ageInMonths months)');
      
      return cattle.copyWith(classification: expectedClassification);
    } catch (e) {
      debugPrint('Error in autoUpdateClassificationIfNeeded: $e');
      return null;
    }
  }

  /// Get all cattle with auto-updated classifications
  /// Returns a map of cattle that need updates: {cattleId: updatedCattle}
  static Map<int, Cattle> autoUpdateClassificationsForList(List<Cattle> cattleList) {
    final Map<int, Cattle> updatedCattle = {};
    
    for (var cattle in cattleList) {
      final updated = autoUpdateClassificationIfNeeded(cattle);
      if (updated != null) {
        updatedCattle[cattle.id] = updated;
      }
    }
    
    return updatedCattle;
  }

}

