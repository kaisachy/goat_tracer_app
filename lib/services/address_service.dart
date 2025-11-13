import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AddressService {
  static final String _baseUrl = AppConfig.baseUrl;

  // Get Isabela municipalities from backend API
  static Future<List<dynamic>> getIsabelaMunicipalities() async {
    try {
      debugPrint('Getting Isabela municipalities from backend API...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/isabela-municipalities'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Municipalities response status: ${response.statusCode}');
      debugPrint('Municipalities response body: ${response.body}');

      if (response.statusCode == 200) {
        final municipalities = jsonDecode(response.body) as List<dynamic>;
        debugPrint('Success! Found ${municipalities.length} municipalities in Isabela');
        return municipalities;
      } else {
        debugPrint('Failed to get municipalities: ${response.body}');
        throw Exception('Failed to fetch municipalities from backend API');
      }
    } catch (e) {
      debugPrint('Backend API approach failed: $e');
      throw Exception('Failed to load Isabela municipalities: $e');
    }
  }

  // Get barangays from backend API
  static Future<List<dynamic>> getBarangays(String municipalityCode) async {
    try {
      debugPrint('Getting barangays for municipality: $municipalityCode');
      
      // Try path parameter first (preferred), fallback to query parameter
      Uri uri = Uri.parse('$_baseUrl/api/address/barangays/$municipalityCode');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Barangay response status: ${response.statusCode}');
      debugPrint('Barangay response body: ${response.body}');

      if (response.statusCode == 200) {
        final barangays = jsonDecode(response.body) as List<dynamic>;
        debugPrint('Found ${barangays.length} barangays');
        return barangays;
      } else {
        debugPrint('Failed to get barangays: ${response.body}');
        throw Exception('Failed to load barangays');
      }
    } catch (e) {
      debugPrint('Error getting barangays: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get regions from backend API
  static Future<List<dynamic>> getRegions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/regions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load regions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get provinces from backend API
  static Future<List<dynamic>> getProvinces(String regionCode) async {
    try {
      debugPrint('Getting provinces for region code: $regionCode');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/provinces/$regionCode'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Provinces response status: ${response.statusCode}');
      debugPrint('Provinces response body: ${response.body}');

      if (response.statusCode == 200) {
        final provinces = jsonDecode(response.body) as List<dynamic>;
        debugPrint('Success! Found ${provinces.length} provinces');
        return provinces;
      } else {
        debugPrint('Failed to get provinces: ${response.body}');
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      debugPrint('Error getting provinces: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get municipalities from backend API
  static Future<List<dynamic>> getMunicipalities(String provinceCode) async {
    try {
      debugPrint('Getting municipalities for province code: $provinceCode');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/municipalities/$provinceCode'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Municipalities response status: ${response.statusCode}');
      debugPrint('Municipalities response body: ${response.body}');

      if (response.statusCode == 200) {
        final municipalities = jsonDecode(response.body) as List<dynamic>;
        debugPrint('Success! Found ${municipalities.length} municipalities');
        return municipalities;
      } else {
        debugPrint('Failed to get municipalities: ${response.body}');
        throw Exception('Failed to load municipalities');
      }
    } catch (e) {
      debugPrint('Error getting municipalities: $e');
      throw Exception('Network error: $e');
    }
  }
}