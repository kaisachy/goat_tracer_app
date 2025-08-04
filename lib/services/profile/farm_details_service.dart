import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';

class FarmDetailsService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<Map<String, dynamic>?> getFarmDetails() async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getFarmDetails: No token found.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/farm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getFarmDetails: Response Status Code: ${response.statusCode}');
      log('getFarmDetails: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);

        // FIX: Check if the 'data' key exists and is a Map
        if (decodedData.containsKey('data') && decodedData['data'] is Map) {
          final farmData = decodedData['data'] as Map<String, dynamic>;
          log('getFarmDetails: Successfully extracted farm data: $farmData');
          return farmData;
        } else {
          log('getFarmDetails: Response body does not contain a valid "data" key.');
          return null; // Return null if the data key is missing or not a map
        }
      } else {
        log('getFarmDetails: Failed to load farm details. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getFarmDetails: $e', stackTrace: stackTrace);
    }

    return null;
  }

  static Future<bool> storeFarmDetails(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      // Use http.post to call your store/create endpoint
      final response = await http.post(
        Uri.parse('$_baseUrl/farmer/farm'), // Assuming this is your POST route
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // Your backend returns status 201 (Created) on success
      if (response.statusCode == 201) {
        log('Farm details created successfully.');
        return true;
      } else {
        log('Failed to create farm details. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeFarmDetails: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateFarmDetails(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      // Use http.post to call your store/create endpoint
      final response = await http.put(
        Uri.parse('$_baseUrl/farmer/farm'), // Assuming this is your POST route
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // Your backend returns status 201 (Created) on success
      if (response.statusCode == 200) {
        log('Farm details updated successfully.');
        return true;
      } else {
        log('Failed to update farm details. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateFarmDetails: $e', stackTrace: stackTrace);
      return false;
    }
  }
}