// enhanced_schedule_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../models/schedule.dart';
import '../auth_service.dart';

class ScheduleService {
  static final String _baseUrl = AppConfig.baseUrl;
  static const int _timeoutDuration = 30; // seconds

  // Enhanced error handling wrapper
  static Future<T> _handleRequest<T>(
      Future<T> Function() request,
      String operation,
      ) async {
    try {
      return await request().timeout(
        Duration(seconds: _timeoutDuration),
        onTimeout: () {
          throw Exception('Request timeout: $operation took too long');
        },
      );
    } catch (e) {
      log('Error in $operation: $e');
      rethrow;
    }
  }

  // Get all schedules with comprehensive filtering
  static Future<List<Schedule>> getSchedules({
    String? status,
    String? type,
    String? goatTag,
    int? upcomingDays,
    bool overdue = false,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      String endpoint = '$_baseUrl/goats/schedule';
      List<String> queryParams = [];

      // Add query parameters
      if (status != null) queryParams.add('status=${Uri.encodeComponent(status)}');
      if (type != null) queryParams.add('type=${Uri.encodeComponent(type)}');
      if (goatTag != null) {
        // Normalize the Goat Tag before sending
        final normalizedTag = goatTag.trim().toUpperCase();
        queryParams.add('goat_tag=${Uri.encodeComponent(normalizedTag)}');
      }
      if (upcomingDays != null) queryParams.add('upcoming=$upcomingDays');
      if (overdue) queryParams.add('overdue=1');
      if (startDate != null) queryParams.add('start_date=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('end_date=${endDate.toIso8601String()}');
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      log('Fetching schedules from: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // Handle different response formats
          List<dynamic> schedulesData;
          if (data is List) {
            schedulesData = data;
          } else if (data is Map && data.containsKey('data')) {
            if (data['data'] is List) {
              schedulesData = data['data'];
            } else {
              throw Exception('Invalid response format: data is not a list');
            }
          } else if (data is Map && data.containsKey('schedules')) {
            schedulesData = data['schedules'];
          } else {
            throw Exception('Invalid response format: ${data.runtimeType}');
          }

          return schedulesData
              .map((json) => Schedule.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        } catch (e) {
          log('Error parsing response: $e');
          throw Exception('Failed to parse schedule data: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error occurred');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to load schedules: ${response.statusCode} - $errorBody');
      }
    }, 'getSchedules');
  }

  // Get schedules for specific goat - IMPROVED VERSION
  static Future<List<Schedule>> getSchedulesForgoat(String goatTag) async {
    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Normalize the Goat Tag to match database format (uppercase, trimmed)
      final normalizedTag = goatTag.trim().toUpperCase();

      if (normalizedTag.isEmpty) {
        log('Empty Goat Tag provided, returning empty list');
        return [];
      }

      String endpoint = '$_baseUrl/goats/schedule?goat_tag=${Uri.encodeComponent(normalizedTag)}';

      log('Fetching schedules for Goat Tag: "$normalizedTag"');
      log('Request URL: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // Handle different response formats
          List<dynamic> schedulesData;
          if (data is List) {
            schedulesData = data;
          } else if (data is Map && data.containsKey('data')) {
            if (data['data'] is List) {
              schedulesData = data['data'];
            } else {
              throw Exception('Invalid response format: data is not a list');
            }
          } else if (data is Map && data.containsKey('schedules')) {
            schedulesData = data['schedules'];
          } else {
            throw Exception('Invalid response format: ${data.runtimeType}');
          }

          final schedules = schedulesData
              .map((json) => Schedule.fromJson(Map<String, dynamic>.from(json)))
              .toList();

          log('Successfully parsed ${schedules.length} schedules');

          // Additional client-side filtering to ensure accuracy
          final filteredSchedules = schedules.where((schedule) {
            return scheduleContainsgoatTag(schedule, normalizedTag);
          }).toList();

          log('After client-side filtering: ${filteredSchedules.length} schedules');

          // Additional logging for debugging
          for (var schedule in filteredSchedules) {
            log('Found schedule: ${schedule.title}, goatTags: "${schedule.goatTag}", ID: ${schedule.id}');
          }

          return filteredSchedules;
        } catch (e) {
          log('Error parsing response: $e');
          throw Exception('Failed to parse schedule data: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error occurred');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to load schedules: ${response.statusCode} - $errorBody');
      }
    }, 'getSchedulesForgoat');
  }

  // IMPROVED: Client-side method to check if a schedule contains a specific Goat Tag
  static bool scheduleContainsgoatTag(Schedule schedule, String goatTag) {
    if (schedule.goatTag == null || schedule.goatTag!.isEmpty) {
      return false;
    }

    // Normalize both the schedule tags and the search tag
    final normalizedSearchTag = goatTag.trim().toUpperCase();

    // Split comma-separated tags and normalize each one
    final schedulegoatTags = schedule.goatTag!
        .split(',')
        .map((tag) => tag.trim().toUpperCase())
        .where((tag) => tag.isNotEmpty)
        .toList();

    log('Checking if "$normalizedSearchTag" is in [${schedulegoatTags.join(', ')}]');

    // Check for exact match
    final found = schedulegoatTags.any((tag) => tag == normalizedSearchTag);

    if (found) {
      log('Match found!');
    }

    return found;
  }

  // IMPROVED: Method to get all Goat Tags from a schedule
  static List<String> getgoatTagsFromSchedule(Schedule schedule) {
    if (schedule.goatTag == null || schedule.goatTag!.isEmpty) {
      return [];
    }

    return schedule.goatTag!
        .split(',')
        .map((tag) => tag.trim().toUpperCase())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  // Get schedules for multiple Goat Tags
  static Future<List<Schedule>> getSchedulesForMultiplegoat(List<String> goatTags) async {
    if (goatTags.isEmpty) return [];

    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Normalize all Goat Tags
      final normalizedTags = goatTags
          .map((tag) => tag.trim().toUpperCase())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (normalizedTags.isEmpty) {
        return [];
      }

      // Get all schedules and filter client-side for multiple tags
      // This approach is more reliable than complex server-side queries
      final allSchedules = await getSchedules();

      final filteredSchedules = allSchedules.where((schedule) {
        // Check if any of the requested Goat Tags match any in the schedule
        return normalizedTags.any((requestedTag) =>
            scheduleContainsgoatTag(schedule, requestedTag));
      }).toList();

      log('Found ${filteredSchedules.length} schedules for Goat Tags: ${normalizedTags.join(', ')}');
      return filteredSchedules;
    }, 'getSchedulesForMultiplegoat');
  }

  // Create schedule with validation - IMPROVED
  static Future<Schedule> createSchedule(Schedule schedule) async {
    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Validate schedule data
      if (schedule.title.trim().isEmpty) {
        throw Exception('Title is required');
      }

      // Normalize Goat Tag before sending
      Schedule normalizedSchedule = schedule;
      if (schedule.goatTag != null && schedule.goatTag!.isNotEmpty) {
        final tags = schedule.goatTag!
            .split(',')
            .map((tag) => tag.trim().toUpperCase())
            .where((tag) => tag.isNotEmpty)
            .toList();
        normalizedSchedule = schedule.copyWith(goatTag: tags.join(','));
      }

      final uri = Uri.parse('$_baseUrl/goats/schedule');
      final requestBody = normalizedSchedule.toApiJson();

      log('Creating schedule with URL: $uri');
      log('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      log('Create response status: ${response.statusCode}');
      log('Create response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // Handle different response formats
          if (data is Map && data.containsKey('data')) {
            return Schedule.fromJson(Map<String, dynamic>.from(data['data']));
          } else if (data is Map && data.containsKey('schedule')) {
            return Schedule.fromJson(Map<String, dynamic>.from(data['schedule']));
          } else if (data is Map) {
            // Assume the entire response is the schedule data
            return Schedule.fromJson(Map<String, dynamic>.from(data));
          } else {
            // If no data returned, return the original schedule with current timestamp as ID
            return normalizedSchedule.copyWith(
              id: DateTime.now().millisecondsSinceEpoch,
              createdAt: DateTime.now(),
            );
          }
        } catch (e) {
          log('Error parsing create response: $e');
          // Return the schedule with a temporary ID if parsing fails
          return normalizedSchedule.copyWith(
            id: DateTime.now().millisecondsSinceEpoch,
            createdAt: DateTime.now(),
          );
        }
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Invalid schedule data');
        } catch (e) {
          throw Exception('Invalid schedule data: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to create schedule: ${response.statusCode} - $errorBody');
      }
    }, 'createSchedule');
  }

  // All other methods remain the same...
  // (I'll include the essential ones for completeness)

  static Future<Schedule?> getScheduleById(int id) async {
    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/goats/schedule/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Schedule.fromJson(data['data'] ?? data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    }, 'getScheduleById');
  }

  // Update schedule with validation - IMPROVED
  static Future<Schedule> updateSchedule(Schedule schedule) async {
    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      if (schedule.id == null) {
        throw Exception('Schedule ID is required for update');
      }

      // Validate schedule data
      if (schedule.title.trim().isEmpty) {
        throw Exception('Title is required');
      }

      // Normalize Goat Tag before sending
      Schedule normalizedSchedule = schedule;
      if (schedule.goatTag != null && schedule.goatTag!.isNotEmpty) {
        final tags = schedule.goatTag!
            .split(',')
            .map((tag) => tag.trim().toUpperCase())
            .where((tag) => tag.isNotEmpty)
            .toList();
        normalizedSchedule = schedule.copyWith(goatTag: tags.join(','));
      }

      final uri = Uri.parse('$_baseUrl/goats/schedule/${schedule.id}');
      final requestBody = normalizedSchedule.toApiJson();

      log('Updating schedule with URL: $uri');
      log('Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      log('Update response status: ${response.statusCode}');
      log('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Handle different response formats
          if (data is Map && data.containsKey('data')) {
            return Schedule.fromJson(Map<String, dynamic>.from(data['data']));
          } else if (data is Map && data.containsKey('schedule')) {
            return Schedule.fromJson(Map<String, dynamic>.from(data['schedule']));
          } else {
            // Return the updated schedule with current timestamp
            return normalizedSchedule.copyWith(updatedAt: DateTime.now());
          }
        } catch (e) {
          log('Error parsing update response: $e');
          return normalizedSchedule.copyWith(updatedAt: DateTime.now());
        }
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Invalid schedule data');
        } catch (e) {
          throw Exception('Invalid schedule data: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else if (response.statusCode == 404) {
        throw Exception('Schedule not found');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to update schedule: ${response.statusCode} - $errorBody');
      }
    }, 'updateSchedule');
  }

  // Convenience methods...
  static Future<List<Schedule>> getUpcomingSchedules({int days = 7}) async {
    return await getSchedules(upcomingDays: days);
  }

  static Future<List<Schedule>> getOverdueSchedules() async {
    return await getSchedules(overdue: true);
  }

  static Future<List<Schedule>> getSchedulesByStatus(String status) async {
    return await getSchedules(status: status);
  }

  static Future<List<Schedule>> getScheduledSchedules() async {
    return await getSchedulesByStatus(ScheduleStatus.scheduled);
  }

  static Future<List<Schedule>> getCompletedSchedules() async {
    return await getSchedulesByStatus(ScheduleStatus.completed);
  }

  static Future<List<Schedule>> getCancelledSchedules() async {
    return await getSchedulesByStatus(ScheduleStatus.cancelled);
  }

  static Future<bool> updateScheduleStatus(int id, String status) async {
    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      if (!ScheduleStatus.values.contains(status)) {
        throw Exception('Invalid status value');
      }

      final uri = Uri.parse('$_baseUrl/goats/schedule/$id/status');
      log('Updating schedule status: id=$id, status=$status');

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Invalid status update request');
        } catch (e) {
          throw Exception('Invalid status update request: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else if (response.statusCode == 404) {
        throw Exception('Schedule not found');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to update schedule status: ${response.statusCode} - $errorBody');
      }
    }, 'updateScheduleStatus');
  }

  static Future<Schedule> duplicateSchedule(
      Schedule originalSchedule,
      DateTime newDateTime,
      ) async {
    final duplicatedSchedule = originalSchedule.copyWith(
      id: null,
      scheduleDateTime: newDateTime,
      status: ScheduleStatus.scheduled,
      createdAt: null,
      updatedAt: null,
    );

    return await createSchedule(duplicatedSchedule);
  }

  static Future<bool> deleteSchedule(int id) async {
    return _handleRequest(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$_baseUrl/goats/schedule/$id');
      log('Deleting schedule: id=$id');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else if (response.statusCode == 404) {
        throw Exception('Schedule not found');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to delete schedule: ${response.statusCode} - $errorBody');
      }
    }, 'deleteSchedule');
  }

  static Future<bool> markScheduleAsCompleted(int id) async {
    return await updateScheduleStatus(id, ScheduleStatus.completed);
  }

  static Future<bool> markScheduleAsCancelled(int id) async {
    return await updateScheduleStatus(id, ScheduleStatus.cancelled);
  }

  static Future<bool> reschedule(int id) async {
    return await updateScheduleStatus(id, ScheduleStatus.scheduled);
  }

  // Statistics
  static Future<Map<String, int>> getScheduleStatistics() async {
    try {
      final schedules = await getSchedules();
      return {
        'total': schedules.length,
        'scheduled': schedules.where((s) => s.isScheduled).length,
        'completed': schedules.where((s) => s.isCompleted).length,
        'cancelled': schedules.where((s) => s.isCancelled).length,
        'overdue': schedules.where((s) => s.isOverdue).length,
        'upcoming': schedules.where((s) => s.isUpcoming()).length,
        'with_duration': schedules.where((s) => s.hasDuration).length,
        'with_reminder': schedules.where((s) => s.hasReminder).length,
        'with_scheduled_by': schedules.where((s) => s.hasScheduledBy).length,
      };
    } catch (e) {
      log('Error getting schedule statistics: $e');
      return {};
    }
  }

  // Search schedules
  static Future<List<Schedule>> searchSchedules(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final schedules = await getSchedules();
      return schedules.where((schedule) {
        final searchQuery = query.toLowerCase();
        return schedule.title.toLowerCase().contains(searchQuery) ||
            schedule.type.toLowerCase().contains(searchQuery) ||
            (schedule.goatTag?.toLowerCase().contains(searchQuery) ?? false) ||
            (schedule.scheduledBy?.toLowerCase().contains(searchQuery) ?? false) ||
            (schedule.details?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      log('Error searching schedules: $e');
      return [];
    }
  }
}