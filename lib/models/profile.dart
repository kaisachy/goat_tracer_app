class Farmer {
  final int id;
  final int userId;
  final String? profilePicture;
  final String birthdate;
  final String sex;
  final String maritalStatus;
  final String contactNumber;

  Farmer({
    required this.id,
    required this.userId,
    this.profilePicture,
    required this.birthdate,
    required this.sex,
    required this.maritalStatus,
    required this.contactNumber,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'],
      userId: json['user_id'],
      profilePicture: json['profile_picture'],
      birthdate: json['birthdate'],
      sex: json['sex'],
      maritalStatus: json['marital_status'],
      contactNumber: json['contact_number'],
    );
  }
}

class FarmDetail {
  final int id;
  final int userId;
  final String farmName;
  final String farmType;
  final String farmClassification;
  final String farmLandArea;
  final String cooperativeAffiliation;
  final String farmProvince;
  final String farmMunicipality;
  final String farmBarangay;
  final double? farmLatitude;
  final double? farmLongitude;

  FarmDetail({
    required this.id,
    required this.userId,
    required this.farmName,
    required this.farmType,
    required this.farmClassification,
    required this.farmLandArea,
    required this.cooperativeAffiliation,
    required this.farmProvince,
    required this.farmMunicipality,
    required this.farmBarangay,
    this.farmLatitude,
    this.farmLongitude,
  });

  factory FarmDetail.fromJson(Map<String, dynamic> json) {
    return FarmDetail(
      id: json['id'],
      userId: json['user_id'],
      farmName: json['farm_name'],
      farmType: json['farm_type'],
      farmClassification: json['farm_classification'],
      farmLandArea: json['farm_land_area']?.toString() ?? '',
      cooperativeAffiliation: json['cooperative_affiliation'],
      farmProvince: json['farm_province'] ?? 'Isabela',
      farmMunicipality: json['farm_municipality'] ?? '',
      farmBarangay: json['farm_barangay'] ?? '',
      farmLatitude: json['farm_latitude'] != null ? double.tryParse(json['farm_latitude'].toString()) : null,
      farmLongitude: json['farm_longitude'] != null ? double.tryParse(json['farm_longitude'].toString()) : null,
    );
  }

  // Helper method to get formatted address
  String get formattedAddress {
    final parts = <String>[];
    if (farmBarangay.isNotEmpty) parts.add(farmBarangay);
    if (farmMunicipality.isNotEmpty) parts.add(farmMunicipality);
    if (farmProvince.isNotEmpty) parts.add(farmProvince);
    return parts.join(', ');
  }
}

class EducationalBackground {
  final int id;
  final int userId;
  final String level;
  final String schoolName;
  final int? yearGraduated;
  final String? course;

  EducationalBackground({
    required this.id,
    required this.userId,
    required this.level,
    required this.schoolName,
    this.yearGraduated,
    this.course,
  });

  factory EducationalBackground.fromJson(Map<String, dynamic> json) {
    return EducationalBackground(
      id: json['id'],
      userId: json['user_id'],
      level: json['level'],
      schoolName: json['school_name'],
      yearGraduated: json['year_graduated'] != null ? int.tryParse(json['year_graduated'].toString()) : null,
      course: json['course'],
    );
  }
}

class TrainingSeminar {
  final String title;
  final String? conductedBy;
  final String? dateFrom;
  final String? dateTo;
  final String location;
  final bool certificateIssued;

  TrainingSeminar({
    required this.title,
    this.conductedBy,
    this.dateFrom,
    this.dateTo,
    required this.location,
    required this.certificateIssued,
  });

  factory TrainingSeminar.fromJson(Map<String, dynamic> json) {
    return TrainingSeminar(
      title: json['title'] ?? '',
      conductedBy: json['conducted_by'],
      dateFrom: json['date_from']?.toString(),
      dateTo: json['date_to']?.toString(),
      location: json['location'] ?? '',
      certificateIssued: json['certificate_issued'].toString() == '1',
    );
  }
}


