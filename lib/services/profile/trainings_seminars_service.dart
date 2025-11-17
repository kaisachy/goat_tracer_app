import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';

class TrainingsSeminarsService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getTrainingsAndSeminars() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      // Clean token: trim and remove only newlines and carriage returns (not spaces)
      // JWT tokens are base64url encoded and should not have newlines
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();
      
      final authHeader = 'Bearer $cleanedToken';
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/trainings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load trainings and seminars. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getTrainingsAndSeminars: $e', stackTrace: stackTrace);
    }

    return [];
  }

  static Future<bool> storeTrainingsAndSeminars(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/farmer/trainings');
    log('Attempting to POST to $uri'); // Debugging log

    try {
      final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        log('Training & Seminar created successfully.');
        return true;
      } else {
        log('Failed to create Training & Seminar. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeTrainingsAndSeminars: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateTrainingsAndSeminars(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/farmer/trainings');
    log('Attempting to PUT to $uri'); // Debugging log

    try {
      final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // FIX: Corrected log message for clarity.
        log('Training & Seminar updated successfully.');
        return true;
      } else {
        log('Failed to update Training & Seminar. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateTrainingsAndSeminars: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> deleteTrainingsAndSeminars(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/farmer/trainings');
    log('Attempting to DELETE from $uri with id=$id'); // Debug log

    try {
      final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        log('Training & Seminar deleted successfully.');
        return true;
      } else {
        log('Failed to delete Training & Seminar. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deleteTrainingsAndSeminars: $e', stackTrace: stackTrace);
      return false;
    }
  }
}