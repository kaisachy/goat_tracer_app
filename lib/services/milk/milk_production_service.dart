import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';
import '../../models/milk.dart';

class MilkProductionService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<List<MilkProduction>> getMilkProductions() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/milk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => MilkProduction.fromJson(json))
            .toList();
      } else {
        log('Failed to load milk productions. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getMilkProductions: $e', stackTrace: stackTrace);
    }
    return [];
  }

  /// Create a new milk production record
  static Future<bool> storeMilkProduction(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cattles/milk'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        log('Milk production record created successfully.');
        return true;
      } else {
        log('Failed to create milk production record. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in storeMilkProduction: $e', stackTrace: stackTrace);
    }
    return false;
  }

  /// Update an existing milk production record
  static Future<bool> updateMilkProduction(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/cattles/milk'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        log('Milk production record updated successfully.');
        return true;
      } else {
        log('Failed to update milk production record. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in updateMilkProduction: $e', stackTrace: stackTrace);
    }
    return false;
  }

  /// Delete a milk production record
  static Future<bool> deleteMilkProduction(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/cattles/milk'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        log('Milk production record deleted successfully.');
        return true;
      } else {
        log('Failed to delete milk production record. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in deleteMilkProduction: $e', stackTrace: stackTrace);
    }
    return false;
  }
}
