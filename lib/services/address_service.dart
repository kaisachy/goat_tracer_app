import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressService {
  // Call the Philippine address API directly instead of through your backend
  static const String _externalApiBase = 'https://psgc.gitlab.io/api';

  // Get Isabela municipalities directly from external API
  static Future<List<dynamic>> getIsabelaMunicipalities() async {
    try {
      print('Getting Isabela municipalities directly from external API...');

      // Step 1: Get Region 2 (Cagayan Valley) provinces
      final provincesUrl = '$_externalApiBase/regions/020000000/provinces/';
      print('Getting provinces from: $provincesUrl');

      final provincesResponse = await http.get(
        Uri.parse(provincesUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print('Provinces response status: ${provincesResponse.statusCode}');

      if (provincesResponse.statusCode == 200) {
        final provinces = jsonDecode(provincesResponse.body) as List<dynamic>;
        print('Found ${provinces.length} provinces in Region 2');

        // Step 2: Find Isabela province
        Map<String, dynamic>? isabelaProvince;
        for (var province in provinces) {
          print('Province: ${province['name']} (${province['code']})');
          if (province['name'].toString().toLowerCase().contains('isabela')) {
            isabelaProvince = province;
            print('Found Isabela: ${province}');
            break;
          }
        }

        if (isabelaProvince != null) {
          print('Found Isabela province with code: ${isabelaProvince['code']}');

          // Step 3: Get municipalities for Isabela
          final municipalitiesUrl = '$_externalApiBase/provinces/${isabelaProvince['code']}/cities-municipalities/';
          print('Getting municipalities from: $municipalitiesUrl');

          final municipalitiesResponse = await http.get(
            Uri.parse(municipalitiesUrl),
            headers: {'Content-Type': 'application/json'},
          );

          print('Municipalities response status: ${municipalitiesResponse.statusCode}');

          if (municipalitiesResponse.statusCode == 200) {
            final municipalities = jsonDecode(municipalitiesResponse.body) as List<dynamic>;
            print('Success! Found ${municipalities.length} municipalities in Isabela');
            return municipalities;
          } else {
            print('Failed to get municipalities: ${municipalitiesResponse.body}');
            throw Exception('Failed to fetch municipalities from external API');
          }
        } else {
          print('Could not find Isabela province in the list');
          throw Exception('Isabela province not found');
        }
      } else {
        print('Failed to get provinces: ${provincesResponse.body}');
        throw Exception('Failed to fetch provinces from external API');
      }
    } catch (e) {
      print('Direct API approach failed: $e');
      throw Exception('Failed to load Isabela municipalities: $e');
    }
  }

  // Get barangays directly from external API
  static Future<List<dynamic>> getBarangays(String municipalityCode) async {
    try {
      print('Getting barangays for municipality: $municipalityCode');
      final url = '$_externalApiBase/cities-municipalities/$municipalityCode/barangays/';
      print('Barangay URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Barangay response status: ${response.statusCode}');

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

  // For backward compatibility, keep methods that use your backend
  // (these will only work if your backend routing is fixed)
  static Future<List<dynamic>> getRegions() async {
    // This one works, so keep using your backend
    try {
      final response = await http.get(
        Uri.parse('http://192.168.254.113/cattle-tracer/public/api/address/regions'),
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

  static Future<List<dynamic>> getProvinces(String regionCode) async {
    // Use external API since your backend routing is broken
    try {
      final response = await http.get(
        Uri.parse('$_externalApiBase/regions/$regionCode/provinces/'),
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

  static Future<List<dynamic>> getMunicipalities(String provinceCode) async {
    // Use external API since your backend routing is broken
    try {
      final response = await http.get(
        Uri.parse('$_externalApiBase/provinces/$provinceCode/cities-municipalities/'),
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