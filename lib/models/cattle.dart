import 'dart:convert';
import 'dart:typed_data';

class Cattle {
  final int id;
  final String tagNo;
  final String? name;
  final String? dateOfBirth;
  final String gender;
  final double? weight;
  final String classification;
  final String status;
  final String? breed;
  final String? groupName;
  final String? joinedDate;
  final String source;
  final String? motherTag;
  final String? fatherTag;
  final String? offspring; // Added this line
  final String? notes;
  final String? cattlePicture;
  final String? age;

  Cattle({
    required this.id,
    required this.tagNo,
    this.name,
    this.dateOfBirth,
    required this.gender,
    this.weight,
    required this.classification,
    required this.status,
    this.breed,
    this.groupName,
    this.joinedDate,
    required this.source,
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
      name: json['name'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'] ?? '',
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      classification: json['classification'] ?? '',
      status: json['status'] ?? 'Active',
      breed: json['breed'],
      groupName: json['group_name'],
      joinedDate: json['joined_date'],
      source: json['source'] ?? 'Born on farm',
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
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'weight': weight,
      'classification': classification,
      'status': status,
      'breed': breed,
      'group_name': groupName,
      'joined_date': joinedDate,
      'source': source,
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
      print('Error decoding cattle picture: $e');
      return null;
    }
  }

  /// Check if cattle has a picture
  bool get hasPicture => cattlePicture != null && cattlePicture!.isNotEmpty;

  /// Create a copy with updated fields
  Cattle copyWith({
    int? id,
    String? tagNo,
    String? name,
    String? dateOfBirth,
    String? gender,
    double? weight,
    String? classification,
    String? status,
    String? breed,
    String? groupName,
    String? joinedDate,
    String? source,
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
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      classification: classification ?? this.classification,
      status: status ?? this.status,
      breed: breed ?? this.breed,
      groupName: groupName ?? this.groupName,
      joinedDate: joinedDate ?? this.joinedDate,
      source: source ?? this.source,
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
    return 'Cattle{id: $id, tagNo: $tagNo, name: $name, gender: $gender, offspring: $offspring, classification: $classification, status: $status, hasPicture: $hasPicture}';
  }
}

class CattleEvent {
  final int id;
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
  final String? createdAt;

  CattleEvent({
    required this.id,
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
    this.createdAt,
  });

  factory CattleEvent.fromJson(Map<String, dynamic> json) {
    return CattleEvent(
      id: json['id'],
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
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'created_at': createdAt,
    };
  }
}