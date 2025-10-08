import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../auth_service.dart';
import '../../db/app_database.dart';
import 'cattle_event_local_service.dart';

class CattleEventService {
  static final String _baseUrl = AppConfig.baseUrl;
  static final AppDatabase _db = AppDatabase();
  static final CattleEventLocalService _local = CattleEventLocalService(_db);

  static Future<List<Map<String, dynamic>>> getCattleEvent() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        // offline: return local
        return await _local.getAll();
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/event'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getCattleEvent Response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data']);
        // persist locally for offline
        for (final e in list) {
          await _local.upsert(e);
        }
        return list;
      } else {
        log('Failed to load cattle events. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
        return await _local.getAll();
      }
    } catch (e, stackTrace) {
      log('Error in getCattleEvent: $e', stackTrace: stackTrace);
      return await _local.getAll();
    }
  }

  static Future<bool> storeCattleEvent(Map<String, dynamic> data) async {
    // Offline-first: just enqueue and return success
    await _local.enqueueCreate(data);
    return true;
  }

  static Future<bool> updateCattleEvent(Map<String, dynamic> data) async {
    await _local.enqueueUpdate(data);
    return true;
  }

  static Future<bool> deleteCattleEvent(int id) async {
    await _local.enqueueDelete(id);
    return true;
  }

  /// Get cattle events by cattle tag
  static Future<List<Map<String, dynamic>>> getCattleEventsByTag(String cattleTag) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return await _local.getByTag(cattleTag);
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/event?cattle_tag=$cattleTag'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getCattleEventsByTag Response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data']);
        for (final e in list) { await _local.upsert(e); }
        return list;
      } else {
        log('Failed to load cattle events by tag. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
        return await _local.getByTag(cattleTag);
      }
    } catch (e, stackTrace) {
      log('Error in getCattleEventsByTag: $e', stackTrace: stackTrace);
      return await _local.getByTag(cattleTag);
    }
  }
}