import 'dart:convert';
import 'dart:typed_data';

class Goat {
  final int id;
  final String tagNo;
  final String? dateOfBirth;
  final String sex;
  final double? weight;
  final String classification;
  final String status;
  final String? breed;
  final String? groupName;
  final String source;
  final String? sourceDetails; // NEW: For storing additional source information
  final String? motherTag;
  final String? fatherTag;
  final String? offspring; // Added this line
  final String? notes;
  final String? goatPicture;
  final String? age;

  Goat({
    required this.id,
    required this.tagNo,
    this.dateOfBirth,
    required this.sex,
    this.weight,
    required this.classification,
    required this.status,
    this.breed,
    this.groupName,
    required this.source,
    this.sourceDetails, // Added this line
    this.motherTag,
    this.fatherTag,
    this.offspring, // Added this line
    this.notes,
    this.goatPicture,
    this.age,
  });

  factory Goat.fromJson(Map<String, dynamic> json) {
    return Goat(
      id: json['id'],
      tagNo: json['tag_no'] ?? '',
      dateOfBirth: json['date_of_birth'],
      sex: json['sex'] ?? '',
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      classification: json['classification'] ?? '',
      status: json['status'] ?? 'Healthy',
      breed: json['breed'],
      groupName: json['group_name'],
      source: json['source'] ?? 'Born on farm',
      sourceDetails: json['source_details'], // Added this line
      motherTag: json['mother_tag'],
      fatherTag: json['father_tag'],
      offspring: json['offspring'], // Added this line
      notes: json['notes'],
      goatPicture: json['goat_picture'], // Base64 from backend
      age: json['age'], // Computed age from backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_no': tagNo,
      'date_of_birth': dateOfBirth,
      'sex': sex,
      'weight': weight,
      'classification': classification,
      'status': status,
      'breed': breed,
      'group_name': groupName,
      'source': source,
      'source_details': sourceDetails, // Added this line
      'mother_tag': motherTag,
      'father_tag': fatherTag,
      'offspring': offspring, // Added this line
      'notes': notes,
      'goat_picture': goatPicture,
    };
  }

  /// Get image as Uint8List for display
  Uint8List? get imageBytes {
    if (goatPicture == null || goatPicture!.isEmpty) {
      return null;
    }

    try {
      return base64Decode(goatPicture!);
    } catch (e) {
      return null;
    }
  }

  /// Check if Goat has a picture
  bool get hasPicture => goatPicture != null && goatPicture!.isNotEmpty;

  /// Get computed age in months from date of birth
  int? get computedAgeInMonths {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) {
      return null;
    }

    try {
      final birthDate = DateTime.parse(dateOfBirth!);
      final now = DateTime.now();
      final difference = now.difference(birthDate);
      return (difference.inDays / 30.44).round(); // Average days per month
    } catch (e) {
      return null;
    }
  }

  /// Get age string for display (prioritizes backend age, falls back to computed age)
  String? get displayAge {
    // First try to use the backend-provided age
    if (age != null && age!.isNotEmpty) {
      return age;
    }
    
    // Fall back to computed age from date of birth
    final computedAge = computedAgeInMonths;
    if (computedAge != null) {
      return computedAge.toString();
    }
    
    return null;
  }

  /// Create a copy with updated fields
  Goat copyWith({
    int? id,
    String? tagNo,
    String? dateOfBirth,
    String? sex,
    double? weight,
    String? classification,
    String? status,
    String? breed,
    String? groupName,
    String? source,
    String? sourceDetails, // Added this line
    String? motherTag,
    String? fatherTag,
    String? offspring, // Added this line
    String? notes,
    String? goatPicture,
    String? age,
  }) {
    return Goat(
      id: id ?? this.id,
      tagNo: tagNo ?? this.tagNo,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      weight: weight ?? this.weight,
      classification: classification ?? this.classification,
      status: status ?? this.status,
      breed: breed ?? this.breed,
      groupName: groupName ?? this.groupName,
      source: source ?? this.source,
      sourceDetails: sourceDetails ?? this.sourceDetails, // Added this line
      motherTag: motherTag ?? this.motherTag,
      fatherTag: fatherTag ?? this.fatherTag,
      offspring: offspring ?? this.offspring, // Added this line
      notes: notes ?? this.notes,
      goatPicture: goatPicture ?? this.goatPicture,
      age: age ?? this.age,
    );
  }

  @override
  String toString() {
    return 'Goat{id: $id, tagNo: $tagNo, sex: $sex, offspring: $offspring, classification: $classification, status: $status, hasPicture: $hasPicture}';
  }
}

class GoatHistoryRecord {
  final int id;
  final int userId;
  final String goatTag;
  final String? buckTag;
  final String? kidTag;
  final String historyType;
  final String historyDate;
  final String? sicknessSymptoms;
  final String? diagnosis;
  final String? technician;
  final String? medicineGiven;
  final String? semenUsed;
  final String? estimatedReturnDate;
  final double? weighedResult;
  final String? breedingDate;
  final String? expectedDeliveryDate;
  final String? notes;
  final String? lastKnownLocation;
  final double? soldAmount;
  final String? buyer;
  final String? createdAt;

  GoatHistoryRecord({
    required this.id,
    required this.userId,
    required this.goatTag,
    this.buckTag,
    this.kidTag,
    required this.historyType,
    required this.historyDate,
    this.sicknessSymptoms,
    this.diagnosis,
    this.technician,
    this.medicineGiven,
    this.semenUsed,
    this.estimatedReturnDate,
    this.weighedResult,
    this.breedingDate,
    this.expectedDeliveryDate,
    this.notes,
    this.lastKnownLocation,
    this.soldAmount,
    this.buyer,
    this.createdAt,
  });

  factory GoatHistoryRecord.fromJson(Map<String, dynamic> json) {
    return GoatHistoryRecord(
      id: json['id'],
      userId: json['user_id'],
      goatTag: json['goat_tag'],
      buckTag: json['buck_tag'],
      kidTag: json['kid_tag'] ?? json['KidTag'],
      historyType: json['history_type'],
      historyDate: json['history_date'],
      sicknessSymptoms: json['sickness_symptoms'],
      diagnosis: json['diagnosis'],
      technician: json['technician'],
      medicineGiven: json['medicine_given'],
      semenUsed: json['semen_used'],
      estimatedReturnDate: json['estimated_return_date'],
      weighedResult: json['weighed_result'] != null
          ? double.tryParse(json['weighed_result'].toString())
          : null,
      breedingDate: json['breeding_date'],
      expectedDeliveryDate: json['expected_delivery_date'],
      notes: json['notes'],
      lastKnownLocation: json['last_known_location'],
      soldAmount: json['sold_amount'] != null
          ? double.tryParse(json['sold_amount'].toString())
          : null,
      buyer: json['buyer'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goat_tag': goatTag,
      'buck_tag': buckTag,
      'kid_tag': kidTag,
      'history_type': historyType,
      'history_date': historyDate,
      'sickness_symptoms': sicknessSymptoms,
      'diagnosis': diagnosis,
      'technician': technician,
      'medicine_given': medicineGiven,
      'semen_used': semenUsed,
      'estimated_return_date': estimatedReturnDate,
      'weighed_result': weighedResult,
      'breeding_date': breedingDate,
      'expected_delivery_date': expectedDeliveryDate,
      'notes': notes,
      'last_known_location': lastKnownLocation,
      'sold_amount': soldAmount,
      'buyer': buyer,
      'created_at': createdAt,
    };
  }
}