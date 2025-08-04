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

    if (token == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('Failed to load farmer farmer-profile. Status code: ${response
            .statusCode}');
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
      final response = await http.post(
        Uri.parse('$_baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
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
      final response = await http.put(
        Uri.parse('$_baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
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
      final uri = Uri.parse('$_baseUrl/farmer/profile/picture');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
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
      final response = await http.delete(
        Uri.parse('$_baseUrl/farmer/profile/picture'),
        headers: {
          'Authorization': 'Bearer $token',
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