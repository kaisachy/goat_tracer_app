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
      log('getCattleEvent: No token found');
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

      log('getCattleEvent Response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load cattle events. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
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
    final requestBody = jsonEncode(data);

    log('=== STORE CATTLE EVENT DEBUG ===');
    log('URI: $uri');
    log('Request Body: $requestBody');
    log('Data being sent: $data');
    log('Token exists: ${token.isNotEmpty}');
    log('Token preview: ${token.substring(0, 20)}...');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      log('Response Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');
      log('Response Headers: ${response.headers}');

      if (response.statusCode == 201) {
        log('Cattle event created successfully.');
        return true;
      } else if (response.statusCode == 200) {
        // Some APIs return 200 instead of 201 for successful creation
        log('Cattle event created successfully (status 200).');

        // Try to parse response to check for success indicators
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true || responseData['status'] == 'success') {
            return true;
          }
        } catch (parseError) {
          log('Could not parse response body as JSON: $parseError');
        }

        return true; // Assume success for 200 status
      } else {
        log('Failed to create cattle event. Status: ${response.statusCode}');
        log('Error response body: ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            log('Server error message: ${errorData['message']}');
          }
          if (errorData['errors'] != null) {
            log('Server validation errors: ${errorData['errors']}');
          }
        } catch (parseError) {
          log('Could not parse error response as JSON: $parseError');
        }

        return false;
      }
    } catch (e, stackTrace) {
      log('Exception in storeCattleEvent: $e');
      log('Stack trace: $stackTrace');
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
    final requestBody = jsonEncode(data);

    log('=== UPDATE CATTLE EVENT DEBUG ===');
    log('URI: $uri');
    log('Request Body: $requestBody');
    log('Data being sent: $data');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      log('Update Response Status Code: ${response.statusCode}');
      log('Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        log('Cattle event updated successfully.');
        return true;
      } else {
        log('Failed to update cattle event. Status: ${response.statusCode}');
        log('Error response body: ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            log('Server error message: ${errorData['message']}');
          }
        } catch (parseError) {
          log('Could not parse error response as JSON: $parseError');
        }

        return false;
      }
    } catch (e, stackTrace) {
      log('Exception in updateCattleEvent: $e');
      log('Stack trace: $stackTrace');
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
    final requestBody = jsonEncode({'id': id});

    log('=== DELETE CATTLE EVENT DEBUG ===');
    log('URI: $uri');
    log('Request Body: $requestBody');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      log('Delete Response Status Code: ${response.statusCode}');
      log('Delete Response Body: ${response.body}');

      if (response.statusCode == 200) {
        log('Cattle event deleted successfully.');
        return true;
      } else {
        log('Failed to delete cattle event. Status: ${response.statusCode}');
        log('Error response body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Exception in deleteCattleEvent: $e');
      log('Stack trace: $stackTrace');
      return false;
    }
  }
}