import 'dart:developer';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/models/vaccination_schedule.dart';

class VaccinationService {
  static final VaccinationService _instance = VaccinationService._internal();
  factory VaccinationService() => _instance;
  VaccinationService._internal();

  /// Generate vaccination schedules for all goat based on their age and stage
  Future<List<VaccinationSchedule>> generateVaccinationSchedules({
    required List<Goat> allGoats,
    required List<Map<String, dynamic>> allEvents,
  }) async {
    log('🚀 VACCINATION SERVICE: Generating schedules for ${allGoats.length} goat');
    
    final List<VaccinationSchedule> schedules = [];
    
    for (final goat in allGoats) {
      final ageInMonths = _getAccurateAgeInMonths(goat);
      final isDairy = _isDairyGoat(goat);
      final pregnancyInfo = _getPregnancyInfo(goat.tagNo, allEvents);
      final classification = _normalizeClassification(goat.classification);
      
      log('🐄 Processing ${goat.tagNo}: Age=$ageInMonths months, Classification=$classification, Dairy=$isDairy, Pregnant=${pregnancyInfo != null}');
      
      final goatSchedules = await _generateGoatVaccinationSchedules(
        goat: goat,
        allEvents: allEvents,
        ageInMonths: ageInMonths,
        isDairy: isDairy,
        pregnancyInfo: pregnancyInfo,
        classification: classification,
      );
      
      schedules.addAll(goatSchedules);
    }
    
    log('✅ Generated ${schedules.length} vaccination schedules');
    return schedules;
  }

  /// Get accurate age in months for goat
  int _getAccurateAgeInMonths(Goat goat) {
    // First try to use the backend-provided age
    if (goat.age != null && goat.age!.isNotEmpty) {
      try {
        final ageValue = int.tryParse(goat.age!);
        if (ageValue != null && ageValue >= 0) {
          return ageValue;
        }
      } catch (e) {
        log('⚠️ Error parsing backend age for ${goat.tagNo}: $e');
      }
    }
    
    // Fall back to computed age from date of birth
    if (goat.dateOfBirth != null && goat.dateOfBirth!.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(goat.dateOfBirth!);
        final now = DateTime.now();
        final difference = now.difference(birthDate);
        final ageInMonths = (difference.inDays / 30.44).round();
        return ageInMonths > 0 ? ageInMonths : 0;
      } catch (e) {
        log('⚠️ Error parsing date of birth for ${goat.tagNo}: $e');
      }
    }
    
    // Default age based on classification if no date available
    return _getDefaultAgeByClassification(goat.classification);
  }

  /// Compute accurate age in days (for newborn logic)
  int _getAccurateAgeInDays(Goat goat) {
    // Prefer DOB when available
    if (goat.dateOfBirth != null && goat.dateOfBirth!.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(goat.dateOfBirth!);
        final now = DateTime.now();
        final days = now.difference(birthDate).inDays;
        return days >= 0 ? days : 0;
      } catch (_) {}
    }

    // Fallback: derive from age in months if provided
    if (goat.age != null && goat.age!.isNotEmpty) {
      final months = int.tryParse(goat.age!);
      if (months != null) {
        // Approximate days from months
        return (months * 30.44).round();
      }
    }

    // Last resort: classification defaults
    switch (goat.classification.toLowerCase()) {
      case 'Kid':
      case 'calves':
        return 30; // assume ~1 month if unknown
      case 'grower':
      case 'growers':
        return 240; // ~8 months
      case 'Doeling':
      case 'Doelings':
        return 450; // ~15 months
      case 'Doe':
      case 'Does':
      case 'Buck':
      case 'Bucks':
        return 1095; // ~3 years
      default:
        return 365; // default 1 year
    }
  }

  /// Get default age based on classification when no date is available
  int _getDefaultAgeByClassification(String classification) {
    switch (classification.toLowerCase()) {
      case 'Kid':
        return 3; // Assume 3 months for calves
      case 'grower':
      case 'growers':
        return 8; // Assume 8 months for growers
      case 'Doeling':
      case 'Doelings':
        return 15; // Assume 15 months for Doelings
      case 'Doe':
      case 'Does':
        return 36; // Assume 3 years for Does
      case 'Buck':
      case 'Bucks':
        return 36; // Assume 3 years for Bucks
      default:
        return 12; // Default to 1 year
    }
  }

  /// Normalize classification to ensure consistency
  String _normalizeClassification(String classification) {
    final normalized = classification.trim().toLowerCase();
    
    switch (normalized) {
      case 'Kid':
      case 'calves':
        return 'Kid';
      case 'grower':
      case 'growers':
        return 'Growers';
      case 'Buckling':
      case 'Bucklings':
        return 'Buckling';
      case 'Doeling':
      case 'Doelings':
        return 'Doeling';
      case 'Doe':
      case 'Does':
        return 'Doe';
      case 'Buck':
      case 'Bucks':
        return 'Buck';
      default:
        return classification; // Keep original if unknown
    }
  }

  /// Detect if the goat has a Weaned event
  bool _hasWeanedEvent(String goatTag, List<Map<String, dynamic>> allEvents) {
    return allEvents.any((event) =>
        event['goat_tag'] == goatTag &&
        (event['history_type']?.toString().toLowerCase() ?? '') == 'weaned');
  }

  /// Generate vaccination schedules for a specific goat
  Future<List<VaccinationSchedule>> _generateGoatVaccinationSchedules({
    required Goat goat,
    required List<Map<String, dynamic>> allEvents,
    required int ageInMonths,
    required bool isDairy,
    required Map<String, dynamic>? pregnancyInfo,
    required String classification,
  }) async {
    final List<VaccinationSchedule> schedules = [];
    
    // If a Kid has a Weaned event, treat as Growers for vaccination purposes
    final bool hasWeanedEvent = _hasWeanedEvent(goat.tagNo, allEvents);
    final String effectiveClassification =
        (classification == 'Kid' && hasWeanedEvent) ? 'Growers' : classification;
    
    // Get applicable vaccines for this goat
    final applicableVaccines = VaccinationProtocol.getApplicableVaccines(
      ageInMonths: ageInMonths,
      ageInDays: _getAccurateAgeInDays(goat),
      classification: effectiveClassification,
      sex: goat.sex,
      isDairy: isDairy,
      status: goat.status,
      isPregnant: pregnancyInfo != null,
    );
    
    log('  📋 Applicable vaccines for ${goat.tagNo}: ${applicableVaccines.map((v) => v.name).join(', ')}');
    
    // Get vaccination history for this goat
    final vaccinationHistory = _getVaccinationHistory(goat.tagNo, allEvents);
    
    for (final vaccine in applicableVaccines) {
      final schedule = await _createVaccinationSchedule(
        goat: goat,
        vaccine: vaccine,
        vaccinationHistory: vaccinationHistory,
        ageInMonths: ageInMonths,
        pregnancyInfo: pregnancyInfo,
        classification: effectiveClassification,
      );
      
      if (schedule != null) {
        schedules.add(schedule);
        log('  ✅ Created schedule: ${vaccine.name} - ${schedule.recommendedDate}');
      }
    }
    
    return schedules;
  }

  /// Create a vaccination schedule for a specific vaccine
  Future<VaccinationSchedule?> _createVaccinationSchedule({
    required Goat goat,
    required VaccineType vaccine,
    required List<Map<String, dynamic>> vaccinationHistory,
    required int ageInMonths,
    required Map<String, dynamic>? pregnancyInfo,
    required String classification,
  }) async {
    // For pre-calving vaccines, check if already vaccinated during current pregnancy
    if (_isPreCalvingVaccine(vaccine) && pregnancyInfo != null) {
      if (_isAlreadyVaccinatedForCurrentPregnancy(goat.tagNo, vaccine.name, vaccinationHistory, pregnancyInfo)) {
        log('  ⏭️ Skipping ${vaccine.name} - already vaccinated for current pregnancy');
        return null; // Already vaccinated for this pregnancy
      }
    }
    
    // Check if this vaccine was already given recently
    final lastVaccination = _getLastVaccination(goat.tagNo, vaccine.name, vaccinationHistory);
    
    if (lastVaccination != null) {
      // Check if booster is needed
      if (vaccine.requiresBooster && vaccine.boosterIntervalWeeks != null) {
        final nextDate = VaccinationProtocol.getNextVaccinationDate(
          lastVaccinationDate: DateTime.parse(lastVaccination['history_date']),
          vaccine: vaccine,
          ageInMonths: ageInMonths,
        );
        
        // Only create schedule if booster is due
        if (nextDate.isAfter(DateTime.now())) {
          log('  ⏭️ Skipping ${vaccine.name} - booster not due yet');
          return null;
        }
        
        return VaccinationSchedule(
          goatTag: goat.tagNo,
          vaccineType: vaccine.name,
          goatStage: _getGoatStage(goat, classification),
          recommendedDate: nextDate,
          status: _calculateStatus(nextDate),
          notes: 'Booster shot for ${vaccine.name}',
        );
      }
      
      // For non-booster vaccines, check if annual vaccination is needed
      if (vaccine.name.toLowerCase().contains('annual')) {
        final nextDate = VaccinationProtocol.getNextVaccinationDate(
          lastVaccinationDate: DateTime.parse(lastVaccination['history_date']),
          vaccine: vaccine,
          ageInMonths: ageInMonths,
        );
        
        if (nextDate.isAfter(DateTime.now())) {
          log('  ⏭️ Skipping ${vaccine.name} - annual vaccination not due yet');
          return null;
        }
        
        return VaccinationSchedule(
          goatTag: goat.tagNo,
          vaccineType: vaccine.name,
          goatStage: _getGoatStage(goat, classification),
          recommendedDate: nextDate,
          status: _calculateStatus(nextDate),
          notes: 'Annual vaccination for ${vaccine.name}',
        );
      }
      
      // Vaccine already given and no repeat needed
      log('  ⏭️ Skipping ${vaccine.name} - already vaccinated and no repeat needed');
      return null;
    }
    
    // First time vaccination - calculate recommended date based on age and pregnancy
    final recommendedDate = _calculateFirstVaccinationDate(
      vaccine, 
      ageInMonths, 
      pregnancyInfo: pregnancyInfo,
    );
    
    // Skip pre-calving vaccines if not pregnant
    if (_isPreCalvingVaccine(vaccine) && pregnancyInfo == null) {
      log('  ⏭️ Skipping ${vaccine.name} - not pregnant');
      return null;
    }
    
    return VaccinationSchedule(
      goatTag: goat.tagNo,
      vaccineType: vaccine.name,
      goatStage: _getGoatStage(goat, classification),
      recommendedDate: recommendedDate,
      status: _calculateStatus(recommendedDate),
      notes: _getVaccinationNotes(vaccine, pregnancyInfo),
    );
  }

  /// Calculate the first vaccination date for a vaccine based on goat age and pregnancy
  DateTime _calculateFirstVaccinationDate(
    VaccineType vaccine, 
    int ageInMonths, {
    Map<String, dynamic>? pregnancyInfo,
  }) {
    final now = DateTime.now();
    
    // Handle pre-calving vaccines
    if (_isPreCalvingVaccine(vaccine) && pregnancyInfo != null) {
      return _calculatePreCalvingVaccinationDate(vaccine, pregnancyInfo);
    }
    
    // For newborn vaccines, recommend immediately
    if (vaccine.ageInMonths == 0) {
      return now;
    }
    
    // For vaccines that should have been given earlier, recommend immediately
    if (ageInMonths >= vaccine.ageInMonths) {
      return now;
    }
    
    // For vaccines that should be given in the future, calculate the date
    final monthsUntilDue = vaccine.ageInMonths - ageInMonths;
    return now.add(Duration(days: monthsUntilDue * 30));
  }

  /// Calculate status based on recommended date
  String _calculateStatus(DateTime recommendedDate) {
    final now = DateTime.now();
    final daysUntilDue = recommendedDate.difference(now).inDays;
    
    if (daysUntilDue < 0) {
      return 'Overdue';
    } else if (daysUntilDue <= 30) {
      return 'Pending';
    } else {
      return 'Pending';
    }
  }

  /// Get vaccination history for a specific goat
  List<Map<String, dynamic>> _getVaccinationHistory(
    String goatTag,
    List<Map<String, dynamic>> allEvents,
  ) {
    return allEvents
        .where((event) =>
            event['goat_tag'] == goatTag &&
            event['history_type']?.toString().toLowerCase() == 'vaccinated')
        .toList();
  }

  /// Get the last vaccination for a specific vaccine type
  Map<String, dynamic>? _getLastVaccination(
    String goatTag,
    String vaccineName,
    List<Map<String, dynamic>> vaccinationHistory,
  ) {
    final relevantVaccinations = vaccinationHistory
        .where((event) =>
            event['medicine_given']?.toString().toLowerCase() ==
            vaccineName.toLowerCase())
        .toList();
    
    if (relevantVaccinations.isEmpty) return null;
    
    // Sort by date and return the most recent
    relevantVaccinations.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['history_date']);
        final dateB = DateTime.parse(b['history_date']);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    
    return relevantVaccinations.first;
  }

  /// Determine if a goat is dairy goat with improved logic
  bool _isDairyGoat(Goat goat) {
    // Enhanced dairy breed detection
    final dairyBreeds = [
      'holstein', 'friesian', 'jersey', 'guernsey', 'ayrshire', 'brown swiss',
      'milking shorthorn', 'dairy shorthorn', 'dairy', 'milk'
    ];
    
    if (goat.breed != null && goat.breed!.isNotEmpty) {
      final breedLower = goat.breed!.toLowerCase();
      var isDairy = dairyBreeds.any((dairyBreed) => breedLower.contains(dairyBreed));
      
      // Additional check for dairy-related terms in classification or notes
      if (!isDairy) {
        final dairyTerms = ['dairy', 'milk', 'lactation'];
        final classificationLower = goat.classification.toLowerCase();
        final notesLower = (goat.notes ?? '').toLowerCase();
        
        isDairy = dairyTerms.any((term) => 
          classificationLower.contains(term) || notesLower.contains(term));
      }
      
      return isDairy;
    }
    
    // If no breed info, check classification for dairy indicators
    final classificationLower = goat.classification.toLowerCase();
    return classificationLower.contains('dairy') || classificationLower.contains('milk');
  }

  /// Get the current stage of the goat for vaccination purposes
  String _getGoatStage(Goat goat, String classification) {
    final sex = goat.sex;
    
    if (classification == 'Kid') {
      return 'Pre-weaning Calves';
    } else if (classification == 'Growers' || classification == 'Buckling') {
      return 'Weaned Calves / Growers / Buckling';
    } else if (classification == 'Doeling' && sex == 'Female') {
      return 'Replacement Doelings';
    } else if (classification == 'Doe' && sex == 'Female') {
      return 'Pregnant Doeling & Doe';
    } else if (classification == 'Buck' && sex == 'Male') {
      return 'Breeding Does & Bucks';
    }
    
    return 'Unknown';
  }

  /// Get goat that need vaccination (overdue or due soon)
  List<Map<String, dynamic>> getGoatNeedingVaccination({
    required List<VaccinationSchedule> schedules,
    required List<Goat> allGoats,
  }) {
    final List<Map<String, dynamic>> goatNeedingVaccination = [];
    
    for (final schedule in schedules) {
      if (schedule.isOverdue || schedule.isDueSoon) {
        final goat = allGoats.firstWhere(
          (c) => c.tagNo == schedule.goatTag,
          orElse: () => Goat(
            id: 0,
            tagNo: schedule.goatTag,
            sex: '',
            classification: '',
            status: '',
            source: '',
          ),
        );
        
        // Get pregnancy info for better prioritization
        final pregnancyInfo = _getPregnancyInfo(goat.tagNo, []);
        
        goatNeedingVaccination.add({
          'goat': goat,
          'schedule': schedule,
          'urgency': schedule.urgencyLevel,
          'daysUntilDue': schedule.daysUntilDue,
          'pregnancyInfo': pregnancyInfo,
          'isPreCalvingVaccine': _isPreCalvingVaccine(VaccineType(
            name: schedule.vaccineType,
            protectsAgainst: '',
            recommendedTiming: '',
            purpose: '',
            applicableStages: [],
            ageInMonths: 0,
          )),
        });
      }
    }
    
    // Enhanced sorting with pregnancy priority
    goatNeedingVaccination.sort((a, b) {
      final scheduleA = a['schedule'] as VaccinationSchedule;
      final scheduleB = b['schedule'] as VaccinationSchedule;
      final pregnancyInfoA = a['pregnancyInfo'] as Map<String, dynamic>?;
      final pregnancyInfoB = b['pregnancyInfo'] as Map<String, dynamic>?;
      final isPreCalvingA = a['isPreCalvingVaccine'] as bool;
      final isPreCalvingB = b['isPreCalvingVaccine'] as bool;
      
      // Priority 1: Pre-calving vaccines for pregnant goat
      if (isPreCalvingA && pregnancyInfoA != null && !isPreCalvingB) return -1;
      if (!isPreCalvingA && isPreCalvingB && pregnancyInfoB != null) return 1;
      
      // Priority 2: Overdue vaccinations
      if (scheduleA.isOverdue && !scheduleB.isOverdue) return -1;
      if (!scheduleA.isOverdue && scheduleB.isOverdue) return 1;
      
      // Priority 3: Urgent pregnancy vaccinations (within 21 days)
      if (pregnancyInfoA != null && pregnancyInfoA['isUrgentVaccination'] == true && 
          pregnancyInfoB == null) {
        return -1;
      }
      if (pregnancyInfoB != null && pregnancyInfoB['isUrgentVaccination'] == true && 
          pregnancyInfoA == null) {
        return 1;
      }
      
      // Priority 4: Days until due
      return scheduleA.daysUntilDue.compareTo(scheduleB.daysUntilDue);
    });
    
    return goatNeedingVaccination;
  }

  /// Get vaccination statistics
  Map<String, dynamic> getVaccinationStatistics({
    required List<VaccinationSchedule> schedules,
    required List<Goat> allGoats,
  }) {
    final totalgoat = allGoats.length;
    final pendingVaccinations = schedules.where((s) => s.isPending).length;
    final overdueVaccinations = schedules.where((s) => s.isOverdue).length;
    final dueSoonVaccinations = schedules.where((s) => s.isDueSoon).length;
    final completedVaccinations = schedules.where((s) => s.isCompleted).length;
    
    return {
      'totalgoat': totalgoat,
      'pendingVaccinations': pendingVaccinations,
      'overdueVaccinations': overdueVaccinations,
      'dueSoonVaccinations': dueSoonVaccinations,
      'completedVaccinations': completedVaccinations,
      'vaccinationRate': totalgoat > 0 ? (completedVaccinations / totalgoat * 100).round() : 0,
    };
  }

  /// Get vaccines by stage for educational purposes
  Map<String, List<VaccineType>> getVaccinesByStage() {
    final Map<String, List<VaccineType>> vaccinesByStage = {};
    
    for (final vaccine in VaccinationProtocol.vaccineTypes) {
      for (final stage in vaccine.applicableStages) {
        if (!vaccinesByStage.containsKey(stage)) {
          vaccinesByStage[stage] = [];
        }
        vaccinesByStage[stage]!.add(vaccine);
      }
    }
    
    return vaccinesByStage;
  }

  /// Get pregnancy information for a goat with improved error handling
  Map<String, dynamic>? _getPregnancyInfo(String goatTag, List<Map<String, dynamic>> allEvents) {
    // Find the most recent pregnant event for this goat
    final pregnantEvents = allEvents
        .where((event) =>
            event['goat_tag'] == goatTag &&
            event['history_type']?.toString().toLowerCase() == 'pregnant' &&
            event['expected_delivery_date'] != null &&
            event['expected_delivery_date'].toString().isNotEmpty)
        .toList();

    if (pregnantEvents.isEmpty) {
      return null;
    }

    // Sort by event date and get the most recent
    pregnantEvents.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['history_date']);
        final dateB = DateTime.parse(b['history_date']);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    final latestPregnancy = pregnantEvents.first;
    
    try {
      final expectedDeliveryDate = DateTime.parse(latestPregnancy['expected_delivery_date']);
      final breedingDate = latestPregnancy['breeding_date'] != null 
          ? DateTime.parse(latestPregnancy['breeding_date'])
          : expectedDeliveryDate.subtract(const Duration(days: 280)); // Default gestation period
      
      final daysUntilDelivery = expectedDeliveryDate.difference(DateTime.now()).inDays;
      
      // Enhanced pregnancy info with vaccination timing
      final result = {
        'isPregnant': true,
        'breedingDate': breedingDate,
        'expectedDeliveryDate': expectedDeliveryDate,
        'daysUntilDelivery': daysUntilDelivery,
        'pregnancyEvent': latestPregnancy,
        'needsPreCalvingVaccination': daysUntilDelivery <= 30 && daysUntilDelivery > 0,
        'isUrgentVaccination': daysUntilDelivery <= 21 && daysUntilDelivery > 0,
        'isPreparationWindow': daysUntilDelivery <= 30 && daysUntilDelivery > 21,
      };
      
      return result;
    } catch (e) {
      log('⚠️ Error parsing pregnancy dates for $goatTag: $e');
      return null;
    }
  }

  /// Check if a vaccine is a pre-calving vaccine
  bool _isPreCalvingVaccine(VaccineType vaccine) {
    final preCalvingVaccines = [
      'Mastitis Vaccines',
      'Scour Vaccine',
    ];
    
    return preCalvingVaccines.contains(vaccine.name) ||
           vaccine.recommendedTiming.toLowerCase().contains('pre-calving');
  }

  /// Calculate pre-calving vaccination date based on expected delivery date
  DateTime _calculatePreCalvingVaccinationDate(
    VaccineType vaccine, 
    Map<String, dynamic> pregnancyInfo,
  ) {
    final expectedDeliveryDate = pregnancyInfo['expectedDeliveryDate'] as DateTime;
    
    // Calculate vaccination date based on vaccine type
    switch (vaccine.name) {
      case 'Scour Vaccine':
        // 3-4 weeks pre-calving (21-28 days before)
        return expectedDeliveryDate.subtract(const Duration(days: 25));
      
      case 'Mastitis Vaccines':
        // Pre-calving and during lactation (2-3 weeks before)
        return expectedDeliveryDate.subtract(const Duration(days: 21));
      
      default:
        // Default to 3 weeks before calving
        return expectedDeliveryDate.subtract(const Duration(days: 21));
    }
  }

  /// Generate appropriate notes for vaccination
  String _getVaccinationNotes(VaccineType vaccine, Map<String, dynamic>? pregnancyInfo) {
    if (_isPreCalvingVaccine(vaccine) && pregnancyInfo != null) {
      // For Mastitis, omit expected delivery date details in notes
      if (vaccine.name == 'Mastitis Vaccines') {
        return 'Pre-calving vaccination';
      }

      final expectedDeliveryDate = pregnancyInfo['expectedDeliveryDate'] as DateTime;
      final daysUntilDelivery = pregnancyInfo['daysUntilDelivery'] as int;

      if (daysUntilDelivery > 0) {
        return 'Pre-calving vaccination - Expected delivery: ${_formatDate(expectedDeliveryDate)}';
      } else {
        return 'Pre-calving vaccination - Overdue (Expected delivery: ${_formatDate(expectedDeliveryDate)})';
      }
    }
    
    return 'Initial vaccination for ${vaccine.name}';
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  /// Check if goat has already been vaccinated for the current pregnancy
  bool _isAlreadyVaccinatedForCurrentPregnancy(
    String goatTag,
    String vaccineName,
    List<Map<String, dynamic>> vaccinationHistory,
    Map<String, dynamic> pregnancyInfo,
  ) {
    final breedingDate = pregnancyInfo['breedingDate'] as DateTime;
    
    // Find vaccinations for this vaccine after the breeding date
    final relevantVaccinations = vaccinationHistory
        .where((event) =>
            event['medicine_given']?.toString().toLowerCase() == vaccineName.toLowerCase())
        .where((event) {
          try {
            final vaccinationDate = DateTime.parse(event['history_date']);
            return vaccinationDate.isAfter(breedingDate);
          } catch (_) {
            return false;
          }
        })
        .toList();
    
    return relevantVaccinations.isNotEmpty;
  }
}

