import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    // Ensure token is properly cleaned before saving
    final cleaned = token.trim().replaceAll('\r', '').replaceAll('\n', '');
    await _storage.write(key: 'auth_token', value: cleaned);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;
    // Clean token on retrieval: remove any newlines/carriage returns that might have been added
    final cleaned = token.trim().replaceAll('\r', '').replaceAll('\n', '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Add these generic methods
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
}