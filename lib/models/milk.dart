class MilkProduction {
  final int id;
  final String? goatTag;
  final DateTime recordDate;
  final String? milkType;
  final double? morningYield;
  final double? eveningYield;
  final double? totalYield;
  final String? milkQuality;
  final String? notes;
  final DateTime? createdAt;

  MilkProduction({
    required this.id,
    this.goatTag,
    required this.recordDate,
    required this.milkType,
    this.morningYield,
    this.eveningYield,
    this.totalYield,
    this.milkQuality,
    this.notes,
    this.createdAt,
  });

  factory MilkProduction.fromJson(Map<String, dynamic> json) {
    return MilkProduction(
      id: json['id'] ?? 0,
      goatTag: json['goat_tag'],
      recordDate: DateTime.parse(json['record_date']),
      milkType: json['milk_type'],
      morningYield: json['morning_yield'] != null
          ? double.tryParse(json['morning_yield'].toString())
          : null,
      eveningYield: json['evening_yield'] != null
          ? double.tryParse(json['evening_yield'].toString())
          : null,
      totalYield: json['total_yield'] != null
          ? double.tryParse(json['total_yield'].toString())
          : null,
      milkQuality: json['milk_quality'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goat_tag': goatTag,
      'record_date': recordDate.toIso8601String(),
      'milk_type': milkType,
      'morning_yield': morningYield,
      'evening_yield': eveningYield,
      'total_yield': totalYield,
      'milk_quality': milkQuality,
      'notes': notes,
    };
  }
}
