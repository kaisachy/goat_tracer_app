import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AddressService {
  static final String _baseUrl = AppConfig.baseUrl;

  // Get Isabela municipalities from backend API
  static Future<List<dynamic>> getIsabelaMunicipalities() async {
    try {
      print('Getting Isabela municipalities from backend API...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/isabela-municipalities'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Municipalities response status: ${response.statusCode}');
      print('Municipalities response body: ${response.body}');

      if (response.statusCode == 200) {
        final municipalities = jsonDecode(response.body) as List<dynamic>;
        print('Success! Found ${municipalities.length} municipalities in Isabela');
        return municipalities;
      } else {
        print('Failed to get municipalities: ${response.body}');
        throw Exception('Failed to fetch municipalities from backend API');
      }
    } catch (e) {
      print('Backend API approach failed: $e');
      throw Exception('Failed to load Isabela municipalities: $e');
    }
  }

  // Get barangays from backend API
  static Future<List<dynamic>> getBarangays(String municipalityCode) async {
    try {
      print('Getting barangays for municipality: $municipalityCode');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/barangays?municipalityCode=$municipalityCode'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Barangay response status: ${response.statusCode}');
      print('Barangay response body: ${response.body}');

      if (response.statusCode == 200) {
        final barangays = jsonDecode(response.body) as List<dynamic>;
        print('Found ${barangays.length} barangays');
        return barangays;
      } else {
        print('Failed to get barangays: ${response.body}');
        throw Exception('Failed to load barangays');
      }
    } catch (e) {
      print('Error getting barangays: $e');
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
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/provinces?regionCode=$regionCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get municipalities from backend API
  static Future<List<dynamic>> getMunicipalities(String provinceCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/address/municipalities?provinceCode=$provinceCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load municipalities');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}