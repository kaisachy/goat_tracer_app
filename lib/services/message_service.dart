import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/message.dart';
import 'auth_service.dart';

class MessageService {
  static final String _baseUrl = AppConfig.baseUrl;

  /// Helper to build headers that work with the production server
  /// (nginx/PHP-FPM sometimes strips the standard Authorization header).
  static Future<Map<String, String>> _authHeaders({
    bool includeContentType = true,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final cleanedToken = token.trim().replaceAll(RegExp(r'[\r\n]'), '');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $cleanedToken',
      // Workaround header used elsewhere in the app (e.g. GoatService)
      'X-Auth-Token': cleanedToken,
    };

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  /// Get current farmer's message thread.
  static Future<List<MessageModel>> getMyMessages() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/messages'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      // Try to surface backend message (e.g. "Authorization token is missing.")
      String message = 'Failed to load messages (${response.statusCode})';
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] is String) {
            message = decoded['message'] as String;
          }
        } catch (_) {}
      }
      throw Exception(message);
    }

    final data = jsonDecode(response.body);
    final list = (data['data'] as List<dynamic>? ?? []);
    return list
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Send a new message/note from farmer to admin.
  static Future<void> sendMessage(
    String body, {
    Uint8List? attachmentBytes,
    String? attachmentName,
    String? attachmentMime,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/messages'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'body': body,
        if (attachmentBytes != null && attachmentName != null)
          'attachment': base64Encode(attachmentBytes),
        if (attachmentName != null) 'attachment_name': attachmentName,
        if (attachmentMime != null) 'attachment_mime': attachmentMime,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final decoded =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Failed to send message';
      throw Exception(message);
    }
  }

  /// Edit an existing message that belongs to the current user.
  static Future<void> editMessage(int id, String body) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/messages/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({'body': body}),
    );

    if (response.statusCode != 200) {
      final decoded =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Failed to update message';
      throw Exception(message);
    }
  }

  /// Delete an existing message that belongs to the current user.
  static Future<void> deleteMessage(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/messages/$id'),
      headers: await _authHeaders(includeContentType: false),
    );

    if (response.statusCode != 200) {
      final decoded =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Failed to delete message';
      throw Exception(message);
    }
  }
}
