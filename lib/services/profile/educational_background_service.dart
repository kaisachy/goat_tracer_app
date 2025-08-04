import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';

class EducationalBackgroundService {
  static final String _baseUrl = AppConfig.baseUrl;

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

  static Future<bool> storeEducationalBackground(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/farmer/education'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        log('Educational background created successfully.');
        return true;
      } else {
        log('Failed to create educational background. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeEducationalBackground: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateEducationalBackground(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/farmer/education'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        log('Educational background updated successfully.');
        return true;
      } else {
        log('Failed to update educational background. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateEducationalBackground: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> deleteEducationalBackground(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/farmer/education'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        log('Educational background deleted successfully.');
        return true;
      } else {
        log('Failed to delete educational background. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deleteEducationalBackground: $e', stackTrace: stackTrace);
      return false;
    }
  }
}