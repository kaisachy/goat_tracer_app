// ignore_for_file: unnecessary_this
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class CattlesTable extends Table {
	IntColumn get id => integer()();
	TextColumn get tagNo => text()();
	TextColumn get dateOfBirth => text().nullable()();
	TextColumn get sex => text()();
	RealColumn get weight => real().nullable()();
	TextColumn get classification => text()();
	TextColumn get status => text()();
	TextColumn get breed => text().nullable()();
	TextColumn get groupName => text().nullable()();
	TextColumn get source => text()();
	TextColumn get sourceDetails => text().nullable()();
	TextColumn get motherTag => text().nullable()();
	TextColumn get fatherTag => text().nullable()();
	TextColumn get offspring => text().nullable()();
	TextColumn get notes => text().nullable()();
	TextColumn get cattlePicture => text().nullable()();
	TextColumn get age => text().nullable()();
	DateTimeColumn get updatedAt => dateTime().nullable()();
	DateTimeColumn get deletedAt => dateTime().nullable()();

	@override
	Set<Column> get primaryKey => {id};
}

class CattleEventsTable extends Table {
	IntColumn get id => integer()();
	IntColumn get userId => integer()();
	TextColumn get cattleTag => text()();
	TextColumn get bullTag => text().nullable()();
	TextColumn get calfTag => text().nullable()();
	TextColumn get eventType => text()();
	TextColumn get eventDate => text()();
	TextColumn get sicknessSymptoms => text().nullable()();
	TextColumn get diagnosis => text().nullable()();
	TextColumn get technician => text().nullable()();
	TextColumn get medicineGiven => text().nullable()();
	TextColumn get semenUsed => text().nullable()();
	TextColumn get estimatedReturnDate => text().nullable()();
	RealColumn get weighedResult => real().nullable()();
	TextColumn get breedingDate => text().nullable()();
	TextColumn get expectedDeliveryDate => text().nullable()();
	TextColumn get notes => text().nullable()();
	TextColumn get lastKnownLocation => text().nullable()();
	TextColumn get createdAt => text().nullable()();
	DateTimeColumn get updatedAt => dateTime().nullable()();
	DateTimeColumn get deletedAt => dateTime().nullable()();

	@override
	Set<Column> get primaryKey => {id};
}

class SchedulesTable extends Table {
	IntColumn get id => integer().nullable()();
	IntColumn get userId => integer()();
	TextColumn get title => text()();
	TextColumn get cattleTag => text().nullable()();
	TextColumn get type => text()();
	DateTimeColumn get scheduleDateTime => dateTime()();
	TextColumn get duration => text().nullable()();
	TextColumn get reminder => text().nullable()();
	TextColumn get status => text()();
	TextColumn get scheduledBy => text().nullable()();
	TextColumn get details => text().nullable()();
	TextColumn get vaccineType => text().nullable()();
	DateTimeColumn get createdAt => dateTime().nullable()();
	DateTimeColumn get updatedAt => dateTime().nullable()();
	DateTimeColumn get deletedAt => dateTime().nullable()();

	@override
	Set<Column> get primaryKey => {id};
}

class VaccinationSchedulesTable extends Table {
	IntColumn get id => integer().nullable()();
	TextColumn get cattleTag => text()();
	TextColumn get vaccineType => text()();
	TextColumn get cattleStage => text()();
	DateTimeColumn get recommendedDate => dateTime()();
	DateTimeColumn get actualDate => dateTime().nullable()();
	TextColumn get status => text()();
	TextColumn get notes => text().nullable()();
	TextColumn get administeredBy => text().nullable()();
	DateTimeColumn get createdAt => dateTime().nullable()();
	DateTimeColumn get updatedAt => dateTime().nullable()();
	DateTimeColumn get deletedAt => dateTime().nullable()();

	@override
	Set<Column> get primaryKey => {id};
}

class OutboxTable extends Table {
	TextColumn get id => text()(); // uuid
	TextColumn get entity => text()();
	TextColumn get entityId => text().nullable()();
	TextColumn get operation => text()(); // create|update|delete
	TextColumn get payload => text()(); // json string
	IntColumn get attemptCount => integer().withDefault(const Constant(0))();
	TextColumn get lastError => text().nullable()();
	DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
	DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

	@override
	Set<Column> get primaryKey => {id};
}

class MetaTable extends Table {
	TextColumn get key => text()();
	TextColumn get value => text()();

	@override
	Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [CattlesTable, CattleEventsTable, SchedulesTable, VaccinationSchedulesTable, OutboxTable, MetaTable])
class AppDatabase extends _$AppDatabase {
	AppDatabase() : super(_openConnection());

	@override
	int get schemaVersion => 1;

	// Simple key-value helpers
	Future<void> setMeta(String key, String value) async {
		await into(metaTable).insertOnConflictUpdate(MetaTableCompanion.insert(key: key, value: value));
	}

	Future<String?> getMeta(String key) async {
		final row = await (select(metaTable)..where((t) => t.key.equals(key))).getSingleOrNull();
		return row?.value;
	}

	// Outbox helpers
	Future<void> enqueueChange({required String id, required String entity, String? entityId, required String operation, required Map<String, dynamic> payload}) async {
		await into(outboxTable).insertOnConflictUpdate(OutboxTableCompanion(
			id: Value(id),
			entity: Value(entity),
			entityId: Value(entityId),
			operation: Value(operation),
			payload: Value(jsonEncode(payload)),
		));
	}

	Future<List<OutboxTableData>> getPendingOutbox() async {
		return await (select(outboxTable)..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
	}

	Future<void> markOutboxSuccess(String id) async {
		await (delete(outboxTable)..where((t) => t.id.equals(id))).go();
	}

	Future<void> markOutboxFailure(String id, String error) async {
		// Increment attempt_count atomically without relying on Value.increment
		await customUpdate(
			'UPDATE outbox_table SET attempt_count = attempt_count + 1, last_error = ?, updated_at = ? WHERE id = ?',
			variables: [
				Variable<String>(error),
				Variable<DateTime>(DateTime.now()),
				Variable<String>(id),
			],
		);
	}
}

LazyDatabase _openConnection() {
	return LazyDatabase(() async {
		final dir = await getApplicationDocumentsDirectory();
		final file = p.join(dir.path, 'cattle_tracer.db');
		return SqfliteQueryExecutor.inDatabaseFolder(path: file, logStatements: false);
	});
}


