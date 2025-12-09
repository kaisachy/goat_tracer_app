import 'package:goat_tracer_app/models/goat.dart';
import 'package:flutter/foundation.dart';

class GoatAgeClassification {
  // Age ranges in months
  static const int kidMaxAge = 2;
  static const int weanlingMinAge = 3;
  static const int weanlingMaxAge = 5;
  static const int growerMinAge = 5;
  static const int growerMaxAge = 18;
  static const int doelingBucklingMinAge = 19;
  static const int doelingBucklingMaxAge = 24; // Upper bound is exclusive in logic below
  static const int doeBuckMinAge = 24; // Inclusive: >= 24 months is Doe/Buck

  /// Get the expected classification based on age and sex
  static String getExpectedClassification(int ageInMonths, String sex) {
    if (ageInMonths <= kidMaxAge) {
      return 'Kid';
    } else if (ageInMonths >= weanlingMinAge && ageInMonths <= weanlingMaxAge) {
      return 'Weanling';
    } else if (ageInMonths >= growerMinAge && ageInMonths <= growerMaxAge) {
      return 'Growers';
    } else if (ageInMonths >= doelingBucklingMinAge && ageInMonths < doelingBucklingMaxAge) {
      if (sex == 'Female') {
        return 'Doeling';
      } else if (sex == 'Male') {
        return 'Buckling';
      }
      return 'Doeling'; // Default fallback
    } else if (ageInMonths >= doeBuckMinAge) {
      if (sex == 'Female') {
        return 'Doe';
      } else if (sex == 'Male') {
        return 'Buck';
      }
      return 'Doe'; // Default fallback
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

  /// Auto-update Goat classification if it doesn't match the age
  /// Returns the Goat with updated classification, or null if no update needed
  static Goat? autoUpdateClassificationIfNeeded(Goat goat) {
    final displayAge = goat.displayAge;
    if (displayAge == null || displayAge.isEmpty) {
      return null; // Can't auto-update without age information
    }

    try {
      final ageInMonths = _parseAgeToMonths(displayAge);
      if (ageInMonths == null) {
        return null; // Can't parse age
      }

      final expectedClassification = getExpectedClassification(ageInMonths, goat.sex);

      // Check if current classification is accurate
      if (goat.classification == expectedClassification) {
        return null; // No update needed
      }

      // Classification needs to be updated
      debugPrint('🔄 Auto-updating Goat ${goat.tagNo} classification: "${goat.classification}" -> "$expectedClassification" (Age: $ageInMonths months)');
      
      return goat.copyWith(classification: expectedClassification);
    } catch (e) {
      debugPrint('Error in autoUpdateClassificationIfNeeded: $e');
      return null;
    }
  }

  /// Get all Goat with auto-updated classifications
  /// Returns a map of Goat that need updates: {GoatId: updatedGoat}
  static Map<int, Goat> autoUpdateClassificationsForList(List<Goat> goatList) {
    final Map<int, Goat> updatedGoat = {};
    
    for (var goat in goatList) {
      final updated = autoUpdateClassificationIfNeeded(goat);
      if (updated != null) {
        updatedGoat[goat.id] = updated;
      }
    }
    
    return updatedGoat;
  }

}
