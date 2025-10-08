import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../models/cattle.dart';
import '../auth_service.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import 'cattle_local_service.dart';

class CattleService {
  static final String _baseUrl = AppConfig.baseUrl;
  static final AppDatabase _db = AppDatabase();
  static final CattleLocalService _local = CattleLocalService(_db);

  /// Get all cattle information
  static Future<List<Cattle>> getAllCattle() async {
    // Always serve from local DB for offline-first UX
    final localData = await _local.getAll();

    // Try to refresh from server in background; ignore failures
    final token = await AuthService.getToken();
    if (token != null) {
      () async {
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl/cattles'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final cattleList = List<Map<String, dynamic>>.from(data['data']);
            for (final item in cattleList) {
              await _local.upsert(Cattle.fromJson(item));
            }
          }
        } catch (_) {
          // ignore network errors for offline mode
        }
      }();
    }

    return localData;
  }

  /// Get cattle by tag number - Fixed implementation
  static Future<Cattle?> getCattleByTag(String tag) async {
    try {
      log('Attempting to get cattle by tag: $tag');

      // Get all cattle and find by tag (more reliable approach)
      final allCattle = await getAllCattle();

      if (allCattle.isEmpty) {
        log('No cattle found in database');
        return null;
      }

      // Try to find exact match first
      Cattle? foundCattle;
      try {
        foundCattle = allCattle.firstWhere(
              (cattle) => cattle.tagNo == tag,
        );
      } catch (e) {
        // If exact match fails, try case-insensitive match
        try {
          foundCattle = allCattle.firstWhere(
                (cattle) => cattle.tagNo.toLowerCase() == tag.toLowerCase(),
          );
        } catch (e2) {
          log('Cattle with tag $tag not found');
          return null;
        }
      }

      log('Found cattle: ${foundCattle.tagNo} - Gender: ${foundCattle.sex}');
      return foundCattle;

    } catch (e, stackTrace) {
      log('Error in getCattleByTag: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// Get cattle information as raw data (for backward compatibility)
  static Future<List<Map<String, dynamic>>> getCattleInformation() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        final local = await getAllCattle();
        return local.map((c) => c.toJson()).toList();
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        log('Failed to load cattle. Status code: ${response.statusCode}');
        // fallback to local
        final local = await getAllCattle();
        return local.map((c) => c.toJson()).toList();
      }
    } catch (e, stackTrace) {
      log('Error in getCattleInformation: $e', stackTrace: stackTrace);
      // fallback to local
      final local = await getAllCattle();
      return local.map((c) => c.toJson()).toList();
    }
  }

  /// Store/Create new cattle information with image support
  static Future<bool> storeCattleInformation(Map<String, dynamic> data) async {
    // Optimistic local write + enqueue outbox; network is optional
    final sanitizedData = Map<String, dynamic>.from(data);
    if (!sanitizedData.containsKey('id') || sanitizedData['id'] == null) {
      // Assign a temporary negative id for local persistence; server id will reconcile on pull
      sanitizedData['id'] = -DateTime.now().millisecondsSinceEpoch;
    }
    final localModel = Cattle.fromJson(sanitizedData);
    await _local.upsert(localModel);
    await _local.enqueueCreate(localModel);
    return true;
  }

  /// Update existing cattle information with image support
  // This method is already designed to handle the new logic because it accepts a generic map.
  // The UI will be responsible for populating this map with the necessary original and new parent tags.
  static Future<bool> updateCattleInformation(Map<String, dynamic> data) async {
    final sanitizedData = Map<String, dynamic>.from(data);
    // Apply locally
    try {
      final existing = await getCattleById(sanitizedData['id']);
      if (existing != null) {
        final updated = existing.copyWith(
          tagNo: sanitizedData['tag_no'],
          dateOfBirth: sanitizedData['date_of_birth'],
          sex: sanitizedData['sex'],
          weight: sanitizedData['weight'] == null ? null : double.tryParse(sanitizedData['weight'].toString()),
          classification: sanitizedData['classification'],
          status: sanitizedData['status'],
          breed: sanitizedData['breed'],
          groupName: sanitizedData['group_name'],
          source: sanitizedData['source'],
          sourceDetails: sanitizedData['source_details'],
          motherTag: sanitizedData['mother_tag'],
          fatherTag: sanitizedData['father_tag'],
          offspring: sanitizedData['offspring'],
          notes: sanitizedData['notes'],
          cattlePicture: sanitizedData['cattle_picture'],
        );
        await _local.upsert(updated);
      }
    } catch (_) {}
    // Enqueue change
    await _local.enqueueUpdate(sanitizedData);
    return true;
  }

  /// Update only the cattle picture
  static Future<bool> updateCattlePicture(int cattleId, String? base64Image) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Update picture failed: No token found.');
      return false;
    }

    final data = {
      'id': cattleId,
      'cattle_picture': base64Image,
    };

    return await updateCattleInformation(data);
  }

  /// Delete cattle picture only (set to null)
  static Future<bool> deleteCattlePicture(int cattleId) async {
    return await updateCattlePicture(cattleId, null);
  }

  /// Delete cattle information
  static Future<bool> deleteCattleInformation(int id) async {
    // Soft-delete locally and enqueue delete
    try {
      await (_db.update(_db.cattlesTable)..where((t) => t.id.equals(id))).write(
        CattlesTableCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (_) {}
    await _db.enqueueChange(
      id: 'delete-$id-${DateTime.now().millisecondsSinceEpoch}',
      entity: 'cattles',
      entityId: id.toString(),
      operation: 'delete',
      payload: {'id': id},
    );
    return true;
  }

  /// Alternative method to get cattle by ID (if needed)
  static Future<Cattle?> getCattleById(int id) async {
    try {
      // Get all cattle and find by ID
      log('Getting all cattle to find ID: $id');
      final allCattle = await getAllCattle();

      final foundCattle = allCattle.firstWhere(
            (cattle) => cattle.id == id,
        orElse: () => throw Exception('Cattle not found'),
      );

      log('Found cattle by ID: ${foundCattle.tagNo}');
      return foundCattle;
    } catch (e) {
      log('Error in getCattleById: $e');
      return null;
    }
  }

  /// Validate image size before upload
  static bool validateImageSize(String base64Image, {int maxSizeInMB = 5}) {
    try {
      // Calculate size in bytes
      final sizeInBytes = base64Image.length * (3 / 4);
      final sizeInMB = sizeInBytes / (1024 * 1024);

      log('Image size: ${sizeInMB.toStringAsFixed(2)} MB');

      return sizeInMB <= maxSizeInMB;
    } catch (e) {
      log('Error validating image size: $e');
      return false;
    }
  }

  /// Get cattle with full image data
  static Future<Cattle?> getCattleWithImage(int id) async {
    final cattle = await getCattleById(id);
    if (cattle != null) {
      log('Retrieved cattle with image data: ${cattle.tagNo}');
    }
    return cattle;
  }

  /// Archive a cattle record
  static Future<bool> archiveCattle(int id, String reason, {String? notes}) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Archive failed: No token found.');
      return false;
    }

    final data = {
      'id': id,
      'reason': reason,
      if (notes != null) 'notes': notes,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cattles/archive'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      log('Archive cattle response status: ${response.statusCode}');
      log('Archive cattle response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Cattle archived successfully.');
        return true;
      } else {
        log('Failed to archive cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in archiveCattle: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Unarchive a cattle record
  static Future<bool> unarchiveCattle(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('Unarchive failed: No token found.');
      return false;
    }

    final data = {
      'id': id,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cattles/unarchive'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      log('Unarchive cattle response status: ${response.statusCode}');
      log('Unarchive cattle response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Cattle unarchived successfully.');
        return true;
      } else {
        log('Failed to unarchive cattle. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in unarchiveCattle: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Get archived cattle
  static Future<List<Cattle>> getArchivedCattle() async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getArchivedCattle failed: No token found.');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/archived'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getArchivedCattle response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cattleList = List<Map<String, dynamic>>.from(data['data']);

        return cattleList.map((cattleData) => Cattle.fromJson(cattleData)).toList();
      } else {
        log('Failed to load archived cattle. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getArchivedCattle: $e', stackTrace: stackTrace);
    }

    return [];
  }

  /// Get family tree data for a specific cattle
  static Future<Map<String, dynamic>?> getFamilyTree(int cattleId) async {
    final token = await AuthService.getToken();

    if (token == null) {
      log('getFamilyTree failed: No token found.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cattles/family-tree/$cattleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('getFamilyTree response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['data']);
      } else {
        log('Failed to load family tree. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error in getFamilyTree: $e', stackTrace: stackTrace);
    }

    return null;
  }
}