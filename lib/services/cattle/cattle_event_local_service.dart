import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../db/app_database.dart';

class CattleEventLocalService {
  final AppDatabase db;

  CattleEventLocalService(this.db);

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await (db.select(db.cattleEventsTable)).get();
    return rows.map((r) => _toMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getByTag(String cattleTag) async {
    final q = db.select(db.cattleEventsTable)
      ..where((t) => t.cattleTag.equals(cattleTag));
    final rows = await q.get();
    return rows.map((r) => _toMap(r)).toList();
  }

  Future<void> upsert(Map<String, dynamic> e) async {
    await db.into(db.cattleEventsTable).insertOnConflictUpdate(CattleEventsTableCompanion(
      id: e['id'] == null ? const Value.absent() : Value((e['id'] as num).toInt()),
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
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> enqueueCreate(Map<String, dynamic> payload) async {
    final id = const Uuid().v4();
    await db.enqueueChange(
      id: id,
      entity: 'events',
      operation: 'create',
      payload: payload,
    );
  }

  Future<void> enqueueUpdate(Map<String, dynamic> payload) async {
    final id = const Uuid().v4();
    await db.enqueueChange(
      id: id,
      entity: 'events',
      operation: 'update',
      payload: payload,
    );
  }

  Future<void> enqueueDelete(int idToDelete) async {
    final id = const Uuid().v4();
    await db.enqueueChange(
      id: id,
      entity: 'events',
      operation: 'delete',
      payload: {'id': idToDelete},
    );
  }

  Map<String, dynamic> _toMap(CattleEventsTableData r) {
    return {
      'id': r.id,
      'user_id': r.userId,
      'cattle_tag': r.cattleTag,
      'bull_tag': r.bullTag,
      'calf_tag': r.calfTag,
      'event_type': r.eventType,
      'event_date': r.eventDate,
      'sickness_symptoms': r.sicknessSymptoms,
      'diagnosis': r.diagnosis,
      'technician': r.technician,
      'medicine_given': r.medicineGiven,
      'semen_used': r.semenUsed,
      'estimated_return_date': r.estimatedReturnDate,
      'weighed_result': r.weighedResult,
      'breeding_date': r.breedingDate,
      'expected_delivery_date': r.expectedDeliveryDate,
      'notes': r.notes,
      'last_known_location': r.lastKnownLocation,
      'created_at': r.createdAt,
    };
  }
}


