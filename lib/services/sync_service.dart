import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class SyncService {
	final AppDatabase db;
	static final String _baseUrl = AppConfig.baseUrl;
	static SyncService? _instance;

	SyncService(this.db);

	static SyncService get instance {
		if (_instance == null) {
			throw Exception('SyncService not initialized. Call SyncService.initialize() first.');
		}
		return _instance!;
	}

	static Future<void> initialize(AppDatabase db) async {
		_instance = SyncService(db);
		await _instance!.startConnectivityListener();
	}

	Future<void> startConnectivityListener() async {
		// Check initial connectivity state
		final initialResult = await Connectivity().checkConnectivity();
		final hasInitialNetwork = initialResult.any((r) => r != ConnectivityResult.none);
		log('Initial connectivity: ${hasInitialNetwork ? "Connected" : "Disconnected"}');
		
		// If initially connected, trigger sync
		if (hasInitialNetwork) {
			log('Initial network detected, triggering sync in 3 seconds...');
			Future.delayed(Duration(seconds: 3), () async {
				await sync();
			});
		}
		
		// Listen for connectivity changes
		Connectivity().onConnectivityChanged.listen((results) async {
			final hasNetwork = results.any((r) => r != ConnectivityResult.none);
			log('Connectivity changed: ${hasNetwork ? "Connected" : "Disconnected"}');
			
			if (hasNetwork) {
				log('Network available, triggering sync in 3 seconds...');
				// Add a small delay to ensure network is stable
				await Future.delayed(Duration(seconds: 3));
				await sync();
			}
		});
	}

	Future<void> startListening() async {
		// This method is called from main.dart for compatibility
		await startConnectivityListener();
	}

	// Manual sync trigger for immediate sync after operations
	Future<void> triggerSync() async {
		log('triggerSync: Manual sync triggered');
		await sync();
	}

	Future<void> sync() async {
		final token = await AuthService.getToken();
		if (token == null) {
			log('sync: No token available, skipping sync');
			return;
		}

		log('sync: Starting sync process...');
		try {
			await _pushOutbox(token);
			await _pullChanges(token);
			log('sync: Sync completed successfully');
		} catch (e, st) {
			log('sync error: $e', stackTrace: st);
		}
	}

	Future<void> _pushOutbox(String token) async {
		final pending = await db.getPendingOutbox();
		for (final item in pending) {
			try {
				final uri = Uri.parse('$_baseUrl/sync/${item.entity}');
				final envelope = jsonEncode({
					'operation': item.operation,
					'data': jsonDecode(item.payload),
				});
				final res = await http.post(
					uri,
					headers: {
						'Content-Type': 'application/json',
						'Authorization': 'Bearer $token',
					},
					body: envelope,
				);
				if (res.statusCode >= 200 && res.statusCode < 300) {
					await db.markOutboxSuccess(item.id);
				} else {
					await db.markOutboxFailure(item.id, 'HTTP ${res.statusCode}: ${res.body}');
				}
			} catch (e) {
				await db.markOutboxFailure(item.id, e.toString());
			}
		}
	}

	Future<void> _pullChanges(String token) async {
		final since = await db.getMeta('lastSyncedAt');
		final uri = Uri.parse('$_baseUrl/changes?since=${Uri.encodeQueryComponent(since ?? '')}');
		final res = await http.get(uri, headers: {
			'Authorization': 'Bearer $token',
		});
		if (res.statusCode != 200) return;
		final body = jsonDecode(res.body) as Map<String, dynamic>;
		final serverNow = body['server_time'] as String?;
		final cattles = (body['cattles'] as List?) ?? [];
		final events = (body['events'] as List?) ?? [];
		final schedules = (body['schedules'] as List?) ?? [];
		final vaccs = (body['vaccination_schedules'] as List?) ?? [];

		await db.transaction(() async {
			for (final c in cattles.cast<Map>()) {
				final incomingId = (c['id'] as num).toInt();
				final incomingTag = (c['tag_no'] ?? '') as String;
				// Reconcile: if a local record exists with same tag but different id, replace it
				final existingWithTag = await (db.select(db.cattlesTable)..where((t) => t.tagNo.equals(incomingTag))).getSingleOrNull();
				if (existingWithTag != null && existingWithTag.id != incomingId) {
					await (db.delete(db.cattlesTable)..where((t) => t.id.equals(existingWithTag.id))).go();
				}
				await db.into(db.cattlesTable).insertOnConflictUpdate(CattlesTableCompanion(
					id: Value(incomingId),
					tagNo: Value(c['tag_no'] ?? ''),
					dateOfBirth: Value(c['date_of_birth']),
					sex: Value(c['sex'] ?? ''),
					weight: Value(c['weight'] == null ? null : (c['weight'] as num).toDouble()),
					classification: Value(c['classification'] ?? ''),
					status: Value(c['status'] ?? ''),
					breed: Value(c['breed']),
					groupName: Value(c['group_name']),
					source: Value(c['source'] ?? ''),
					sourceDetails: Value(c['source_details']),
					motherTag: Value(c['mother_tag']),
					fatherTag: Value(c['father_tag']),
					offspring: Value(c['offspring']),
					notes: Value(c['notes']),
					cattlePicture: Value(c['cattle_picture']),
					age: Value(c['age']),
					updatedAt: Value(_parseDateTime(c['updated_at'])),
					deletedAt: Value(_parseDateTime(c['deleted_at'])),
				));
			}
			for (final e in events.cast<Map>()) {
				await db.into(db.cattleEventsTable).insertOnConflictUpdate(CattleEventsTableCompanion(
					id: Value((e['id'] as num).toInt()),
					userId: Value((e['user_id'] as num).toInt()),
					cattleTag: Value(e['cattle_tag'] ?? ''),
					bullTag: Value(e['bull_tag']),
					calfTag: Value(e['calf_tag']),
					eventType: Value(e['event_type'] ?? ''),
					eventDate: Value(e['event_date'] ?? ''),
					sicknessSymptoms: Value(e['sickness_symptoms']),
					diagnosis: Value(e['diagnosis']),
					technician: Value(e['technician']),
					medicineGiven: Value(e['medicine_given']),
					semenUsed: Value(e['semen_used']),
					estimatedReturnDate: Value(e['estimated_return_date']),
					weighedResult: Value(e['weighed_result'] == null ? null : (e['weighed_result'] as num).toDouble()),
					breedingDate: Value(e['breeding_date']),
					expectedDeliveryDate: Value(e['expected_delivery_date']),
					notes: Value(e['notes']),
					lastKnownLocation: Value(e['last_known_location']),
					createdAt: Value(e['created_at']),
					updatedAt: Value(_parseDateTime(e['updated_at'])),
					deletedAt: Value(_parseDateTime(e['deleted_at'])),
				));
			}
			for (final s in schedules.cast<Map>()) {
				await db.into(db.schedulesTable).insertOnConflictUpdate(SchedulesTableCompanion(
					id: Value((s['id'] as num?)?.toInt()),
					userId: Value((s['user_id'] as num).toInt()),
					title: Value(s['title'] ?? ''),
					cattleTag: Value(s['cattle_tag']),
					type: Value(s['type'] ?? ''),
					scheduleDateTime: Value(_parseDateTime(s['schedule_datetime']) ?? DateTime.now()),
					duration: Value(s['duration']),
					reminder: Value(s['reminder']),
					status: Value(s['status'] ?? 'Scheduled'),
					scheduledBy: Value(s['scheduled_by']),
					details: Value(s['details']),
					vaccineType: Value(s['vaccine_type']),
					createdAt: Value(_parseDateTime(s['created_at'])),
					updatedAt: Value(_parseDateTime(s['updated_at'])),
					deletedAt: Value(_parseDateTime(s['deleted_at'])),
				));
			}
			for (final v in vaccs.cast<Map>()) {
				await db.into(db.vaccinationSchedulesTable).insertOnConflictUpdate(VaccinationSchedulesTableCompanion(
					id: Value((v['id'] as num?)?.toInt()),
					cattleTag: Value(v['cattle_tag'] ?? ''),
					vaccineType: Value(v['vaccine_type'] ?? ''),
					cattleStage: Value(v['cattle_stage'] ?? ''),
					recommendedDate: Value(_parseDateTime(v['recommended_date']) ?? DateTime.now()),
					actualDate: Value(_parseDateTime(v['actual_date'])),
					status: Value(v['status'] ?? 'Pending'),
					notes: Value(v['notes']),
					administeredBy: Value(v['administered_by']),
					createdAt: Value(_parseDateTime(v['created_at'])),
					updatedAt: Value(_parseDateTime(v['updated_at'])),
					deletedAt: Value(_parseDateTime(v['deleted_at'])),
				));
			}
			if (serverNow != null) {
				await db.setMeta('lastSyncedAt', serverNow);
			}
		});
	}

	DateTime? _parseDateTime(dynamic value) {
		if (value == null) return null;
		if (value is String && value.isNotEmpty) {
			try {
				if (value.contains(' ')) {
					return DateTime.parse(value.replaceFirst(' ', 'T'));
				}
				return DateTime.parse(value);
			} catch (_) {
				return null;
			}
		}
		return null;
	}
}


