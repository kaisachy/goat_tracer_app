class Farmer {
  final int id;
  final String birthdate;
  final String gender;
  final String maritalStatus;
  final String contactNumber;
  final double farmLandArea;
  final String cooperativeAffiliation;
  final String province;
  final String municipality;
  final String barangay;

  Farmer({
    required this.id,
    required this.birthdate,
    required this.gender,
    required this.maritalStatus,
    required this.contactNumber,
    required this.farmLandArea,
    required this.cooperativeAffiliation,
    required this.province,
    required this.municipality,
    required this.barangay,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'],
      birthdate: json['birthdate'],
      gender: json['gender'],
      maritalStatus: json['marital_status'],
      contactNumber: json['contact_number'],
      farmLandArea: (json['farm_land_area'] as num).toDouble(),
      cooperativeAffiliation: json['cooperative_affiliation'],
      province: json['province'],
      municipality: json['municipality'],
      barangay: json['barangay'],
    );
  }
}

class EducationalBackground {
  final String level;
  final String schoolName;
  final int? startYear;
  final int? endYear;
  final int? yearGraduated;
  final String? course;
  final String? honorsReceived;

  EducationalBackground({
    required this.level,
    required this.schoolName,
    this.startYear,
    this.endYear,
    this.yearGraduated,
    this.course,
    this.honorsReceived,
  });

  factory EducationalBackground.fromJson(Map<String, dynamic> json) {
    return EducationalBackground(
      level: json['level'],
      schoolName: json['school_name'],
      startYear: json['start_year'] != null ? int.tryParse(json['start_year'].toString()) : null,
      endYear: json['end_year'] != null ? int.tryParse(json['end_year'].toString()) : null,
      yearGraduated: json['year_graduated'] != null ? int.tryParse(json['year_graduated'].toString()) : null,
      course: json['course'],
      honorsReceived: json['honors_received'],
    );
  }
}

class TrainingSeminar {
  final String title;
  final String? conductedBy;
  final String dateFrom;
  final String dateTo;
  final String location;
  final bool certificateIssued;

  TrainingSeminar({
    required this.title,
    this.conductedBy,
    required this.dateFrom,
    required this.dateTo,
    required this.location,
    required this.certificateIssued,
  });

  factory TrainingSeminar.fromJson(Map<String, dynamic> json) {
    return TrainingSeminar(
      title: json['title'],
      conductedBy: json['conducted_by'],
      dateFrom: json['date_from'],
      dateTo: json['date_to'],
      location: json['location'],
      certificateIssued: json['certificate_issued'].toString() == '1',
    );
  }
}
