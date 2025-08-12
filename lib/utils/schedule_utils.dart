import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../models/schedule.dart';

class ScheduleUtils {
  // Get color for priority
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red; // Fixed: Use Material Colors directly
      case 'medium':
        return Colors.orange; // Fixed: Use Material Colors directly
      case 'low':
        return Colors.green; // Fixed: Use Material Colors directly
      default:
        return AppColors.textSecondary;
    }
  }

  // Get icon for schedule type
  static IconData getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return FontAwesomeIcons.syringe;
      case 'deworming':
        return FontAwesomeIcons.pills;
      case 'hoof trimming':
        return FontAwesomeIcons.cut;
      case 'feed':
        return FontAwesomeIcons.bowlFood;
      case 'weigh':
        return FontAwesomeIcons.weight;
      case 'breeding':
        return FontAwesomeIcons.heart;
      default:
        return FontAwesomeIcons.calendar;
    }
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green; // Fixed: Use Material Colors directly
      case 'cancelled':
        return AppColors.textSecondary;
      case 'scheduled':
      default:
        return AppColors.primary;
    }
  }

  // Format date time for display
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
  }

  // Format date time for detail view
  static String formatDetailDateTime(DateTime dateTime) {
    return DateFormat('MMMM dd, yyyy - HH:mm').format(dateTime);
  }

  // Check if schedule needs attention (overdue or due soon)
  static bool needsAttention(Schedule schedule) {
    return schedule.isOverdue || (schedule.isUpcoming(days: 1) && schedule.priority == SchedulePriority.high);
    }

  // Get attention level for visual indicators
  static AttentionLevel getAttentionLevel(Schedule schedule) {
    if (schedule.isOverdue) return AttentionLevel.urgent;
    if (schedule.isUpcoming(days: 1)) return AttentionLevel.soon;
    if (schedule.isUpcoming(days: 7)) return AttentionLevel.upcoming;
    return AttentionLevel.normal;
  }

  // Validate schedule data
  static String? validateScheduleData({
    required String title,
    String? cattleTag,
    String? veterinarian,
    String? notes,
  }) {
    if (title.trim().isEmpty) {
      return 'Title is required';
    }
    if (title.length > 150) {
      return 'Title cannot exceed 150 characters';
    }
    if (cattleTag != null && cattleTag.length > 20) {
      return 'Cattle tag cannot exceed 20 characters';
    }
    if (veterinarian != null && veterinarian.length > 100) {
      return 'Veterinarian name cannot exceed 100 characters';
    }
    if (notes != null && notes.length > 500) {
      return 'Notes cannot exceed 500 characters';
    }
    return null;
  }
}

enum AttentionLevel { urgent, soon, upcoming, normal }

// Extensions for better usability
extension ScheduleExtension on Schedule {
  String get formattedDateTime => ScheduleUtils.formatDateTime(scheduleDateTime);
  String get formattedDetailDateTime => ScheduleUtils.formatDetailDateTime(scheduleDateTime);
  Color get priorityColor => ScheduleUtils.getPriorityColor(priority);
  Color get statusColor => ScheduleUtils.getStatusColor(status);
  IconData get typeIcon => ScheduleUtils.getTypeIcon(type);
  bool get needsAttention => ScheduleUtils.needsAttention(this);
  AttentionLevel get attentionLevel => ScheduleUtils.getAttentionLevel(this);

  bool get isHighPriority => priority == SchedulePriority.high;
  bool get isMediumPriority => priority == SchedulePriority.medium;
  bool get isLowPriority => priority == SchedulePriority.low;
}

// Constants for better maintainability
class ScheduleConstants {
  static const Duration defaultUpcomingDuration = Duration(days: 7);
  static const Duration soonDuration = Duration(days: 1);
  static const Duration urgentDuration = Duration(hours: 24);

  static const int maxTitleLength = 150;
  static const int maxCattleTagLength = 20;
  static const int maxVeterinarianLength = 100;
  static const int maxNotesLength = 500;
}

// Filter options for the schedule screen
enum ScheduleFilter {
  all,
  upcoming,
  overdue,
  completed,
  cancelled,
  highPriority,
  mediumPriority,
  lowPriority,
}

extension ScheduleFilterExtension on ScheduleFilter {
  String get displayName {
    switch (this) {
      case ScheduleFilter.all:
        return 'All';
      case ScheduleFilter.upcoming:
        return 'Upcoming';
      case ScheduleFilter.overdue:
        return 'Overdue';
      case ScheduleFilter.completed:
        return 'Completed';
      case ScheduleFilter.cancelled:
        return 'Cancelled';
      case ScheduleFilter.highPriority:
        return 'High Priority';
      case ScheduleFilter.mediumPriority:
        return 'Medium Priority';
      case ScheduleFilter.lowPriority:
        return 'Low Priority';
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleFilter.all:
        return Icons.list;
      case ScheduleFilter.upcoming:
        return Icons.upcoming;
      case ScheduleFilter.overdue:
        return Icons.warning;
      case ScheduleFilter.completed:
        return Icons.check_circle;
      case ScheduleFilter.cancelled:
        return Icons.cancel;
      case ScheduleFilter.highPriority:
        return Icons.priority_high;
      case ScheduleFilter.mediumPriority:
        return Icons.remove;
      case ScheduleFilter.lowPriority:
        return Icons.keyboard_arrow_down;
    }
  }

  bool matches(Schedule schedule) {
    switch (this) {
      case ScheduleFilter.all:
        return true;
      case ScheduleFilter.upcoming:
        return schedule.isUpcoming();
      case ScheduleFilter.overdue:
        return schedule.isOverdue;
      case ScheduleFilter.completed:
        return schedule.status.toLowerCase() == 'completed';
      case ScheduleFilter.cancelled:
        return schedule.status.toLowerCase() == 'cancelled';
      case ScheduleFilter.highPriority:
        return schedule.isHighPriority;
      case ScheduleFilter.mediumPriority:
        return schedule.isMediumPriority;
      case ScheduleFilter.lowPriority:
        return schedule.isLowPriority;
    }
  }
}

// Sort options for schedules
enum ScheduleSort {
  dateTimeAsc,
  dateTimeDesc,
  titleAsc,
  titleDesc,
  priorityAsc,
  priorityDesc,
  statusAsc,
  statusDesc,
}

extension ScheduleSortExtension on ScheduleSort {
  String get displayName {
    switch (this) {
      case ScheduleSort.dateTimeAsc:
        return 'Date (Earliest First)';
      case ScheduleSort.dateTimeDesc:
        return 'Date (Latest First)';
      case ScheduleSort.titleAsc:
        return 'Title (A-Z)';
      case ScheduleSort.titleDesc:
        return 'Title (Z-A)';
      case ScheduleSort.priorityAsc:
        return 'Priority (Low to High)';
      case ScheduleSort.priorityDesc:
        return 'Priority (High to Low)';
      case ScheduleSort.statusAsc:
        return 'Status (A-Z)';
      case ScheduleSort.statusDesc:
        return 'Status (Z-A)';
    }
  }

  List<Schedule> sort(List<Schedule> schedules) {
    final sorted = List<Schedule>.from(schedules);
    switch (this) {
      case ScheduleSort.dateTimeAsc:
        sorted.sort((a, b) => a.scheduleDateTime.compareTo(b.scheduleDateTime));
        break;
      case ScheduleSort.dateTimeDesc:
        sorted.sort((a, b) => b.scheduleDateTime.compareTo(a.scheduleDateTime));
        break;
      case ScheduleSort.titleAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ScheduleSort.titleDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
        break;
      case ScheduleSort.priorityAsc:
        sorted.sort((a, b) => _priorityValue(a.priority).compareTo(_priorityValue(b.priority)));
        break;
      case ScheduleSort.priorityDesc:
        sorted.sort((a, b) => _priorityValue(b.priority).compareTo(_priorityValue(a.priority)));
        break;
      case ScheduleSort.statusAsc:
        sorted.sort((a, b) => a.status.compareTo(b.status));
        break;
      case ScheduleSort.statusDesc:
        sorted.sort((a, b) => b.status.compareTo(a.status));
        break;
    }
    return sorted;
  }

  int _priorityValue(String priority) {
    switch (priority) {
      case SchedulePriority.low:
        return 1;
      case SchedulePriority.medium:
        return 2;
      case SchedulePriority.high:
        return 3;
      default:
        return 0;
    }
  }
}

// Notification helpers
class ScheduleNotifications {
  static String getNotificationTitle(Schedule schedule) {
    if (schedule.isOverdue) {
      return 'Overdue: ${schedule.title}';
    } else if (schedule.isUpcoming(days: 1)) {
      return 'Due Tomorrow: ${schedule.title}';
    } else if (schedule.isUpcoming(days: 7)) {
      return 'Upcoming: ${schedule.title}';
    }
    return schedule.title;
  }

  static String getNotificationBody(Schedule schedule) {
    final timeInfo = schedule.formattedDateTime;
    final typeInfo = schedule.type;
    final cattleInfo = schedule.cattleTag != null ? ' for ${schedule.cattleTag}' : '';

    return '$typeInfo$cattleInfo scheduled for $timeInfo';
  }
}

// Statistics helper
class ScheduleStats {
  static Map<String, int> getStatusCounts(List<Schedule> schedules) {
    return {
      'scheduled': schedules.where((s) => s.status.toLowerCase() == 'scheduled').length,
      'completed': schedules.where((s) => s.status.toLowerCase() == 'completed').length,
      'cancelled': schedules.where((s) => s.status.toLowerCase() == 'cancelled').length,
      'overdue': schedules.where((s) => s.isOverdue).length,
      'upcoming': schedules.where((s) => s.isUpcoming()).length,
    };
  }

  static Map<String, int> getTypeCounts(List<Schedule> schedules) {
    final counts = <String, int>{};
    for (final schedule in schedules) {
      counts[schedule.type] = (counts[schedule.type] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> getPriorityCounts(List<Schedule> schedules) {
    return {
      'High': schedules.where((s) => s.isHighPriority).length,
      'Medium': schedules.where((s) => s.isMediumPriority).length,
      'Low': schedules.where((s) => s.isLowPriority).length,
    };
  }
}

// Error handling
class ScheduleError {
  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return 'An unexpected error occurred';
  }

  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }
}

// Custom widgets for the schedule screen
class SchedulePriorityChip extends StatelessWidget {
  final String priority;
  final bool isSmall;

  const SchedulePriorityChip({
    super.key,
    required this.priority,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ScheduleUtils.getPriorityColor(priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ScheduleStatusChip extends StatelessWidget {
  final String status;
  final bool isSmall;

  const ScheduleStatusChip({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ScheduleUtils.getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ScheduleTypeIcon extends StatelessWidget {
  final String type;
  final double size;
  final Color? color;

  const ScheduleTypeIcon({
    super.key,
    required this.type,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FaIcon(
        ScheduleUtils.getTypeIcon(type),
        size: size,
        color: color ?? AppColors.primary,
      ),
    );
  }
}