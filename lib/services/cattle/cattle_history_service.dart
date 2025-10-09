import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';

class CattleHistoryService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getCattleHistory() async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getCattleHistory: No token found');
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

      log('getCattleHistory Response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load cattle history. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getCattleHistory: $e', stackTrace: stackTrace);
    }

    return [];
  }

  static Future<bool> storeCattleHistory(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles/event');
    final requestBody = jsonEncode(data);

    log('=== STORE CATTLE HISTORY DEBUG ===');
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
        log('Cattle history record created successfully.');
        return true;
      } else if (response.statusCode == 200) {
        // Some APIs return 200 instead of 201 for successful creation
        log('Cattle history record created successfully (status 200).');

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
        log('Failed to create cattle history record. Status: ${response.statusCode}');
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
      log('Exception in storeCattleHistory: $e');
      log('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> updateCattleHistory(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    // Extract the history record ID from the data
    final historyId = data['id'];
    if (historyId == null) {
      log('Update failed: No history record ID provided.');
      return false;
    }

    try {
      // First, delete the existing history record
      final deleteSuccess = await deleteCattleHistory(historyId);
      if (!deleteSuccess) {
        log('Failed to delete existing history record for update.');
        return false;
      }

      // Remove the ID from the data since we're creating a new history record
      final newHistoryData = Map<String, dynamic>.from(data);
      newHistoryData.remove('id');

      // Create a new history record with the updated data
      final createSuccess = await storeCattleHistory(newHistoryData);
      if (createSuccess) {
        log('Cattle history record updated successfully via delete-and-recreate.');
        return true;
      } else {
        log('Failed to create new history record after deletion.');
        return false;
      }
    } catch (e, stackTrace) {
      log('Exception in updateCattleHistory: $e');
      log('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> deleteCattleHistory(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles/event');
    final requestBody = jsonEncode({'id': id});

    log('=== DELETE CATTLE HISTORY DEBUG ===');
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
        log('Cattle history record deleted successfully.');
        return true;
      } else {
        log('Failed to delete cattle history record. Status: ${response.statusCode}');
        log('Error response body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Exception in deleteCattleHistory: $e');
      log('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get cattle history records by cattle tag
  static Future<List<Map<String, dynamic>>> getCattleHistoryByTag(String cattleTag) async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getCattleHistoryByTag: No token found');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/event?cattle_tag=$cattleTag'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getCattleHistoryByTag Response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load cattle history by tag. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getCattleHistoryByTag: $e', stackTrace: stackTrace);
    }

    return [];
  }
}