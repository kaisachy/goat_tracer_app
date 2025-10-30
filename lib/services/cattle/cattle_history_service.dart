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
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/history'),
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
      log('Error in getCattleHistory: $e');
    }

    return [];
  }

  static Future<bool> storeCattleHistory(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles/history');
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
      log('Exception in storeCattleHistory: $e');
      return false;
    }
  }

  static Future<bool> updateCattleHistory(Map<String, dynamic> data) async {
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
      final deleteSuccess = await deleteCattleHistory(historyId);
      if (!deleteSuccess) {
        return false;
      }

      // Remove the ID from the data since we're creating a new history record
      final newHistoryData = Map<String, dynamic>.from(data);
      newHistoryData.remove('id');

      // Create a new history record with the updated data
      final createSuccess = await storeCattleHistory(newHistoryData);
      return createSuccess;
    } catch (e) {
      log('Exception in updateCattleHistory: $e');
      return false;
    }
  }

  static Future<bool> deleteCattleHistory(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles/history');
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

  /// Get cattle history records by cattle tag
  static Future<List<Map<String, dynamic>>> getCattleHistoryByTag(String cattleTag) async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/history?cattle_tag=$cattleTag'),
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
      log('Error in getCattleHistoryByTag: $e');
    }

    return [];
  }
}