import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class ProfileService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<Map<String, dynamic>?> getFarmerProfile() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('Failed to load farmer profile. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getFarmerProfile: $e', stackTrace: stackTrace);
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> getEducationalBackground() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/education'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load educational background. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getEducationalBackground: $e', stackTrace: stackTrace);
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> getTrainingsAndSeminars() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/trainings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
}
