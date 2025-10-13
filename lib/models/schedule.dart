class Schedule {
  final int? id;
  final int userId;
  final String title;
  final String? cattleTag;
  final String type;
  final DateTime scheduleDateTime;
  final String? duration;
  final String? reminder;
  final String status;
  final String? scheduledBy;
  final String? details;
  final String? vaccineType;
  final String? creatorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Schedule({
    this.id,
    required this.userId,
    required this.title,
    this.cattleTag,
    required this.type,
    required this.scheduleDateTime,
    this.duration,
    this.reminder,
    this.status = 'Scheduled',
    this.scheduledBy,
    this.details,
    this.vaccineType,
    this.creatorName,
    this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    try {
      return Schedule(
        id: _parseId(json['id']),
        userId: _parseInt(json['user_id']) ?? 0,
        title: json['title']?.toString() ?? '',
        cattleTag: _normalizeCattleTag(json['cattle_tag']?.toString()),
        type: json['type']?.toString() ?? 'Other',
        scheduleDateTime: _parseDateTime(json['schedule_datetime']) ?? DateTime.now(),
        duration: json['duration']?.toString(),
        reminder: json['reminder']?.toString(),
        status: json['status']?.toString() ?? 'Scheduled',
        scheduledBy: json['scheduled_by']?.toString(),
        details: json['details']?.toString(),
        vaccineType: json['vaccine_type']?.toString(),
        creatorName: _getCreatorName(json),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      throw Exception('Error parsing Schedule from JSON: $e\nJSON: $json');
    }
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      try {
        // Handle different datetime formats
        if (value.contains('T')) {
          return DateTime.parse(value);
        } else if (value.contains(' ')) {
          // Handle MySQL datetime format: YYYY-MM-DD HH:MM:SS
          return DateTime.parse(value.replaceFirst(' ', 'T'));
        } else {
          return DateTime.parse(value);
        }
      } catch (e) {
        print('Error parsing datetime: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  // Normalize cattle tag to ensure consistent format
  static String? _normalizeCattleTag(String? cattleTag) {
    if (cattleTag == null || cattleTag.isEmpty) {
      return null;
    }

    // Split by comma, trim whitespace, convert to uppercase, and rejoin
    final tags = cattleTag
        .split(',')
        .map((tag) => tag.trim().toUpperCase())
        .where((tag) => tag.isNotEmpty)
        .toList();

    return tags.isEmpty ? null : tags.join(',');
  }

  // Get creator name from JSON data
  static String? _getCreatorName(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString();
    final lastName = json['last_name']?.toString();
    
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName;
    } else if (lastName != null) {
      return lastName;
    }
    
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'cattle_tag': cattleTag,
      'type': type,
      'schedule_datetime': scheduleDateTime.toIso8601String(),
      'duration': duration,
      'reminder': reminder,
      'status': status,
      'scheduled_by': scheduledBy,
      'details': details,
      if (vaccineType != null) 'vaccine_type': vaccineType,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper method to convert DateTime to MySQL format for API
  Map<String, dynamic> toApiJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'cattle_tag': cattleTag,
      'type': type,
      'schedule_datetime': _formatDateTime(scheduleDateTime),
      'duration': duration,
      'reminder': reminder,
      'status': status,
      'scheduled_by': scheduledBy,
      'details': details,
      if (vaccineType != null) 'vaccine_type': vaccineType,
    };
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  // Copy method for easy updates
  Schedule copyWith({
    int? id,
    int? userId,
    String? title,
    String? cattleTag,
    String? type,
    DateTime? scheduleDateTime,
    String? duration,
    String? reminder,
    String? status,
    String? scheduledBy,
    String? details,
    String? vaccineType,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      cattleTag: cattleTag ?? this.cattleTag,
      type: type ?? this.type,
      scheduleDateTime: scheduleDateTime ?? this.scheduleDateTime,
      duration: duration ?? this.duration,
      reminder: reminder ?? this.reminder,
      status: status ?? this.status,
      scheduledBy: scheduledBy ?? this.scheduledBy,
      details: details ?? this.details,
      vaccineType: vaccineType ?? this.vaccineType,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for status checking
  bool get isScheduled => status.toLowerCase() == 'scheduled';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  // Helper methods for field checking
  bool get hasDuration => duration != null && duration!.isNotEmpty;
  bool get hasReminder => reminder != null && reminder!.isNotEmpty;
  bool get hasScheduledBy => scheduledBy != null && scheduledBy!.isNotEmpty;

  // Helper method to check if schedule is overdue
  bool get isOverdue => isScheduled && scheduleDateTime.isBefore(DateTime.now());

  // Helper method to check if schedule is upcoming (within specified days)
  bool isUpcoming({int days = 7}) {
    if (!isScheduled) return false;
    final now = DateTime.now();
    final deadline = now.add(Duration(days: days));
    return scheduleDateTime.isAfter(now) && scheduleDateTime.isBefore(deadline);
  }

  // Helper methods for cattle tag handling
  List<String> get cattleTagsList {
    if (cattleTag == null || cattleTag!.isEmpty) {
      return [];
    }
    return cattleTag!
        .split(',')
        .map((tag) => tag.trim().toUpperCase())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  bool containsCattleTag(String tag) {
    final normalizedTag = tag.trim().toUpperCase();
    return cattleTagsList.contains(normalizedTag);
  }

  // Check if this schedule is assigned to multiple cattle
  bool get isMultipleCattleSchedule => cattleTagsList.length > 1;

  // Get the primary cattle tag (first one in the list)
  String? get primaryCattleTag => cattleTagsList.isNotEmpty ? cattleTagsList.first : null;

  // Get additional cattle tags (excluding the first one)
  List<String> get additionalCattleTags =>
      cattleTagsList.length > 1 ? cattleTagsList.skip(1).toList() : [];

  @override
  String toString() {
    return 'Schedule{id: $id, title: $title, type: $type, scheduleDateTime: $scheduleDateTime, status: $status, cattleTag: $cattleTag}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Schedule &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              title == other.title &&
              cattleTag == other.cattleTag &&
              type == other.type &&
              scheduleDateTime == other.scheduleDateTime &&
              duration == other.duration &&
              reminder == other.reminder &&
              status == other.status &&
              scheduledBy == other.scheduledBy &&
              details == other.details &&
              vaccineType == other.vaccineType &&
              creatorName == other.creatorName;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      cattleTag.hashCode ^
      type.hashCode ^
      scheduleDateTime.hashCode ^
      duration.hashCode ^
      reminder.hashCode ^
      status.hashCode ^
      scheduledBy.hashCode ^
      details.hashCode ^
      vaccineType.hashCode ^
      creatorName.hashCode;
}

// Constants for enum values
class ScheduleType {
  static const String vaccination = 'Vaccination';
  static const String deworming = 'Deworming';
  static const String hoofTrimming = 'Hoof Trimming';
  static const String feed = 'Feed';
  static const String weigh = 'Weigh';
  static const String other = 'Other';

  static const List<String> values = [
    vaccination,
    deworming,
    hoofTrimming,
    feed,
    weigh,
    other,
  ];
}


class ScheduleStatus {
  static const String scheduled = 'Scheduled';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';

  static const List<String> values = [scheduled, completed, cancelled];
}