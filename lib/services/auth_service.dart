import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'secure_storage_service.dart';

class AuthService {
  static final String _baseUrl = AppConfig.baseUrl;
  static final SecureStorageService _storage = SecureStorageService();

  static Future<Map<String, dynamic>> register(
      String firstName,
      String lastName,
      String email,
      String password,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      // Handle non-200 responses
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      // Handle non-200 responses
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }

      if (data['success'] == true) {
        // Save token and user ID
        await _storage.saveToken(data['token']);

        if (data['user'] != null && data['user']['id'] != null) {
          await _storage.write(
              key: 'user_id',
              value: data['user']['id'].toString()
          );
        }
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.delete(key: 'user_id');
  }

  static Future<String?> getToken() async {
    return await _storage.getToken();
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  // New method to get current user ID from token claims
  static Future<String?> getCurrentUserId() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );

      return payload['sub']?.toString();
    } catch (e) {
      print('Error decoding user ID from token: $e');
      return null;
    }
  }
}