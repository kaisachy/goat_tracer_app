import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/message.dart';
import 'auth_service.dart';

class MessageService {
  static final String _baseUrl = AppConfig.baseUrl;

  /// Get current farmer's message thread.
  static Future<List<MessageModel>> getMyMessages() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load messages (${response.statusCode})');
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
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
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
      final message =
          decoded is Map && decoded['message'] is String ? decoded['message'] as String : 'Failed to send message';
      throw Exception(message);
    }
  }

  /// Edit an existing message that belongs to the current user.
  static Future<void> editMessage(int id, String body) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/api/messages/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
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
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/messages/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
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


