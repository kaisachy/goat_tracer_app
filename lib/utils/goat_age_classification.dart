import 'package:goat_tracer_app/models/goat.dart';
import 'package:flutter/foundation.dart';

class GoatAgeClassification {
  // Day-based age boundaries — aligned with backend (GoatClassificationService, VaccinationDashboardService)
  // Kid: 0–91d, Weanling: 92–152d, Grower: 153–243d, Doeling/Buckling: 244–365d, Doe/Buck: 366+
  // (≈ 30.44 days/month: 3mo=91, 5mo=152, 8mo=243, 12mo=365)
  static const int kidMaxDays = 91;           // From birth to 3 months
  static const int weanlingMinDays = 92;
  static const int weanlingMaxDays = 152;
  static const int growerMinDays = 153;
  static const int growerMaxDays = 243;
  static const int doelingBucklingMinDays = 244;
  static const int doelingBucklingMaxDays = 365;
  static const int doeBuckMinDays = 366;

  /// Get the expected classification from age in days (day-based; e.g. 3 months 1 day = Weanling).
  static String getExpectedClassificationFromAgeInDays(int ageInDays, String sex) {
    if (ageInDays <= kidMaxDays) {
      return 'Kid';
    }
    if (ageInDays >= weanlingMinDays && ageInDays <= weanlingMaxDays) {
      return 'Weanling';
    }
    if (ageInDays >= growerMinDays && ageInDays <= growerMaxDays) {
      return 'Growers';
    }
    if (ageInDays >= doelingBucklingMinDays && ageInDays <= doelingBucklingMaxDays) {
      if (sex == 'Female') return 'Doeling';
      if (sex == 'Male') return 'Buckling';
      return 'Doeling';
    }
    if (ageInDays >= doeBuckMinDays) {
      if (sex == 'Female') return 'Doe';
      if (sex == 'Male') return 'Buck';
      return 'Doe';
    }
    return 'Unknown';
  }

  /// Get the expected classification based on age in months (uses day-equivalent for boundaries).
  static String getExpectedClassification(int ageInMonths, String sex) {
    // Convert months to approximate days (30.44 days/month) so boundaries match day-based logic
    final ageInDays = (ageInMonths * 30.44).round();
    return getExpectedClassificationFromAgeInDays(ageInDays, sex);
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

  /// Auto-update Goat classification if it doesn't match the age (day-based when DOB is available).
  /// Returns the Goat with updated classification, or null if no update needed
  static Goat? autoUpdateClassificationIfNeeded(Goat goat) {
    try {
      int? ageInDays;
      if (goat.dateOfBirth != null && goat.dateOfBirth!.isNotEmpty) {
        final birthDate = DateTime.tryParse(goat.dateOfBirth!);
        if (birthDate != null) {
          ageInDays = DateTime.now().difference(birthDate).inDays;
          if (ageInDays < 0) ageInDays = 0;
        }
      }
      if (ageInDays == null) {
        final displayAge = goat.displayAge;
        if (displayAge == null || displayAge.isEmpty) return null;
        final ageInMonths = _parseAgeToMonths(displayAge);
        if (ageInMonths == null) return null;
        ageInDays = (ageInMonths * 30.44).round();
      }

      final expectedClassification = getExpectedClassificationFromAgeInDays(ageInDays, goat.sex);

      if (goat.classification == expectedClassification) {
        return null;
      }

      debugPrint('🔄 Auto-updating Goat ${goat.tagNo} classification: "${goat.classification}" -> "$expectedClassification" (Age: $ageInDays days)');
      return goat.copyWith(classification: expectedClassification);
    } catch (e) {
      debugPrint('Error in autoUpdateClassificationIfNeeded: $e');
      return null;
    }
  }

  /// Expected classification from date of birth (day-based). Use in forms for validation/suggestions.
  static String? getExpectedClassificationFromDateOfBirth(String? dateOfBirth, String? sex) {
    if (dateOfBirth == null || dateOfBirth.isEmpty || sex == null || sex.isEmpty) return null;
    final birthDate = DateTime.tryParse(dateOfBirth);
    if (birthDate == null) return null;
    int ageInDays = DateTime.now().difference(birthDate).inDays;
    if (ageInDays < 0) ageInDays = 0;
    return getExpectedClassificationFromAgeInDays(ageInDays, sex);
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
