import 'dart:convert';
import 'dart:typed_data';

class Cattle {
  final int id;
  final String tagNo;
  final String? dateOfBirth;
  final String sex;
  final double? weight;
  final String classification;
  final String status;
  final String? breed;
  final String? groupName;
  final String? joinedDate;
  final String source;
  final String? sourceDetails; // NEW: For storing additional source information
  final String? motherTag;
  final String? fatherTag;
  final String? offspring; // Added this line
  final String? notes;
  final String? cattlePicture;
  final String? age;

  Cattle({
    required this.id,
    required this.tagNo,
    this.dateOfBirth,
    required this.sex,
    this.weight,
    required this.classification,
    required this.status,
    this.breed,
    this.groupName,
    this.joinedDate,
    required this.source,
    this.sourceDetails, // Added this line
    this.motherTag,
    this.fatherTag,
    this.offspring, // Added this line
    this.notes,
    this.cattlePicture,
    this.age,
  });

  factory Cattle.fromJson(Map<String, dynamic> json) {
    return Cattle(
      id: json['id'],
      tagNo: json['tag_no'] ?? '',
      dateOfBirth: json['date_of_birth'],
      sex: json['sex'] ?? '',
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      classification: json['classification'] ?? '',
      status: json['status'] ?? 'Healthy',
      breed: json['breed'],
      groupName: json['group_name'],
      joinedDate: json['joined_date'],
      source: json['source'] ?? 'Born on farm',
      sourceDetails: json['source_details'], // Added this line
      motherTag: json['mother_tag'],
      fatherTag: json['father_tag'],
      offspring: json['offspring'], // Added this line
      notes: json['notes'],
      cattlePicture: json['cattle_picture'], // Base64 from backend
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
      'joined_date': joinedDate,
      'source': source,
      'source_details': sourceDetails, // Added this line
      'mother_tag': motherTag,
      'father_tag': fatherTag,
      'offspring': offspring, // Added this line
      'notes': notes,
      'cattle_picture': cattlePicture,
    };
  }

  /// Get image as Uint8List for display
  Uint8List? get imageBytes {
    if (cattlePicture == null || cattlePicture!.isEmpty) {
      return null;
    }

    try {
      return base64Decode(cattlePicture!);
    } catch (e) {
      return null;
    }
  }

  /// Check if cattle has a picture
  bool get hasPicture => cattlePicture != null && cattlePicture!.isNotEmpty;

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
  Cattle copyWith({
    int? id,
    String? tagNo,
    String? dateOfBirth,
    String? sex,
    double? weight,
    String? classification,
    String? status,
    String? breed,
    String? groupName,
    String? joinedDate,
    String? source,
    String? sourceDetails, // Added this line
    String? motherTag,
    String? fatherTag,
    String? offspring, // Added this line
    String? notes,
    String? cattlePicture,
    String? age,
  }) {
    return Cattle(
      id: id ?? this.id,
      tagNo: tagNo ?? this.tagNo,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      weight: weight ?? this.weight,
      classification: classification ?? this.classification,
      status: status ?? this.status,
      breed: breed ?? this.breed,
      groupName: groupName ?? this.groupName,
      joinedDate: joinedDate ?? this.joinedDate,
      source: source ?? this.source,
      sourceDetails: sourceDetails ?? this.sourceDetails, // Added this line
      motherTag: motherTag ?? this.motherTag,
      fatherTag: fatherTag ?? this.fatherTag,
      offspring: offspring ?? this.offspring, // Added this line
      notes: notes ?? this.notes,
      cattlePicture: cattlePicture ?? this.cattlePicture,
      age: age ?? this.age,
    );
  }

  @override
  String toString() {
    return 'Cattle{id: $id, tagNo: $tagNo, sex: $sex, offspring: $offspring, classification: $classification, status: $status, hasPicture: $hasPicture}';
  }
}

class CattleEvent {
  final int id;
  final int userId;
  final String cattleTag;
  final String? bullTag;
  final String? calfTag;
  final String eventType;
  final String eventDate;
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
  final String? createdAt;

  CattleEvent({
    required this.id,
    required this.userId,
    required this.cattleTag,
    this.bullTag,
    this.calfTag,
    required this.eventType,
    required this.eventDate,
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
    this.createdAt,
  });

  factory CattleEvent.fromJson(Map<String, dynamic> json) {
    return CattleEvent(
      id: json['id'],
      userId: json['user_id'],
      cattleTag: json['cattle_tag'],
      bullTag: json['bull_tag'],
      calfTag: json['calf_tag'],
      eventType: json['event_type'],
      eventDate: json['event_date'],
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
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cattle_tag': cattleTag,
      'bull_tag': bullTag,
      'calf_tag': calfTag,
      'event_type': eventType,
      'event_date': eventDate,
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
      'created_at': createdAt,
    };
  }
}