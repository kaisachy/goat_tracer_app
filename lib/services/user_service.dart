import 'dart:convert';
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
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['data']);
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load user data.');
    }
  }

  Future<List<User>> getUsersByRoles({List<String>? roles}) async {
    print('🔍 UserService DEBUG: getUsersByRoles called with roles: $roles');

    final token = await _getToken();
    if (token == null) {
      print('🔍 UserService DEBUG: No token found');
      throw Exception('Authentication required. Please login again.');
    }

    // Build query parameters for roles
    String queryParams = '';
    if (roles != null && roles.isNotEmpty) {
      queryParams = '?roles=${roles.join(',')}';
    }

    final fullUrl = '$_baseUrl/users/by-roles$queryParams';
    print('🔍 UserService DEBUG: Making request to: $fullUrl');

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 UserService DEBUG: Response status: ${response.statusCode}');
      print('🔍 UserService DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> usersData = data['data'];
          print('🔍 UserService DEBUG: Found ${usersData.length} users in response');

          final users = usersData.map((userData) => User.fromJson(userData)).toList();
          print('🔍 UserService DEBUG: Successfully parsed ${users.length} User objects');

          return users;
        } else {
          print('🔍 UserService DEBUG: Response success=false or no data');
          return [];
        }
      } else if (response.statusCode == 401) {
        print('🔍 UserService DEBUG: 401 Unauthorized');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('🔍 UserService DEBUG: 404 Not Found');
        return [];
      } else {
        print('🔍 UserService DEBUG: HTTP error ${response.statusCode}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load users. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🔍 UserService DEBUG: Exception: $e');
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

    print('Fetching technicians from dedicated endpoint...');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/technicians'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Technicians response status: ${response.statusCode}');
      print('Technicians response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> usersData = data['data'];
          final technicians = usersData.map((userData) => User.fromJson(userData)).toList();

          print('Found ${technicians.length} technicians');
          return technicians;
        } else {
          print('No technicians found in response');
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load technicians. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTechnicians: $e');
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
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId/password'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to change password.');
    }
  }
}
