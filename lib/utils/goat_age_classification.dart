import 'package:goat_tracer_app/models/goat.dart';

class GoatAgeClassification {
  // Age ranges in months
  static const int Kid_MAX_AGE = 8;
  static const int GROWER_MIN_AGE = 8;
  static const int GROWER_MAX_AGE = 18;
  static const int Doeling_Buckling_MIN_AGE = 18;
  static const int Doeling_Buckling_MAX_AGE = 24; // Upper bound is exclusive in logic below
  static const int Doe_Buck_MIN_AGE = 24; // Inclusive: >= 24 months is Doe/Buck

  /// Get the expected classification based on age and sex
  static String getExpectedClassification(int ageInMonths, String sex) {
    if (ageInMonths <= Kid_MAX_AGE) {
      return 'Kid';
    } else if (ageInMonths > GROWER_MIN_AGE && ageInMonths <= GROWER_MAX_AGE) {
      return 'Growers';
    } else if (ageInMonths > Doeling_Buckling_MIN_AGE && ageInMonths < Doeling_Buckling_MAX_AGE) {
      if (sex == 'Female') {
        return 'Doeling';
      } else if (sex == 'Male') {
        return 'Buckling';
      }
      return 'Doeling'; // Default fallback
    } else if (ageInMonths >= Doe_Buck_MIN_AGE) {
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
  static Goat? autoUpdateClassificationIfNeeded(Goat Goat) {
    final displayAge = Goat.displayAge;
    if (displayAge == null || displayAge.isEmpty) {
      return null; // Can't auto-update without age information
    }

    try {
      final ageInMonths = _parseAgeToMonths(displayAge);
      if (ageInMonths == null) {
        return null; // Can't parse age
      }

      final expectedClassification = getExpectedClassification(ageInMonths, Goat.sex);

      // Check if current classification is accurate
      if (Goat.classification == expectedClassification) {
        return null; // No update needed
      }

      // Classification needs to be updated
      print('🔄 Auto-updating Goat ${Goat.tagNo} classification: "${Goat.classification}" -> "$expectedClassification" (Age: ${ageInMonths} months)');
      
      return Goat.copyWith(classification: expectedClassification);
    } catch (e) {
      print('Error in autoUpdateClassificationIfNeeded: $e');
      return null;
    }
  }

  /// Get all Goat with auto-updated classifications
  /// Returns a map of Goat that need updates: {GoatId: updatedGoat}
  static Map<int, Goat> autoUpdateClassificationsForList(List<Goat> GoatList) {
    final Map<int, Goat> updatedGoat = {};
    
    for (var Goat in GoatList) {
      final updated = autoUpdateClassificationIfNeeded(Goat);
      if (updated != null) {
        updatedGoat[Goat.id] = updated;
      }
    }
    
    return updatedGoat;
  }

}
