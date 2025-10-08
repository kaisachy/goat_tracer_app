import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../db/app_database.dart';
import '../../models/schedule.dart' as models;

class ScheduleLocalService {
  final AppDatabase db;

  ScheduleLocalService(this.db);

  Future<List<models.Schedule>> getAll() async {
    final rows = await (db.select(db.schedulesTable)).get();
    return rows.map(_mapRow).toList();
  }

  Future<void> upsert(models.Schedule s) async {
    await db.into(db.schedulesTable).insertOnConflictUpdate(SchedulesTableCompanion(
      id: Value(s.id),
      userId: Value(s.userId),
      title: Value(s.title),
      cattleTag: Value(s.cattleTag),
      type: Value(s.type),
      scheduleDateTime: Value(s.scheduleDateTime),
      duration: Value(s.duration),
      reminder: Value(s.reminder),
      status: Value(s.status),
      scheduledBy: Value(s.scheduledBy),
      details: Value(s.details),
      vaccineType: Value(s.vaccineType),
      createdAt: Value(s.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> softDelete(int id) async {
    await (db.update(db.schedulesTable)..where((t) => t.id.equals(id))).write(
      SchedulesTableCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> enqueueCreate(models.Schedule s) async {
    final id = const Uuid().v4();
    await db.enqueueChange(
      id: id,
      entity: 'schedules',
      operation: 'create',
      payload: s.toApiJson(),
    );
  }

  Future<void> enqueueUpdate(Map<String, dynamic> partial) async {
    final id = const Uuid().v4();
    await db.enqueueChange(
      id: id,
      entity: 'schedules',
      operation: 'update',
      payload: partial,
    );
  }

  Future<void> enqueueDelete(int idToDelete) async {
    final id = const Uuid().v4();
    await db.enqueueChange(
      id: id,
      entity: 'schedules',
      operation: 'delete',
      payload: {'id': idToDelete},
    );
  }

  models.Schedule _mapRow(SchedulesTableData r) {
    return models.Schedule(
      id: r.id,
      userId: r.userId,
      title: r.title,
      cattleTag: r.cattleTag,
      type: r.type,
      scheduleDateTime: r.scheduleDateTime,
      duration: r.duration,
      reminder: r.reminder,
      status: r.status,
      scheduledBy: r.scheduledBy,
      details: r.details,
      vaccineType: r.vaccineType,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}


