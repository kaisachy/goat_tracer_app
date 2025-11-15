import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../models/goat.dart';
import '../../utils/goat_age_classification.dart';
import '../auth_service.dart';

class GoatService {
  static final String _baseUrl = AppConfig.baseUrl;

  /// Get all Goat information
  static Future<List<Goat>> getAllGoats() async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getAllGoats failed: No token found.');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getAllGoats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final goatList = List<Map<String, dynamic>>.from(data['data']);

        return goatList.map((goatData) => Goat.fromJson(goatData)).toList();
      } else {
        log('Failed to load Goat. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getAllGoats: $e', stackTrace: stackTrace);
    }

    return [];
  }

  /// Get Goat by tag number - Fixed implementation
  static Future<Goat?> getGoatByTag(String tag) async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getGoatByTag failed: No token found.');
      return null;
    }

    try {
      log('Attempting to get Goat by tag: $tag');

      // Get all Goat and find by tag (more reliable approach)
      final allGoats = await getAllGoats();

      if (allGoats.isEmpty) {
        log('No Goat found in database');
        return null;
      }

      // Try to find exact match first
      Goat? foundGoat;
      try {
        foundGoat = allGoats.firstWhere(
              (goat) => goat.tagNo == tag,
        );
      } catch (e) {
        // If exact match fails, try case-insensitive match
        try {
          foundGoat = allGoats.firstWhere(
                (goat) => goat.tagNo.toLowerCase() == tag.toLowerCase(),
          );
        } catch (e2) {
          log('Goat with tag $tag not found');
          return null;
        }
      }

      log('Found Goat: ${foundGoat.tagNo} - Gender: ${foundGoat.sex}');
      return foundGoat;

    } catch (e, stackTrace) {
      log('Error in getGoatByTag: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// Get Goat information as raw data (for backward compatibility)
  static Future<List<Map<String, dynamic>>> getGoatInformation() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load Goat. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getGoatInformation: $e', stackTrace: stackTrace);
    }

    return [];
  }

  /// Store/Create new Goat information with image support
  static Future<bool> storegoatInformation(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/goats');
    log('Attempting to POST to $uri');

    // Sanitize data before sending
    final sanitizedData = Map<String, dynamic>.from(data);

    // Handle image data
    if (sanitizedData.containsKey('goat_picture') &&
        sanitizedData['goat_picture'] != null &&
        sanitizedData['goat_picture'].toString().isNotEmpty) {
      log('Including Goat picture in request');
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

      log('Store Goat response status: ${response.statusCode}');
      log('Store Goat response body: ${response.body}');

      if (response.statusCode == 201) {
        log('Goat created successfully.');
        return true;
      } else {
        log('Failed to create Goat. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storegoatInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Update existing Goat information with image support
  // This method is already designed to handle the new logic because it accepts a generic map.
  // The UI will be responsible for populating this map with the necessary original and new parent tags.
  static Future<bool> updateGoatInformation(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/goats');
    log('Attempting to PUT to $uri');

    // Sanitize data before sending
    final sanitizedData = Map<String, dynamic>.from(data);

    // Handle image data
    if (sanitizedData.containsKey('goat_picture')) {
      if (sanitizedData['goat_picture'] == null) {
        log('Removing Goat picture from Goat ID: ${sanitizedData['id']}');
      } else if (sanitizedData['goat_picture'].toString().isNotEmpty) {
        log('Updating Goat picture for Goat ID: ${sanitizedData['id']}');
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

      log('Update Goat response status: ${response.statusCode}');
      log('Update Goat response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Goat updated successfully.');
        return true;
      } else {
        log('Failed to update Goat. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateGoatInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Update only the Goat picture
  static Future<bool> updategoatPicture(int goatId, String? base64Image) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update picture failed: No token found.');
      return false;
    }

    final data = {
      'id': goatId,
      'goat_picture': base64Image,
    };

    return await updateGoatInformation(data);
  }

  /// Delete Goat picture only (set to null)
  static Future<bool> deletegoatPicture(int goatId) async {
    return await updategoatPicture(goatId, null);
  }

  /// Delete Goat information
  static Future<bool> deletegoatInformation(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/goats');
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

      log('Delete Goat response status: ${response.statusCode}');
      log('Delete Goat response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Goat deleted successfully.');
        return true;
      } else {
        log('Failed to delete Goat. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deletegoatInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Alternative method to get Goat by ID (if needed)
  static Future<Goat?> getGoatById(int id) async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getGoatById failed: No token found.');
      return null;
    }

    try {
      // Get all Goat and find by ID
      log('Getting all Goat to find ID: $id');
      final allGoats = await getAllGoats();

      // Try to find in active Goat first
      try {
        final foundGoat = allGoats.firstWhere(
              (goat) => goat.id == id,
          orElse: () => throw Exception('Goat not found in active Goat'),
        );

        log('Found Goat by ID in active Goat: ${foundGoat.tagNo}');
        return foundGoat;
      } catch (e) {
        log('Goat not found in active Goat, searching in archived Goat...');
        
        // If not found in active Goat, search in archived Goat
        final archivedgoat = await getArchivedgoat();
        
        final foundGoat = archivedgoat.firstWhere(
              (goat) => goat.id == id,
          orElse: () => throw Exception('Goat not found in archived Goat either'),
        );

        log('Found Goat by ID in archived Goat: ${foundGoat.tagNo}');
        return foundGoat;
      }
    } catch (e) {
      log('Error in getGoatById: $e');
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

  /// Get Goat with full image data
  static Future<Goat?> getGoatWithImage(int id) async {
    final goat = await getGoatById(id);
    if (goat != null) {
      log('Retrieved Goat with image data: ${goat.tagNo}');
    }
    return goat;
  }

  /// Archive a Goat record
  static Future<bool> archivegoat(int id, String reason, {String? notes}) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Archive failed: No token found.');
      return false;
    }

    final data = {
      'id': id,
      'reason': reason,
      if (notes != null) 'notes': notes,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/goats/archive'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      log('Archive Goat response status: ${response.statusCode}');
      log('Archive Goat response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Goat archived successfully.');
        return true;
      } else {
        log('Failed to archive Goat. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in archivegoat: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Unarchive a Goat record
  static Future<bool> unarchivegoat(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Unarchive failed: No token found.');
      return false;
    }

    final data = {
      'id': id,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/goats/unarchive'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      log('Unarchive Goat response status: ${response.statusCode}');
      log('Unarchive Goat response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Goat unarchived successfully.');
        return true;
      } else {
        log('Failed to unarchive Goat. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in unarchivegoat: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Get archived Goat
  static Future<List<Goat>> getArchivedgoat() async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getArchivedgoat failed: No token found.');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goats/archived'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getArchivedgoat response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final goatList = List<Map<String, dynamic>>.from(data['data']);

        return goatList.map((goatData) => Goat.fromJson(goatData)).toList();
      } else {
        log('Failed to load archived Goat. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getArchivedgoat: $e', stackTrace: stackTrace);
    }

    return [];
  }

  /// Auto-update classifications for all Goat based on age
  /// This method checks all Goat and updates their classifications if they've aged into a new category
  static Future<int> autoUpdategoatClassifications() async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('autoUpdategoatClassifications failed: No token found.');
      return 0;
    }

    try {
      // Get all active Goat
      final goatList = await getAllGoats();
      
      if (goatList.isEmpty) {
        return 0;
      }

      // Check which Goat need classification updates
      final updatedGoat = GoatAgeClassification.autoUpdateClassificationsForList(goatList);
      
      if (updatedGoat.isEmpty) {
        log('No Goat need classification updates');
        return 0;
      }

      log('Found ${updatedGoat.length} Goat that need classification updates');

      // Update each Goat that needs classification update
      int successCount = 0;
      for (var entry in updatedGoat.entries) {
        final goat = entry.value;
        
        final updateData = {
          'id': goat.id,
          'classification': goat.classification,
        };

        final success = await updateGoatInformation(updateData);
        if (success) {
          successCount++;
          log('✅ Auto-updated Goat ${goat.tagNo} classification to ${goat.classification}');
        } else {
          log('❌ Failed to auto-update Goat ${goat.tagNo}');
        }
      }

      log('Auto-update completed: $successCount/${updatedGoat.length} Goat updated');
      return successCount;
    } catch (e, stackTrace) {
      log('Error in autoUpdategoatClassifications: $e', stackTrace: stackTrace);
      return 0;
    }
  }

  /// Get Goat with automatic classification updates
  /// Returns list of Goat with classifications auto-updated based on age
  static Future<List<Goat>> getGoatWithAutoUpdatedClassifications() async {
    try {
      // Get all Goat
      final goatList = await getAllGoats();
      
      if (goatList.isEmpty) {
        return goatList;
      }

      // Check and auto-update classifications
      final updatedGoat = GoatAgeClassification.autoUpdateClassificationsForList(goatList);
      
      if (updatedGoat.isEmpty) {
        return goatList;
      }

      // Apply the updated classifications to the list
      final resultList = goatList.map<Goat>((goat) {
        return updatedGoat[goat.id] ?? goat;
      }).toList();

      return resultList;
    } catch (e) {
      log('Error in getGoatWithAutoUpdatedClassifications: $e');
      return await getAllGoats();
    }
  }
}