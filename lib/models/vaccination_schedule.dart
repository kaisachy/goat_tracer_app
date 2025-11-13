class VaccinationSchedule {
  final int? id;
  final String cattleTag;
  final String vaccineType;
  final String cattleStage;
  final DateTime recommendedDate;
  final DateTime? actualDate;
  final String status;
  final String? notes;
  final String? administeredBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VaccinationSchedule({
    this.id,
    required this.cattleTag,
    required this.vaccineType,
    required this.cattleStage,
    required this.recommendedDate,
    this.actualDate,
    this.status = 'Pending',
    this.notes,
    this.administeredBy,
    this.createdAt,
    this.updatedAt,
  });

  factory VaccinationSchedule.fromJson(Map<String, dynamic> json) {
    return VaccinationSchedule(
      id: json['id'],
      cattleTag: json['cattle_tag'] ?? '',
      vaccineType: json['vaccine_type'] ?? '',
      cattleStage: json['cattle_stage'] ?? '',
      recommendedDate: DateTime.parse(json['recommended_date']),
      actualDate: json['actual_date'] != null 
          ? DateTime.parse(json['actual_date']) 
          : null,
      status: json['status'] ?? 'Pending',
      notes: json['notes'],
      administeredBy: json['administered_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cattle_tag': cattleTag,
      'vaccine_type': vaccineType,
      'cattle_stage': cattleStage,
      'recommended_date': recommendedDate.toIso8601String(),
      if (actualDate != null) 'actual_date': actualDate!.toIso8601String(),
      'status': status,
      if (notes != null) 'notes': notes,
      if (administeredBy != null) 'administered_by': administeredBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper methods
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isOverdue => status.toLowerCase() == 'overdue';
  bool get isScheduled => status.toLowerCase() == 'scheduled';

  bool get isDueSoon {
    final now = DateTime.now();
    final daysUntilDue = recommendedDate.difference(now).inDays;
    return daysUntilDue <= 30 && daysUntilDue >= 0;
  }

  int get daysUntilDue {
    final now = DateTime.now();
    return recommendedDate.difference(now).inDays;
  }

  String get urgencyLevel {
    if (isOverdue) return 'Critical';
    if (isDueSoon) return 'High';
    if (daysUntilDue <= 60) return 'Medium';
    return 'Normal';
  }

  /// Get a more detailed status description
  String get statusDescription {
    if (isCompleted) {
      return 'Completed';
    } else if (isOverdue) {
      final overdueDays = daysUntilDue.abs();
      return 'Overdue by $overdueDays days';
    } else if (isDueSoon) {
      return 'Due in $daysUntilDue days';
    } else {
      return 'Due in $daysUntilDue days';
    }
  }

  /// Check if vaccination is critical (overdue by more than 30 days)
  bool get isCritical {
    return isOverdue && daysUntilDue.abs() > 30;
  }

  /// Check if vaccination is urgent (overdue by 7-30 days or due within 7 days)
  bool get isUrgent {
    if (isOverdue) {
      final overdueDays = daysUntilDue.abs();
      return overdueDays <= 30 && overdueDays > 7;
    }
    return daysUntilDue <= 7 && daysUntilDue >= 0;
  }

  VaccinationSchedule copyWith({
    int? id,
    String? cattleTag,
    String? vaccineType,
    String? cattleStage,
    DateTime? recommendedDate,
    DateTime? actualDate,
    String? status,
    String? notes,
    String? administeredBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaccinationSchedule(
      id: id ?? this.id,
      cattleTag: cattleTag ?? this.cattleTag,
      vaccineType: vaccineType ?? this.vaccineType,
      cattleStage: cattleStage ?? this.cattleStage,
      recommendedDate: recommendedDate ?? this.recommendedDate,
      actualDate: actualDate ?? this.actualDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      administeredBy: administeredBy ?? this.administeredBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VaccineType {
  final String name;
  final String protectsAgainst;
  final String recommendedTiming;
  final String purpose;
  final List<String> applicableStages;
  final int ageInMonths;
  final bool requiresBooster;
  final int? boosterIntervalWeeks;

  const VaccineType({
    required this.name,
    required this.protectsAgainst,
    required this.recommendedTiming,
    required this.purpose,
    required this.applicableStages,
    required this.ageInMonths,
    this.requiresBooster = false,
    this.boosterIntervalWeeks,
  });
}

class VaccinationProtocol {
  static const List<VaccineType> vaccineTypes = [
    // Newborn Calf
    VaccineType(
      name: 'Scour Vaccine (Newborn Calf)',
      protectsAgainst: 'Rotavirus, Coronavirus, E. coli',
      recommendedTiming: 'Within 24 hours of birth',
      purpose: 'Provides passive immunity to prevent calf scours',
      applicableStages: ['Newborn Calf'],
      ageInMonths: 0,
    ),
    
    // Pre-weaning Calves
    VaccineType(
      name: 'Clostridial (7-way)',
      protectsAgainst: 'Blackleg, Malignant Edema, etc.',
      recommendedTiming: '2-4 months of age',
      purpose: 'Protects against common soil-borne bacteria',
      applicableStages: ['Pre-weaning Calves'],
      ageInMonths: 3,
      requiresBooster: true,
      boosterIntervalWeeks: 6,
    ),
    
    VaccineType(
      name: 'Respiratory (5-way)',
      protectsAgainst: 'IBR, BVD, PI3, BRSV',
      recommendedTiming: '2-4 months of age',
      purpose: 'Core respiratory disease prevention',
      applicableStages: ['Pre-weaning Calves'],
      ageInMonths: 3,
      requiresBooster: true,
      boosterIntervalWeeks: 6,
    ),
    
    // Weaned Calves / Growers / Steer
    VaccineType(
      name: 'Clostridial (7-way) Booster',
      protectsAgainst: 'Blackleg, Malignant Edema, etc.',
      recommendedTiming: 'At weaning (6–8 months)',
      purpose: 'Strengthens initial immunity during stress of weaning and new groups/feeds',
      applicableStages: ['Weaned Calves / Growers / Steer'],
      ageInMonths: 6,
    ),
    
    VaccineType(
      name: 'Respiratory (5-way) Booster',
      protectsAgainst: 'IBR, BVD, PI3, BRSV',
      recommendedTiming: 'At weaning (6–8 months)',
      purpose: 'Strengthens initial immunity during stress of weaning and new groups/feeds',
      applicableStages: ['Weaned Calves / Growers / Steer'],
      ageInMonths: 6,
    ),
    
    VaccineType(
      name: 'Leptospirosis',
      protectsAgainst: 'Leptospirosis',
      recommendedTiming: 'At weaning (6–8 months)',
      purpose: 'Strengthens overall protection at a critical transition; helps prevent Leptospirosis',
      applicableStages: ['Weaned Calves / Growers / Steer'],
      ageInMonths: 6,
    ),
    
    // Replacement Heifers
    VaccineType(
      name: 'Brucellosis (Strain RB51)',
      protectsAgainst: 'Brucellosis',
      recommendedTiming: '4-12 months of age (once)',
      purpose: 'Prevents Brucellosis causing abortion',
      applicableStages: ['Replacement Heifers'],
      ageInMonths: 8,
    ),
    
    VaccineType(
      name: 'Reproductive (IBR, BVD, Lepto, Vibriosis) - Heifers',
      protectsAgainst: 'IBR, BVD, Leptospirosis, Vibriosis',
      recommendedTiming: 'Pre-breeding',
      purpose: 'Ensures reproductive health before breeding',
      applicableStages: ['Replacement Heifers'],
      ageInMonths: 12,
    ),
    
    // Breeding Cows & Bulls
    VaccineType(
      name: 'Reproductive (IBR, BVD, Lepto, Vibriosis) - Breeding',
      protectsAgainst: 'IBR, BVD, Leptospirosis, Vibriosis',
      recommendedTiming: 'Annually, 30-60 days pre-breeding',
      purpose: 'Protects herd from reproductive diseases',
      applicableStages: ['Breeding Cows & Bulls'],
      ageInMonths: 18,
    ),
    
    VaccineType(
      name: 'Clostridial (7-way) Annual',
      protectsAgainst: 'Blackleg, Malignant Edema, etc.',
      recommendedTiming: 'Annually',
      purpose: 'Annual booster to maintain protection',
      applicableStages: ['Breeding Cows & Bulls'],
      ageInMonths: 18,
    ),
    
    // Pregnant Heifer & Cow
    VaccineType(
      name: 'Mastitis Vaccines',
      protectsAgainst: 'E. coli, Mycoplasma, Staph',
      recommendedTiming: 'Pre-calving and during lactation',
      purpose: 'Reduces severity of mastitis infections',
      applicableStages: ['Pregnant Heifer & Cow'],
      ageInMonths: 24,
    ),
    
    VaccineType(
      name: 'Scour Vaccine (Pre-calving)',
      protectsAgainst: 'Rotavirus, Coronavirus, E. coli',
      recommendedTiming: '3-4 weeks pre-calving',
      purpose: 'Boosts antibodies in colostrum for newborn',
      applicableStages: ['Pregnant Heifer & Cow'],
      ageInMonths: 24,
    ),
    

  ];

  /// Get applicable vaccines for a cattle based on age, classification, and pregnancy status
  static List<VaccineType> getApplicableVaccines({
    required int ageInMonths,
    required int ageInDays,
    required String classification,
    required String sex,
    required bool isDairy,
    required String status,
    bool isPregnant = false,
  }) {
    final List<VaccineType> applicableVaccines = [];
    
    for (final vaccine in vaccineTypes) {
      if (_isVaccineApplicable(
        vaccine: vaccine,
        ageInMonths: ageInMonths,
        ageInDays: ageInDays,
        classification: classification,
        sex: sex,
        isDairy: isDairy,
        status: status,
        isPregnant: isPregnant,
      )) {
        applicableVaccines.add(vaccine);
      }
    }
    
    return applicableVaccines;
  }

  static bool _isVaccineApplicable({
    required VaccineType vaccine,
    required int ageInMonths,
    required int ageInDays,
    required String classification,
    required String sex,
    required bool isDairy,
    required String status,
    bool isPregnant = false,
  }) {
    // Check age requirement
    if (ageInMonths < vaccine.ageInMonths) {
      return false;
    }

    // Check if this is a pre-calving vaccine
    final isPreCalvingVaccine = _isPreCalvingVaccine(vaccine);
    
    // For pre-calving vaccines, only apply to pregnant cattle
    if (isPreCalvingVaccine) {
      return isPregnant && _matchesPreCalvingStage(vaccine, classification, sex, isDairy, status);
    }
    
    // For non-pre-calving vaccines, use normal stage matching
    for (final stage in vaccine.applicableStages) {
      if (_matchesStage(stage, classification, sex, isDairy, status, ageInMonths, ageInDays)) {
        return true;
      }
    }

    return false;
  }

  static bool _matchesStage(String stage, String classification, String sex, bool isDairy, String status, int ageInMonths, int ageInDays) {
    switch (stage) {
      case 'Newborn Calf':
        // Only apply to 1 day old calves
        return classification == 'Calf' && ageInDays <= 1;
      case 'Pre-weaning Calves':
        return classification == 'Calf';
      
      case 'Weaned Calves / Growers / Steer':
        return classification == 'Growers' || classification == 'Steer';
      
      case 'Replacement Heifers':
        return classification == 'Heifer' && sex == 'Female';
      
      case 'Breeding Cows & Bulls':
        return (classification == 'Cow' && sex == 'Female') || 
               (classification == 'Bull' && sex == 'Male');
      
      case 'Pregnant Heifer & Cow':
        return ((classification == 'Cow' && sex == 'Female') || 
                (classification == 'Heifer' && sex == 'Female')) &&
               (status.toLowerCase() == 'pregnant' || 
                status.toLowerCase() == 'lactating & pregnant');
      
      case 'All Stages':
        return true;
      
      default:
        return false;
    }
  }

  /// Get next vaccination date for a specific vaccine
  static DateTime getNextVaccinationDate({
    required DateTime lastVaccinationDate,
    required VaccineType vaccine,
    required int ageInMonths,
  }) {
    if (vaccine.requiresBooster && vaccine.boosterIntervalWeeks != null) {
      return lastVaccinationDate.add(Duration(days: vaccine.boosterIntervalWeeks! * 7));
    }
    
    // For annual vaccines, add 1 year
    if (vaccine.name.toLowerCase().contains('annual')) {
      return lastVaccinationDate.add(const Duration(days: 365));
    }
    
    // Default: no repeat needed
    return lastVaccinationDate;
  }

  /// Check if a vaccine is a pre-calving vaccine
  static bool _isPreCalvingVaccine(VaccineType vaccine) {
    final preCalvingVaccines = [
      'Mastitis Vaccines',
      'Scour Vaccine (Pre-calving)',
    ];
    
    return preCalvingVaccines.contains(vaccine.name) ||
           vaccine.recommendedTiming.toLowerCase().contains('pre-calving');
  }

  /// Check if cattle matches stage requirements for pre-calving vaccines
  static bool _matchesPreCalvingStage(VaccineType vaccine, String classification, String sex, bool isDairy, String status) {
    // Pre-calving vaccines are for pregnant cows and heifers (both dairy and beef)
    return (classification == 'Cow' || classification == 'Heifer') &&
           sex == 'Female' &&
           (status.toLowerCase() == 'pregnant' || 
            status.toLowerCase() == 'lactating & pregnant');
  }
}
