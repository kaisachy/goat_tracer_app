import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<Map<String, dynamic>?> getFarmerProfile() async {
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
        log('Failed to load farmer farmer-profile. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getFarmerProfile: $e', stackTrace: stackTrace);
    }

    return null;
  }

  static Future<bool> storeFarmerProfile(Map<String, dynamic> data) async {
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
        log('Failed to create farmer-profile. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeFarmerProfile: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateFarmerProfile(Map<String, dynamic> data) async {
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
        log('Failed to update farmer-profile. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateFarmerProfile: $e', stackTrace: stackTrace);
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
        log('Failed to update farmer-profile picture. Status: ${response.statusCode}, Body: $respStr');
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
        log('Failed to delete farmer-profile picture. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deleteProfilePicture: $e', stackTrace: stackTrace);
      return false;
    }
  }






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






  static Future<List<Map<String, dynamic>>> getEducationalBackground() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/education'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load educational background. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getEducationalBackground: $e', stackTrace: stackTrace);
    }

    return [];
  }

  static Future<bool> storeEducationalBackground(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/farmer/education'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        log('Educational background created successfully.');
        return true;
      } else {
        log('Failed to create educational background. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeEducationalBackground: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateEducationalBackground(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/farmer/education'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        log('Educational background updated successfully.');
        return true;
      } else {
        log('Failed to update educational background. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateEducationalBackground: $e', stackTrace: stackTrace);
      return false;
    }
  }








  static Future<List<Map<String, dynamic>>> getTrainingsAndSeminars() async {
    final token = await AuthService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farmer/trainings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load trainings and seminars. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error in getTrainingsAndSeminars: $e', stackTrace: stackTrace);
    }

    return [];
  }

  static Future<bool> storeTrainingsAndSeminars(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Store failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/farmer/trainings');
    log('Attempting to POST to $uri'); // Debugging log

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        log('Training & Seminar created successfully.');
        return true;
      } else {
        log('Failed to create Training & Seminar. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in storeTrainingsAndSeminars: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateTrainingsAndSeminars(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/farmer/trainings');
    log('Attempting to PUT to $uri'); // Debugging log

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // FIX: Corrected log message for clarity.
        log('Training & Seminar updated successfully.');
        return true;
      } else {
        log('Failed to update Training & Seminar. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in updateTrainingsAndSeminars: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> deleteTrainingsAndSeminars(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Delete failed: No token found.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/farmer/trainings');
    log('Attempting to DELETE from $uri with id=$id'); // Debug log

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        log('Training & Seminar deleted successfully.');
        return true;
      } else {
        log('Failed to delete Training & Seminar. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in deleteTrainingsAndSeminars: $e', stackTrace: stackTrace);
      return false;
    }
  }

}