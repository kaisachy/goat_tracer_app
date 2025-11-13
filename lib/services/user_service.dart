import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/user.dart';
import 'secure_storage_service.dart';

class UserService {
  final String _baseUrl = AppConfig.baseUrl;
  final SecureStorageService _storage = SecureStorageService();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Fetches a user by their ID.
  Future<User> getUser(int id) async {
    debugPrint('🔍 UserService DEBUG: getUser($id) called');
    debugPrint('🔍 UserService DEBUG: Base URL: $_baseUrl');
    
    final token = await _getToken();
    debugPrint('🔍 UserService DEBUG: Token exists: ${token != null}');
    if (token == null) {
      debugPrint('🔍 UserService DEBUG: ❌ No token found - throwing auth exception');
      throw Exception('Authentication required. Please login again.');
    }

    final url = '$_baseUrl/users/$id';
    debugPrint('🔍 UserService DEBUG: Making GET request to: $url');
    debugPrint('🔍 UserService DEBUG: Request headers: {"Content-Type": "application/json", "Authorization": "Bearer ***"}');
    debugPrint('🔍 UserService DEBUG: Request timestamp: ${DateTime.now()}');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🔍 UserService DEBUG: Response received');
      debugPrint('🔍 UserService DEBUG: Status code: ${response.statusCode}');
      debugPrint('🔍 UserService DEBUG: Response headers: ${response.headers}');
      debugPrint('🔍 UserService DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('🔍 UserService DEBUG: ✅ 200 OK - parsing response');
        final data = jsonDecode(response.body);
        debugPrint('🔍 UserService DEBUG: Parsed JSON: $data');
        
        if (data['data'] != null) {
          debugPrint('🔍 UserService DEBUG: Creating User object from data');
          final user = User.fromJson(data['data']);
          debugPrint('🔍 UserService DEBUG: ✅ User object created: ${user.toString()}');
          return user;
        } else {
          debugPrint('🔍 UserService DEBUG: ❌ No data field in response');
          throw Exception('Invalid response format: missing data field');
        }
      } else if (response.statusCode == 401) {
        debugPrint('🔍 UserService DEBUG: ❌ 401 Unauthorized - session expired');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        debugPrint('🔍 UserService DEBUG: ❌ 404 Not Found - user not found');
        throw Exception('User not found.');
      } else {
        debugPrint('🔍 UserService DEBUG: ❌ HTTP error ${response.statusCode}');
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Failed to load user data.';
        debugPrint('🔍 UserService DEBUG: Error message: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('🔍 UserService DEBUG: ❌ Exception during API call: $e');
      if (e is FormatException) {
        debugPrint('🔍 UserService DEBUG: FormatException - invalid JSON response');
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  Future<List<User>> getUsersByRoles({List<String>? roles}) async {
    debugPrint('🔍 UserService DEBUG: getUsersByRoles called with roles: $roles');

    final token = await _getToken();
    if (token == null) {
      debugPrint('🔍 UserService DEBUG: No token found');
      throw Exception('Authentication required. Please login again.');
    }

    // Build query parameters for roles
    String queryParams = '';
    if (roles != null && roles.isNotEmpty) {
      queryParams = '?roles=${roles.join(',')}';
    }

    final fullUrl = '$_baseUrl/users/by-roles$queryParams';
    debugPrint('🔍 UserService DEBUG: Making request to: $fullUrl');

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🔍 UserService DEBUG: Response status: ${response.statusCode}');
      debugPrint('🔍 UserService DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> usersData = data['data'];
          debugPrint('🔍 UserService DEBUG: Found ${usersData.length} users in response');

          final users = usersData.map((userData) => User.fromJson(userData)).toList();
          debugPrint('🔍 UserService DEBUG: Successfully parsed ${users.length} User objects');

          return users;
        } else {
          debugPrint('🔍 UserService DEBUG: Response success=false or no data');
          return [];
        }
      } else if (response.statusCode == 401) {
        debugPrint('🔍 UserService DEBUG: 401 Unauthorized');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        debugPrint('🔍 UserService DEBUG: 404 Not Found');
        return [];
      } else {
        debugPrint('🔍 UserService DEBUG: HTTP error ${response.statusCode}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load users. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔍 UserService DEBUG: Exception: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  /// Fetches technicians using the dedicated endpoint
  Future<List<User>> getTechnicians() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    debugPrint('Fetching technicians from dedicated endpoint...');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/technicians'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Technicians response status: ${response.statusCode}');
      debugPrint('Technicians response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> usersData = data['data'];
          final technicians = usersData.map((userData) => User.fromJson(userData)).toList();

          debugPrint('Found ${technicians.length} technicians');
          return technicians;
        } else {
          debugPrint('No technicians found in response');
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load technicians. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getTechnicians: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  /// Updates a user's profile information.
  Future<User> updateUser(int id, String firstName, String lastName, String email,
      {String? province, String? municipality, String? barangay}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final Map<String, dynamic> body = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };

    if (province != null) body['province'] = province;
    if (municipality != null) body['municipality'] = municipality;
    if (barangay != null) body['barangay'] = barangay;

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['data']);
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update profile.');
    }
  }

  /// Changes the password for a given user ID.
  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    debugPrint('🔍 UserService DEBUG: changePassword($userId) called');
    debugPrint('🔍 UserService DEBUG: Base URL: $_baseUrl');
    
    final token = await _getToken();
    debugPrint('🔍 UserService DEBUG: Token exists: ${token != null}');
    if (token == null) {
      debugPrint('🔍 UserService DEBUG: ❌ No token found - throwing auth exception');
      throw Exception('Authentication required. Please login again.');
    }

    final url = '$_baseUrl/users/$userId/password';
    debugPrint('🔍 UserService DEBUG: Making PUT request to: $url');
    debugPrint('🔍 UserService DEBUG: Request headers: {"Content-Type": "application/json; charset=UTF-8", "Authorization": "Bearer ***"}');
    debugPrint('🔍 UserService DEBUG: Request body: {"current_password": "***", "new_password": "***"}');
    debugPrint('🔍 UserService DEBUG: Request timestamp: ${DateTime.now()}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      debugPrint('🔍 UserService DEBUG: Response received');
      debugPrint('🔍 UserService DEBUG: Status code: ${response.statusCode}');
      debugPrint('🔍 UserService DEBUG: Response headers: ${response.headers}');
      debugPrint('🔍 UserService DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('🔍 UserService DEBUG: ✅ 200 OK - password changed successfully');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('🔍 UserService DEBUG: ❌ 401 Unauthorized - session expired');
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint('🔍 UserService DEBUG: ❌ HTTP error ${response.statusCode}');
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Failed to change password.';
        debugPrint('🔍 UserService DEBUG: Error message: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('🔍 UserService DEBUG: ❌ Exception during password change API call: $e');
      if (e is FormatException) {
        debugPrint('🔍 UserService DEBUG: FormatException - invalid JSON response');
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }
}
