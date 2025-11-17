import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../models/schedule.dart';
import '../auth_service.dart';

class SchedulerService {
  static final String _baseUrl = AppConfig.baseUrl;
  static const int _timeoutDuration = 30; // seconds

  // Get all schedules for the farmer (view-only)
  static Future<List<Schedule>> getAllSchedules() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Clean token: remove newlines and carriage returns
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();
      final authHeader = 'Bearer $cleanedToken';

      final response = await http.get(
        Uri.parse('$_baseUrl/goats/schedule'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      ).timeout(const Duration(seconds: _timeoutDuration));

      log('getAllSchedules: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('getAllSchedules: Response data keys: ${data.keys.toList()}');
        
        if (data['data'] != null) {
          final List<dynamic> schedulesJson = data['data'];
          log('getAllSchedules: Found ${schedulesJson.length} schedules');
          
          // Handle empty array case (valid response)
          if (schedulesJson.isEmpty) {
            log('getAllSchedules: No schedules found (empty array)');
            return [];
          }
          
          final schedules = schedulesJson.map((json) => Schedule.fromJson(json)).toList();
          log('getAllSchedules: Successfully parsed ${schedules.length} schedules');
          return schedules;
        } else {
          log('getAllSchedules: No data field in response. Response: ${response.body}');
          throw Exception(data['message'] ?? 'Failed to fetch schedules');
        }
      } else if (response.statusCode == 401) {
        log('getAllSchedules: Authentication failed (401). Response: ${response.body}');
        throw Exception('Authentication failed. Please login again.');
      } else {
        log('getAllSchedules: Failed with status ${response.statusCode}. Response: ${response.body}');
        throw Exception('Failed to fetch schedules: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('getAllSchedules: Exception occurred: $e', stackTrace: stackTrace);
      // Return empty list instead of throwing exception to allow calendar to show
      // This matches the web version behavior where calendar is always visible
      return [];
    }
  }

  // Get schedules by date range
  static Future<List<Schedule>> getSchedulesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Clean token: remove newlines and carriage returns
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();
      final authHeader = 'Bearer $cleanedToken';

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await http.get(
        Uri.parse('$_baseUrl/goats/schedule?start_date=$startDateStr&end_date=$endDateStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      ).timeout(const Duration(seconds: _timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> schedulesJson = data['data'];
          return schedulesJson.map((json) => Schedule.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch schedules');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching schedules: $e');
    }
  }

  // Get upcoming schedules
  static Future<List<Schedule>> getUpcomingSchedules({int days = 7}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Clean token: remove newlines and carriage returns
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();
      final authHeader = 'Bearer $cleanedToken';

      final response = await http.get(
        Uri.parse('$_baseUrl/goats/schedule?upcoming=$days'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      ).timeout(const Duration(seconds: _timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> schedulesJson = data['data'];
          return schedulesJson.map((json) => Schedule.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch upcoming schedules');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch upcoming schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching upcoming schedules: $e');
    }
  }

  // Get today's schedules
  static Future<List<Schedule>> getTodaySchedules() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getSchedulesByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Get schedules by status
  static Future<List<Schedule>> getSchedulesByStatus(String status) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Clean token: remove newlines and carriage returns
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();
      final authHeader = 'Bearer $cleanedToken';

      final response = await http.get(
        Uri.parse('$_baseUrl/goats/schedule?status=$status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      ).timeout(const Duration(seconds: _timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> schedulesJson = data['data'];
          return schedulesJson.map((json) => Schedule.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch schedules');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching schedules: $e');
    }
  }

  // Get overdue schedules
  static Future<List<Schedule>> getOverdueSchedules() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Clean token: remove newlines and carriage returns
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();
      final authHeader = 'Bearer $cleanedToken';

      final response = await http.get(
        Uri.parse('$_baseUrl/goats/schedule?overdue=1'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      ).timeout(const Duration(seconds: _timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> schedulesJson = data['data'];
          return schedulesJson.map((json) => Schedule.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch overdue schedules');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch overdue schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching overdue schedules: $e');
    }
  }
}
