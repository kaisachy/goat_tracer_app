import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../models/cattle.dart' as models;
import '../../db/app_database.dart';

class CattleLocalService {
	final AppDatabase db;

	CattleLocalService(this.db);

	Future<List<models.Cattle>> getAll() async {
		final rows = await (db.select(db.cattlesTable)).get();
		return rows.map(_mapCattle).toList();
	}

	Future<void> upsert(models.Cattle cattle) async {
		await db.into(db.cattlesTable).insertOnConflictUpdate(CattlesTableCompanion(
			id: Value(cattle.id),
			tagNo: Value(cattle.tagNo),
			dateOfBirth: Value(cattle.dateOfBirth),
			sex: Value(cattle.sex),
			weight: Value(cattle.weight),
			classification: Value(cattle.classification),
			status: Value(cattle.status),
			breed: Value(cattle.breed),
			groupName: Value(cattle.groupName),
			source: Value(cattle.source),
			sourceDetails: Value(cattle.sourceDetails),
			motherTag: Value(cattle.motherTag),
			fatherTag: Value(cattle.fatherTag),
			offspring: Value(cattle.offspring),
			notes: Value(cattle.notes),
			cattlePicture: Value(cattle.cattlePicture),
			age: Value(cattle.age),
			updatedAt: Value(DateTime.now()),
		));
	}

	Future<void> enqueueCreate(models.Cattle cattle) async {
		final id = const Uuid().v4();
		await db.enqueueChange(
			id: id,
			entity: 'cattles',
			operation: 'create',
			payload: cattle.toJson(),
		);
	}

	Future<void> enqueueUpdate(Map<String, dynamic> partial) async {
		final id = const Uuid().v4();
		await db.enqueueChange(
			id: id,
			entity: 'cattles',
			operation: 'update',
			payload: partial,
		);
	}

	models.Cattle _mapCattle(CattlesTableData r) {
		return models.Cattle(
			id: r.id,
			tagNo: r.tagNo,
			dateOfBirth: r.dateOfBirth,
			sex: r.sex,
			weight: r.weight,
			classification: r.classification,
			status: r.status,
			breed: r.breed,
			groupName: r.groupName,
			source: r.source,
			sourceDetails: r.sourceDetails,
			motherTag: r.motherTag,
			fatherTag: r.fatherTag,
			offspring: r.offspring,
			notes: r.notes,
			cattlePicture: r.cattlePicture,
			age: r.age,
		);
	}
}


