import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';

class CattleEventService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getCattleEvent() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/event'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load cattle. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getCattleEvent: $e', stackTrace: stackTrace);
    }

    return [];
  }

  static Future<bool> storeCattleEvent(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles/event');
    log('Attempting to POST to $uri'); // Debugging log

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        log('Cattle created successfully.');
        return true;
      } else {
        log('Failed to create Cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeCattleEvent: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateCattleEvent(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles/event');
    log('Attempting to PUT to $uri'); // Debugging log

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // FIX: Corrected log message for clarity.
        log('Cattle updated successfully.');
        return true;
      } else {
        log('Failed to update Cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateCattleEvent: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> deleteCattleEvent(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles/event');
    log('Attempting to DELETE from $uri with id=$id'); // Debug log

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        log('Cattle deleted successfully.');
        return true;
      } else {
        log('Failed to delete Cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deleteTrainingsAndSeminars: $e', stackTrace: stackTrace);
      return false;
    }
  }
}