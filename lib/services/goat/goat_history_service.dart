import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';

class GoatHistoryService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getgoatHistory() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goats/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      log('Error in getgoatHistory: $e');
    }

    return [];
  }

  static Future<bool> storegoatHistory(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return false;
    }

    final uri = Uri.parse('$_baseUrl/goats/history');
    final requestBody = jsonEncode(data);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 200) {
        // Some APIs return 200 instead of 201 for successful creation
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true || responseData['status'] == 'success') {
            return true;
          }
        } catch (parseError) {
          // Ignore parse error
        }
        return true; // Assume success for 200 status
      } else {
        return false;
      }
    } catch (e) {
      log('Exception in storegoatHistory: $e');
      return false;
    }
  }

  static Future<bool> updategoatHistory(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return false;
    }

    // Extract the history record ID from the data
    final historyId = data['id'];
    if (historyId == null) {
      return false;
    }

    try {
      // First, delete the existing history record
      final deleteSuccess = await deletegoatHistory(historyId);
      if (!deleteSuccess) {
        return false;
      }

      // Remove the ID from the data since we're creating a new history record
      final newHistoryData = Map<String, dynamic>.from(data);
      newHistoryData.remove('id');

      // Create a new history record with the updated data
      final createSuccess = await storegoatHistory(newHistoryData);
      return createSuccess;
    } catch (e) {
      log('Exception in updategoatHistory: $e');
      return false;
    }
  }

  static Future<bool> deletegoatHistory(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return false;
    }

    final uri = Uri.parse('$_baseUrl/goats/history');
    final requestBody = jsonEncode({'id': id});

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get Goat History records by Goat Tag
  static Future<List<Map<String, dynamic>>> getgoatHistoryByTag(String goatTag) async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goats/history?goat_tag=$goatTag'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      log('Error in getgoatHistoryByTag: $e');
    }

    return [];
  }
}