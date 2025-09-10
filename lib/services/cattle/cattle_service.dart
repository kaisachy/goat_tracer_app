import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../models/cattle.dart';
import '../auth_service.dart';

class CattleService {
  static final String _baseUrl = AppConfig.baseUrl;

  /// Get all cattle information
  static Future<List<Cattle>> getAllCattle() async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getAllCattle failed: No token found.');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getAllCattle response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cattleList = List<Map<String, dynamic>>.from(data['data']);

        return cattleList.map((cattleData) => Cattle.fromJson(cattleData)).toList();
      } else {
        log('Failed to load cattle. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getAllCattle: $e', stackTrace: stackTrace);
    }

    return [];
  }

  /// Get cattle by tag number - Fixed implementation
  static Future<Cattle?> getCattleByTag(String tag) async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getCattleByTag failed: No token found.');
      return null;
    }

    try {
      log('Attempting to get cattle by tag: $tag');

      // Get all cattle and find by tag (more reliable approach)
      final allCattle = await getAllCattle();

      if (allCattle.isEmpty) {
        log('No cattle found in database');
        return null;
      }

      // Try to find exact match first
      Cattle? foundCattle;
      try {
        foundCattle = allCattle.firstWhere(
              (cattle) => cattle.tagNo == tag,
        );
      } catch (e) {
        // If exact match fails, try case-insensitive match
        try {
          foundCattle = allCattle.firstWhere(
                (cattle) => cattle.tagNo.toLowerCase() == tag.toLowerCase(),
          );
        } catch (e2) {
          log('Cattle with tag $tag not found');
          return null;
        }
      }

      log('Found cattle: ${foundCattle.tagNo} - Gender: ${foundCattle.sex}');
      return foundCattle;

    } catch (e, stackTrace) {
      log('Error in getCattleByTag: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// Get cattle information as raw data (for backward compatibility)
  static Future<List<Map<String, dynamic>>> getCattleInformation() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles'),
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
      log('Error in getCattleInformation: $e', stackTrace: stackTrace);
    }

    return [];
  }

  /// Store/Create new cattle information with image support
  static Future<bool> storeCattleInformation(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles');
    log('Attempting to POST to $uri');

    // Sanitize data before sending
    final sanitizedData = Map<String, dynamic>.from(data);

    // Handle image data
    if (sanitizedData.containsKey('cattle_picture') &&
        sanitizedData['cattle_picture'] != null &&
        sanitizedData['cattle_picture'].toString().isNotEmpty) {
      log('Including cattle picture in request');
    }

    log('Data to store: ${jsonEncode(sanitizedData).length} characters');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sanitizedData),
      );

      log('Store cattle response status: ${response.statusCode}');
      log('Store cattle response body: ${response.body}');

      if (response.statusCode == 201) {
        log('Cattle created successfully.');
        return true;
      } else {
        log('Failed to create cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeCattleInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Update existing cattle information with image support
  // This method is already designed to handle the new logic because it accepts a generic map.
  // The UI will be responsible for populating this map with the necessary original and new parent tags.
  static Future<bool> updateCattleInformation(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles');
    log('Attempting to PUT to $uri');

    // Sanitize data before sending
    final sanitizedData = Map<String, dynamic>.from(data);

    // Handle image data
    if (sanitizedData.containsKey('cattle_picture')) {
      if (sanitizedData['cattle_picture'] == null) {
        log('Removing cattle picture from cattle ID: ${sanitizedData['id']}');
      } else if (sanitizedData['cattle_picture'].toString().isNotEmpty) {
        log('Updating cattle picture for cattle ID: ${sanitizedData['id']}');
      }
    }

    log('Data to update: ${jsonEncode(sanitizedData).length} characters');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sanitizedData),
      );

      log('Update cattle response status: ${response.statusCode}');
      log('Update cattle response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Cattle updated successfully.');
        return true;
      } else {
        log('Failed to update cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateCattleInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Update only the cattle picture
  static Future<bool> updateCattlePicture(int cattleId, String? base64Image) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update picture failed: No token found.');
      return false;
    }

    final data = {
      'id': cattleId,
      'cattle_picture': base64Image,
    };

    return await updateCattleInformation(data);
  }

  /// Delete cattle picture only (set to null)
  static Future<bool> deleteCattlePicture(int cattleId) async {
    return await updateCattlePicture(cattleId, null);
  }

  /// Delete cattle information
  static Future<bool> deleteCattleInformation(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/cattles');
    log('Attempting to DELETE from $uri with id=$id');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      );

      log('Delete cattle response status: ${response.statusCode}');
      log('Delete cattle response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Cattle deleted successfully.');
        return true;
      } else {
        log('Failed to delete cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deleteCattleInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Alternative method to get cattle by ID (if needed)
  static Future<Cattle?> getCattleById(int id) async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getCattleById failed: No token found.');
      return null;
    }

    try {
      // Get all cattle and find by ID
      log('Getting all cattle to find ID: $id');
      final allCattle = await getAllCattle();

      final foundCattle = allCattle.firstWhere(
            (cattle) => cattle.id == id,
        orElse: () => throw Exception('Cattle not found'),
      );

      log('Found cattle by ID: ${foundCattle.tagNo}');
      return foundCattle;
    } catch (e) {
      log('Error in getCattleById: $e');
      return null;
    }
  }

  /// Validate image size before upload
  static bool validateImageSize(String base64Image, {int maxSizeInMB = 5}) {
    try {
      // Calculate size in bytes
      final sizeInBytes = base64Image.length * (3 / 4);
      final sizeInMB = sizeInBytes / (1024 * 1024);

      log('Image size: ${sizeInMB.toStringAsFixed(2)} MB');

      return sizeInMB <= maxSizeInMB;
    } catch (e) {
      log('Error validating image size: $e');
      return false;
    }
  }

  /// Get cattle with full image data
  static Future<Cattle?> getCattleWithImage(int id) async {
    final cattle = await getCattleById(id);
    if (cattle != null) {
      log('Retrieved cattle with image data: ${cattle.tagNo}');
    }
    return cattle;
  }
}