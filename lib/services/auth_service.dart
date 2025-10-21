import 'dart:convert';
import 'dart:developer';
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
      String? province,
      String? municipality,
      String? barangay,
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
          'province': province,
          'municipality': municipality,
          'barangay': barangay,
          'role': 'farmer', // Default to farmer for this app
        }),
      );

      final data = jsonDecode(response.body);

      // Handle non-200 responses
      if (response.statusCode != 200 && response.statusCode != 201) {
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

  /// Login method with role requirement support
  static Future<Map<String, dynamic>> login(
      String email,
      String password,
      {String? requiredRole}
      ) async {
    try {
      final body = {
        'email': email,
        'password': password,
      };

      // Add role requirement if specified
      if (requiredRole != null) {
        body['role_required'] = requiredRole;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      // Handle non-200 responses
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'error_type': data['error_type'],
          'status_code': response.statusCode,
        };
      }

      if (data['success'] == true) {
        print('🔍 AuthService DEBUG: Login successful, saving data...');
        // Save token and user data
        await _storage.saveToken(data['token']);
        print('🔍 AuthService DEBUG: Token saved');

        if (data['user'] != null && data['user']['id'] != null) {
          final userId = data['user']['id'].toString();
          print('🔍 AuthService DEBUG: Saving user ID: $userId');
          await _storage.write(
              key: 'user_id',
              value: userId
          );
          print('🔍 AuthService DEBUG: User ID saved to storage');

          // Save additional user info for easy access
          await _storage.write(
              key: 'user_role',
              value: data['user']['role'] ?? 'farmer'
          );

          await _storage.write(
              key: 'user_email_verified',
              value: data['user']['email_verified'].toString()
          );

          final firstName = data['user']['first_name'] ?? '';
          final lastName = data['user']['last_name'] ?? '';
          
          log('🔍 AuthService DEBUG: Saving user names - First: $firstName, Last: $lastName');
          
          await _storage.write(
              key: 'user_first_name',
              value: firstName
          );

          await _storage.write(
              key: 'user_last_name',
              value: lastName
          );
          
          log('🔍 AuthService DEBUG: User names saved successfully');
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

  /// Farmer-specific login method
  static Future<Map<String, dynamic>> farmerLogin(String email, String password) async {
    return await login(email, password, requiredRole: 'farmer');
  }

  /// Resend verification email
  static Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Failed to send verification email',
        'status_code': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Request password reset
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Failed to send password reset email',
        'status_code': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Reset password with token
  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Failed to reset password',
        'status_code': response.statusCode,
      };
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
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_email_verified');
    await _storage.delete(key: 'user_first_name');
    await _storage.delete(key: 'user_last_name');
  }

  static Future<String?> getToken() async {
    return await _storage.getToken();
  }

  static Future<String?> getUserId() async {
    print('🔍 AuthService DEBUG: getUserId() called');
    final userId = await _storage.read(key: 'user_id');
    print('🔍 AuthService DEBUG: User ID from storage: $userId');
    return userId;
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  static Future<bool> isEmailVerified() async {
    final verified = await _storage.read(key: 'user_email_verified');
    return verified == 'true';
  }

  static Future<String?> getUserFirstName() async {
    // First try to get from stored data
    String? firstName = await _storage.read(key: 'user_first_name');
    log('🔍 AuthService DEBUG: getUserFirstName() - Retrieved from storage: $firstName');
    
    // If not found in storage, try to get from JWT token
    if (firstName == null || firstName.isEmpty) {
      try {
        final token = await getToken();
        if (token != null) {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = json.decode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
            );
            firstName = payload['first_name']?.toString();
            log('🔍 AuthService DEBUG: getUserFirstName() - Retrieved from token: $firstName');
          }
        }
      } catch (e) {
        log('🔍 AuthService DEBUG: Error getting first name from token: $e');
      }
    }
    
    return firstName;
  }

  static Future<String?> getUserLastName() async {
    // First try to get from stored data
    String? lastName = await _storage.read(key: 'user_last_name');
    log('🔍 AuthService DEBUG: getUserLastName() - Retrieved from storage: $lastName');
    
    // If not found in storage, try to get from JWT token
    if (lastName == null || lastName.isEmpty) {
      try {
        final token = await getToken();
        if (token != null) {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = json.decode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
            );
            lastName = payload['last_name']?.toString();
            log('🔍 AuthService DEBUG: getUserLastName() - Retrieved from token: $lastName');
          }
        }
      } catch (e) {
        log('🔍 AuthService DEBUG: Error getting last name from token: $e');
      }
    }
    
    return lastName;
  }

  /// Check if user is authenticated and has valid token
  static Future<bool> isAuthenticated() async {
    print('🔍 AuthService DEBUG: isAuthenticated() called');
    final token = await getToken();
    print('🔍 AuthService DEBUG: Token exists: ${token != null}');
    if (token == null) {
      print('🔍 AuthService DEBUG: ❌ No token - not authenticated');
      return false;
    }

    try {
      print('🔍 AuthService DEBUG: Checking token validity...');
      final parts = token.split('.');
      print('🔍 AuthService DEBUG: Token parts count: ${parts.length}');
      if (parts.length != 3) {
        print('🔍 AuthService DEBUG: ❌ Invalid token format - not 3 parts');
        return false;
      }

      print('🔍 AuthService DEBUG: Decoding token payload...');
      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      print('🔍 AuthService DEBUG: Token payload: $payload');

      final exp = payload['exp'];
      print('🔍 AuthService DEBUG: Token expiration: $exp');
      if (exp == null) {
        print('🔍 AuthService DEBUG: ❌ No expiration in token');
        return false;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('🔍 AuthService DEBUG: Current time: $currentTime');
      final isValid = currentTime < exp;
      print('🔍 AuthService DEBUG: Token is valid: $isValid');
      return isValid;
    } catch (e) {
      print('🔍 AuthService DEBUG: ❌ Error checking token validity: $e');
      return false;
    }
  }

  /// Get current user ID from token claims
  static Future<String?> getCurrentUserId() async {
    print('🔍 AuthService DEBUG: getCurrentUserId() called');
    final token = await getToken();
    print('🔍 AuthService DEBUG: Token exists: ${token != null}');
    if (token == null) {
      print('🔍 AuthService DEBUG: ❌ No token found');
      return null;
    }

    try {
      print('🔍 AuthService DEBUG: Decoding JWT token...');
      final parts = token.split('.');
      print('🔍 AuthService DEBUG: Token parts count: ${parts.length}');
      if (parts.length != 3) {
        print('🔍 AuthService DEBUG: ❌ Invalid token format - not 3 parts');
        return null;
      }

      print('🔍 AuthService DEBUG: Decoding payload (part 1)...');
      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      print('🔍 AuthService DEBUG: Token payload: $payload');

      final userId = payload['sub']?.toString();
      print('🔍 AuthService DEBUG: User ID from token (sub): $userId');
      
      // Also check for other possible user ID fields
      final userIdAlt = payload['user_id']?.toString();
      print('🔍 AuthService DEBUG: User ID from token (user_id): $userIdAlt');
      
      final userIdAlt2 = payload['id']?.toString();
      print('🔍 AuthService DEBUG: User ID from token (id): $userIdAlt2');

      return userId ?? userIdAlt ?? userIdAlt2;
    } catch (e) {
      print('🔍 AuthService DEBUG: ❌ Error decoding user ID from token: $e');
      return null;
    }
  }

  /// Get current user role from token claims
  static Future<String?> getCurrentUserRole() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );

      return payload['role']?.toString();
    } catch (e) {
      print('Error decoding user role from token: $e');
      return null;
    }
  }
}