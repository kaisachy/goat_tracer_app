// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'secure_storage_service.dart'; // Import this

class AuthService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<Map<String, dynamic>> register(
      String firstName,
      String lastName,
      String email,
      String password,
      ) async {
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

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      // Use SecureStorageService to save token
      await SecureStorageService().saveToken(data['token']);

      // Save user ID if available
      if (data['user'] != null && data['user']['id'] != null) {
        await SecureStorageService().write(key: 'user_id', value: data['user']['id'].toString());
      }
    }
    return data;
  }

  static Future<void> logout() async {
    await SecureStorageService().deleteToken();
    await SecureStorageService().delete(key: 'user_id');
  }

  static Future<String?> getToken() async {
    return await SecureStorageService().getToken();
  }

  static Future<String?> getUserId() async {
    return await SecureStorageService().read(key: 'user_id');
  }
}