import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';
import 'package:image_picker/image_picker.dart';

class PersonalInformationService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<Map<String, dynamic>?> getPersonalInformation() async {
    final token = await AuthService.getToken();
    
    log('🔍 PersonalInformationService DEBUG: Token exists: ${token != null}');
    if (token != null) {
      log('🔍 PersonalInformationService DEBUG: Token length: ${token.length}');
    }

    if (token == null) {
      log('🔍 PersonalInformationService DEBUG: No token found, returning null');
      return null;
    }

    try {
      // Clean token: trim and remove only newlines and carriage returns (not spaces)
      // JWT tokens are base64url encoded and should not have newlines
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();
      
      // Verify token format (JWT should have 3 parts separated by dots)
      final parts = cleanedToken.split('.');
      if (parts.length != 3) {
        log('🔍 PersonalInformationService DEBUG: ERROR - Invalid JWT format! Parts: ${parts.length}');
        log('🔍 PersonalInformationService DEBUG: Token preview: ${cleanedToken.substring(0, cleanedToken.length > 100 ? 100 : cleanedToken.length)}');
      }
      
      final authHeader = 'Bearer $cleanedToken';
      log('🔍 PersonalInformationService DEBUG: Making API call to $_baseUrl/farmer/profile');
      log('🔍 PersonalInformationService DEBUG: Original token length: ${token.length}');
      log('🔍 PersonalInformationService DEBUG: Cleaned token length: ${cleanedToken.length}');
      log('🔍 PersonalInformationService DEBUG: Token parts count: ${parts.length}');
      log('🔍 PersonalInformationService DEBUG: Token (first 50 chars): ${cleanedToken.substring(0, cleanedToken.length > 50 ? 50 : cleanedToken.length)}...');
      log('🔍 PersonalInformationService DEBUG: Token (last 20 chars): ...${cleanedToken.length > 20 ? cleanedToken.substring(cleanedToken.length - 20) : cleanedToken}');
      log('🔍 PersonalInformationService DEBUG: Authorization header length: ${authHeader.length}');
      
      log('🔍 PersonalInformationService DEBUG: Sending request with headers...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      );

      log('🔍 PersonalInformationService DEBUG: Response status: ${response.statusCode}');
      log('🔍 PersonalInformationService DEBUG: Response headers: ${response.headers}');
      log('🔍 PersonalInformationService DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('Personal Information API Response: $data');
        return data;
      } else {
        log('Failed to load farmer farmer-profile. Status code: ${response
            .statusCode}, Body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getPersonalInformation: $e', stackTrace: stackTrace);
    }

    return null;
  }

  static Future<bool> storePersonalInformation(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');
      final response = await http.post(
        Uri.parse('$_baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        log('Profile created successfully.');
        return true;
      } else {
        log('Failed to create farmer-profile. Status: ${response
            .statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storePersonalInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updatePersonalInformation(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    try {
      final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');
      final response = await http.put(
        Uri.parse('$_baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        log('Profile updated successfully.');
        return true;
      } else {
        log('Failed to update farmer-profile. Status: ${response
            .statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updatePersonalInformation: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateProfilePicture(XFile imageFile) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Upload failed: No token found.');
      return false;
    }

    try {
      final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');
      final uri = Uri.parse('$_baseUrl/farmer/profile/picture');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $cleanedToken';
      request.headers['X-Auth-Token'] = cleanedToken; // Workaround for nginx + PHP-FPM
      request.headers['Accept'] = 'application/json';

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Profile picture updated successfully. Body: $respStr');
        return true;
      } else {
        log('Failed to update farmer-profile picture. Status: ${response
            .statusCode}, Body: $respStr');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateProfilePicture: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> deleteProfilePicture() async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    try {
      final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');
      final response = await http.delete(
        Uri.parse('$_baseUrl/farmer/profile/picture'),
        headers: {
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log('Profile picture deleted successfully.');
        return true;
      } else {
        log('Failed to delete farmer-profile picture. Status: ${response
            .statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deleteProfilePicture: $e', stackTrace: stackTrace);
      return false;
    }
  }
}