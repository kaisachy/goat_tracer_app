// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CattlesTableTable extends CattlesTable
    with TableInfo<$CattlesTableTable, CattlesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CattlesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagNoMeta = const VerificationMeta('tagNo');
  @override
  late final GeneratedColumn<String> tagNo = GeneratedColumn<String>(
    'tag_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classificationMeta = const VerificationMeta(
    'classification',
  );
  @override
  late final GeneratedColumn<String> classification = GeneratedColumn<String>(
    'classification',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
    'breed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDetailsMeta = const VerificationMeta(
    'sourceDetails',
  );
  @override
  late final GeneratedColumn<String> sourceDetails = GeneratedColumn<String>(
    'source_details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _motherTagMeta = const VerificationMeta(
    'motherTag',
  );
  @override
  late final GeneratedColumn<String> motherTag = GeneratedColumn<String>(
    'mother_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatherTagMeta = const VerificationMeta(
    'fatherTag',
  );
  @override
  late final GeneratedColumn<String> fatherTag = GeneratedColumn<String>(
    'father_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offspringMeta = const VerificationMeta(
    'offspring',
  );
  @override
  late final GeneratedColumn<String> offspring = GeneratedColumn<String>(
    'offspring',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cattlePictureMeta = const VerificationMeta(
    'cattlePicture',
  );
  @override
  late final GeneratedColumn<String> cattlePicture = GeneratedColumn<String>(
    'cattle_picture',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<String> age = GeneratedColumn<String>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tagNo,
    dateOfBirth,
    sex,
    weight,
    classification,
    status,
    breed,
    groupName,
    source,
    sourceDetails,
    motherTag,
    fatherTag,
    offspring,
    notes,
    cattlePicture,
    age,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cattles_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CattlesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tag_no')) {
      context.handle(
        _tagNoMeta,
        tagNo.isAcceptableOrUnknown(data['tag_no']!, _tagNoMeta),
      );
    } else if (isInserting) {
      context.missing(_tagNoMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('classification')) {
      context.handle(
        _classificationMeta,
        classification.isAcceptableOrUnknown(
          data['classification']!,
          _classificationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classificationMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('breed')) {
      context.handle(
        _breedMeta,
        breed.isAcceptableOrUnknown(data['breed']!, _breedMeta),
      );
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_details')) {
      context.handle(
        _sourceDetailsMeta,
        sourceDetails.isAcceptableOrUnknown(
          data['source_details']!,
          _sourceDetailsMeta,
        ),
      );
    }
    if (data.containsKey('mother_tag')) {
      context.handle(
        _motherTagMeta,
        motherTag.isAcceptableOrUnknown(data['mother_tag']!, _motherTagMeta),
      );
    }
    if (data.containsKey('father_tag')) {
      context.handle(
        _fatherTagMeta,
        fatherTag.isAcceptableOrUnknown(data['father_tag']!, _fatherTagMeta),
      );
    }
    if (data.containsKey('offspring')) {
      context.handle(
        _offspringMeta,
        offspring.isAcceptableOrUnknown(data['offspring']!, _offspringMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('cattle_picture')) {
      context.handle(
        _cattlePictureMeta,
        cattlePicture.isAcceptableOrUnknown(
          data['cattle_picture']!,
          _cattlePictureMeta,
        ),
      );
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CattlesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CattlesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tagNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_no'],
      )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_of_birth'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      classification: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classification'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      breed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breed'],
      ),
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_details'],
      ),
      motherTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mother_tag'],
      ),
      fatherTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}father_tag'],
      ),
      offspring: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offspring'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      cattlePicture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cattle_picture'],
      ),
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CattlesTableTable createAlias(String alias) {
    return $CattlesTableTable(attachedDatabase, alias);
  }
}

class CattlesTableData extends DataClass
    implements Insertable<CattlesTableData> {
  final int id;
  final String tagNo;
  final String? dateOfBirth;
  final String sex;
  final double? weight;
  final String classification;
  final String status;
  final String? breed;
  final String? groupName;
  final String source;
  final String? sourceDetails;
  final String? motherTag;
  final String? fatherTag;
  final String? offspring;
  final String? notes;
  final String? cattlePicture;
  final String? age;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const CattlesTableData({
    required this.id,
    required this.tagNo,
    this.dateOfBirth,
    required this.sex,
    this.weight,
    required this.classification,
    required this.status,
    this.breed,
    this.groupName,
    required this.source,
    this.sourceDetails,
    this.motherTag,
    this.fatherTag,
    this.offspring,
    this.notes,
    this.cattlePicture,
    this.age,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tag_no'] = Variable<String>(tagNo);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>(dateOfBirth);
    }
    map['sex'] = Variable<String>(sex);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    map['classification'] = Variable<String>(classification);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceDetails != null) {
      map['source_details'] = Variable<String>(sourceDetails);
    }
    if (!nullToAbsent || motherTag != null) {
      map['mother_tag'] = Variable<String>(motherTag);
    }
    if (!nullToAbsent || fatherTag != null) {
      map['father_tag'] = Variable<String>(fatherTag);
    }
    if (!nullToAbsent || offspring != null) {
      map['offspring'] = Variable<String>(offspring);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || cattlePicture != null) {
      map['cattle_picture'] = Variable<String>(cattlePicture);
    }
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<String>(age);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CattlesTableCompanion toCompanion(bool nullToAbsent) {
    return CattlesTableCompanion(
      id: Value(id),
      tagNo: Value(tagNo),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      sex: Value(sex),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      classification: Value(classification),
      status: Value(status),
      breed: breed == null && nullToAbsent
          ? const Value.absent()
          : Value(breed),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      source: Value(source),
      sourceDetails: sourceDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceDetails),
      motherTag: motherTag == null && nullToAbsent
          ? const Value.absent()
          : Value(motherTag),
      fatherTag: fatherTag == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherTag),
      offspring: offspring == null && nullToAbsent
          ? const Value.absent()
          : Value(offspring),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      cattlePicture: cattlePicture == null && nullToAbsent
          ? const Value.absent()
          : Value(cattlePicture),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CattlesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CattlesTableData(
      id: serializer.fromJson<int>(json['id']),
      tagNo: serializer.fromJson<String>(json['tagNo']),
      dateOfBirth: serializer.fromJson<String?>(json['dateOfBirth']),
      sex: serializer.fromJson<String>(json['sex']),
      weight: serializer.fromJson<double?>(json['weight']),
      classification: serializer.fromJson<String>(json['classification']),
      status: serializer.fromJson<String>(json['status']),
      breed: serializer.fromJson<String?>(json['breed']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      source: serializer.fromJson<String>(json['source']),
      sourceDetails: serializer.fromJson<String?>(json['sourceDetails']),
      motherTag: serializer.fromJson<String?>(json['motherTag']),
      fatherTag: serializer.fromJson<String?>(json['fatherTag']),
      offspring: serializer.fromJson<String?>(json['offspring']),
      notes: serializer.fromJson<String?>(json['notes']),
      cattlePicture: serializer.fromJson<String?>(json['cattlePicture']),
      age: serializer.fromJson<String?>(json['age']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tagNo': serializer.toJson<String>(tagNo),
      'dateOfBirth': serializer.toJson<String?>(dateOfBirth),
      'sex': serializer.toJson<String>(sex),
      'weight': serializer.toJson<double?>(weight),
      'classification': serializer.toJson<String>(classification),
      'status': serializer.toJson<String>(status),
      'breed': serializer.toJson<String?>(breed),
      'groupName': serializer.toJson<String?>(groupName),
      'source': serializer.toJson<String>(source),
      'sourceDetails': serializer.toJson<String?>(sourceDetails),
      'motherTag': serializer.toJson<String?>(motherTag),
      'fatherTag': serializer.toJson<String?>(fatherTag),
      'offspring': serializer.toJson<String?>(offspring),
      'notes': serializer.toJson<String?>(notes),
      'cattlePicture': serializer.toJson<String?>(cattlePicture),
      'age': serializer.toJson<String?>(age),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CattlesTableData copyWith({
    int? id,
    String? tagNo,
    Value<String?> dateOfBirth = const Value.absent(),
    String? sex,
    Value<double?> weight = const Value.absent(),
    String? classification,
    String? status,
    Value<String?> breed = const Value.absent(),
    Value<String?> groupName = const Value.absent(),
    String? source,
    Value<String?> sourceDetails = const Value.absent(),
    Value<String?> motherTag = const Value.absent(),
    Value<String?> fatherTag = const Value.absent(),
    Value<String?> offspring = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> cattlePicture = const Value.absent(),
    Value<String?> age = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CattlesTableData(
    id: id ?? this.id,
    tagNo: tagNo ?? this.tagNo,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    sex: sex ?? this.sex,
    weight: weight.present ? weight.value : this.weight,
    classification: classification ?? this.classification,
    status: status ?? this.status,
    breed: breed.present ? breed.value : this.breed,
    groupName: groupName.present ? groupName.value : this.groupName,
    source: source ?? this.source,
    sourceDetails: sourceDetails.present
        ? sourceDetails.value
        : this.sourceDetails,
    motherTag: motherTag.present ? motherTag.value : this.motherTag,
    fatherTag: fatherTag.present ? fatherTag.value : this.fatherTag,
    offspring: offspring.present ? offspring.value : this.offspring,
    notes: notes.present ? notes.value : this.notes,
    cattlePicture: cattlePicture.present
        ? cattlePicture.value
        : this.cattlePicture,
    age: age.present ? age.value : this.age,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CattlesTableData copyWithCompanion(CattlesTableCompanion data) {
    return CattlesTableData(
      id: data.id.present ? data.id.value : this.id,
      tagNo: data.tagNo.present ? data.tagNo.value : this.tagNo,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      sex: data.sex.present ? data.sex.value : this.sex,
      weight: data.weight.present ? data.weight.value : this.weight,
      classification: data.classification.present
          ? data.classification.value
          : this.classification,
      status: data.status.present ? data.status.value : this.status,
      breed: data.breed.present ? data.breed.value : this.breed,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      source: data.source.present ? data.source.value : this.source,
      sourceDetails: data.sourceDetails.present
          ? data.sourceDetails.value
          : this.sourceDetails,
      motherTag: data.motherTag.present ? data.motherTag.value : this.motherTag,
      fatherTag: data.fatherTag.present ? data.fatherTag.value : this.fatherTag,
      offspring: data.offspring.present ? data.offspring.value : this.offspring,
      notes: data.notes.present ? data.notes.value : this.notes,
      cattlePicture: data.cattlePicture.present
          ? data.cattlePicture.value
          : this.cattlePicture,
      age: data.age.present ? data.age.value : this.age,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CattlesTableData(')
          ..write('id: $id, ')
          ..write('tagNo: $tagNo, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('sex: $sex, ')
          ..write('weight: $weight, ')
          ..write('classification: $classification, ')
          ..write('status: $status, ')
          ..write('breed: $breed, ')
          ..write('groupName: $groupName, ')
          ..write('source: $source, ')
          ..write('sourceDetails: $sourceDetails, ')
          ..write('motherTag: $motherTag, ')
          ..write('fatherTag: $fatherTag, ')
          ..write('offspring: $offspring, ')
          ..write('notes: $notes, ')
          ..write('cattlePicture: $cattlePicture, ')
          ..write('age: $age, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tagNo,
    dateOfBirth,
    sex,
    weight,
    classification,
    status,
    breed,
    groupName,
    source,
    sourceDetails,
    motherTag,
    fatherTag,
    offspring,
    notes,
    cattlePicture,
    age,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CattlesTableData &&
          other.id == this.id &&
          other.tagNo == this.tagNo &&
          other.dateOfBirth == this.dateOfBirth &&
          other.sex == this.sex &&
          other.weight == this.weight &&
          other.classification == this.classification &&
          other.status == this.status &&
          other.breed == this.breed &&
          other.groupName == this.groupName &&
          other.source == this.source &&
          other.sourceDetails == this.sourceDetails &&
          other.motherTag == this.motherTag &&
          other.fatherTag == this.fatherTag &&
          other.offspring == this.offspring &&
          other.notes == this.notes &&
          other.cattlePicture == this.cattlePicture &&
          other.age == this.age &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CattlesTableCompanion extends UpdateCompanion<CattlesTableData> {
  final Value<int> id;
  final Value<String> tagNo;
  final Value<String?> dateOfBirth;
  final Value<String> sex;
  final Value<double?> weight;
  final Value<String> classification;
  final Value<String> status;
  final Value<String?> breed;
  final Value<String?> groupName;
  final Value<String> source;
  final Value<String?> sourceDetails;
  final Value<String?> motherTag;
  final Value<String?> fatherTag;
  final Value<String?> offspring;
  final Value<String?> notes;
  final Value<String?> cattlePicture;
  final Value<String?> age;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  const CattlesTableCompanion({
    this.id = const Value.absent(),
    this.tagNo = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.sex = const Value.absent(),
    this.weight = const Value.absent(),
    this.classification = const Value.absent(),
    this.status = const Value.absent(),
    this.breed = const Value.absent(),
    this.groupName = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceDetails = const Value.absent(),
    this.motherTag = const Value.absent(),
    this.fatherTag = const Value.absent(),
    this.offspring = const Value.absent(),
    this.notes = const Value.absent(),
    this.cattlePicture = const Value.absent(),
    this.age = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CattlesTableCompanion.insert({
    this.id = const Value.absent(),
    required String tagNo,
    this.dateOfBirth = const Value.absent(),
    required String sex,
    this.weight = const Value.absent(),
    required String classification,
    required String status,
    this.breed = const Value.absent(),
    this.groupName = const Value.absent(),
    required String source,
    this.sourceDetails = const Value.absent(),
    this.motherTag = const Value.absent(),
    this.fatherTag = const Value.absent(),
    this.offspring = const Value.absent(),
    this.notes = const Value.absent(),
    this.cattlePicture = const Value.absent(),
    this.age = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : tagNo = Value(tagNo),
       sex = Value(sex),
       classification = Value(classification),
       status = Value(status),
       source = Value(source);
  static Insertable<CattlesTableData> custom({
    Expression<int>? id,
    Expression<String>? tagNo,
    Expression<String>? dateOfBirth,
    Expression<String>? sex,
    Expression<double>? weight,
    Expression<String>? classification,
    Expression<String>? status,
    Expression<String>? breed,
    Expression<String>? groupName,
    Expression<String>? source,
    Expression<String>? sourceDetails,
    Expression<String>? motherTag,
    Expression<String>? fatherTag,
    Expression<String>? offspring,
    Expression<String>? notes,
    Expression<String>? cattlePicture,
    Expression<String>? age,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tagNo != null) 'tag_no': tagNo,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (sex != null) 'sex': sex,
      if (weight != null) 'weight': weight,
      if (classification != null) 'classification': classification,
      if (status != null) 'status': status,
      if (breed != null) 'breed': breed,
      if (groupName != null) 'group_name': groupName,
      if (source != null) 'source': source,
      if (sourceDetails != null) 'source_details': sourceDetails,
      if (motherTag != null) 'mother_tag': motherTag,
      if (fatherTag != null) 'father_tag': fatherTag,
      if (offspring != null) 'offspring': offspring,
      if (notes != null) 'notes': notes,
      if (cattlePicture != null) 'cattle_picture': cattlePicture,
      if (age != null) 'age': age,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CattlesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? tagNo,
    Value<String?>? dateOfBirth,
    Value<String>? sex,
    Value<double?>? weight,
    Value<String>? classification,
    Value<String>? status,
    Value<String?>? breed,
    Value<String?>? groupName,
    Value<String>? source,
    Value<String?>? sourceDetails,
    Value<String?>? motherTag,
    Value<String?>? fatherTag,
    Value<String?>? offspring,
    Value<String?>? notes,
    Value<String?>? cattlePicture,
    Value<String?>? age,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return CattlesTableCompanion(
      id: id ?? this.id,
      tagNo: tagNo ?? this.tagNo,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      weight: weight ?? this.weight,
      classification: classification ?? this.classification,
      status: status ?? this.status,
      breed: breed ?? this.breed,
      groupName: groupName ?? this.groupName,
      source: source ?? this.source,
      sourceDetails: sourceDetails ?? this.sourceDetails,
      motherTag: motherTag ?? this.motherTag,
      fatherTag: fatherTag ?? this.fatherTag,
      offspring: offspring ?? this.offspring,
      notes: notes ?? this.notes,
      cattlePicture: cattlePicture ?? this.cattlePicture,
      age: age ?? this.age,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tagNo.present) {
      map['tag_no'] = Variable<String>(tagNo.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (classification.present) {
      map['classification'] = Variable<String>(classification.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceDetails.present) {
      map['source_details'] = Variable<String>(sourceDetails.value);
    }
    if (motherTag.present) {
      map['mother_tag'] = Variable<String>(motherTag.value);
    }
    if (fatherTag.present) {
      map['father_tag'] = Variable<String>(fatherTag.value);
    }
    if (offspring.present) {
      map['offspring'] = Variable<String>(offspring.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cattlePicture.present) {
      map['cattle_picture'] = Variable<String>(cattlePicture.value);
    }
    if (age.present) {
      map['age'] = Variable<String>(age.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CattlesTableCompanion(')
          ..write('id: $id, ')
          ..write('tagNo: $tagNo, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('sex: $sex, ')
          ..write('weight: $weight, ')
          ..write('classification: $classification, ')
          ..write('status: $status, ')
          ..write('breed: $breed, ')
          ..write('groupName: $groupName, ')
          ..write('source: $source, ')
          ..write('sourceDetails: $sourceDetails, ')
          ..write('motherTag: $motherTag, ')
          ..write('fatherTag: $fatherTag, ')
          ..write('offspring: $offspring, ')
          ..write('notes: $notes, ')
          ..write('cattlePicture: $cattlePicture, ')
          ..write('age: $age, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $CattleEventsTableTable extends CattleEventsTable
    with TableInfo<$CattleEventsTableTable, CattleEventsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CattleEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cattleTagMeta = const VerificationMeta(
    'cattleTag',
  );
  @override
  late final GeneratedColumn<String> cattleTag = GeneratedColumn<String>(
    'cattle_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bullTagMeta = const VerificationMeta(
    'bullTag',
  );
  @override
  late final GeneratedColumn<String> bullTag = GeneratedColumn<String>(
    'bull_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calfTagMeta = const VerificationMeta(
    'calfTag',
  );
  @override
  late final GeneratedColumn<String> calfTag = GeneratedColumn<String>(
    'calf_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventDateMeta = const VerificationMeta(
    'eventDate',
  );
  @override
  late final GeneratedColumn<String> eventDate = GeneratedColumn<String>(
    'event_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sicknessSymptomsMeta = const VerificationMeta(
    'sicknessSymptoms',
  );
  @override
  late final GeneratedColumn<String> sicknessSymptoms = GeneratedColumn<String>(
    'sickness_symptoms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diagnosisMeta = const VerificationMeta(
    'diagnosis',
  );
  @override
  late final GeneratedColumn<String> diagnosis = GeneratedColumn<String>(
    'diagnosis',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _technicianMeta = const VerificationMeta(
    'technician',
  );
  @override
  late final GeneratedColumn<String> technician = GeneratedColumn<String>(
    'technician',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicineGivenMeta = const VerificationMeta(
    'medicineGiven',
  );
  @override
  late final GeneratedColumn<String> medicineGiven = GeneratedColumn<String>(
    'medicine_given',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _semenUsedMeta = const VerificationMeta(
    'semenUsed',
  );
  @override
  late final GeneratedColumn<String> semenUsed = GeneratedColumn<String>(
    'semen_used',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedReturnDateMeta =
      const VerificationMeta('estimatedReturnDate');
  @override
  late final GeneratedColumn<String> estimatedReturnDate =
      GeneratedColumn<String>(
        'estimated_return_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _weighedResultMeta = const VerificationMeta(
    'weighedResult',
  );
  @override
  late final GeneratedColumn<double> weighedResult = GeneratedColumn<double>(
    'weighed_result',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _breedingDateMeta = const VerificationMeta(
    'breedingDate',
  );
  @override
  late final GeneratedColumn<String> breedingDate = GeneratedColumn<String>(
    'breeding_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedDeliveryDateMeta =
      const VerificationMeta('expectedDeliveryDate');
  @override
  late final GeneratedColumn<String> expectedDeliveryDate =
      GeneratedColumn<String>(
        'expected_delivery_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastKnownLocationMeta = const VerificationMeta(
    'lastKnownLocation',
  );
  @override
  late final GeneratedColumn<String> lastKnownLocation =
      GeneratedColumn<String>(
        'last_known_location',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    cattleTag,
    bullTag,
    calfTag,
    eventType,
    eventDate,
    sicknessSymptoms,
    diagnosis,
    technician,
    medicineGiven,
    semenUsed,
    estimatedReturnDate,
    weighedResult,
    breedingDate,
    expectedDeliveryDate,
    notes,
    lastKnownLocation,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cattle_events_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CattleEventsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('cattle_tag')) {
      context.handle(
        _cattleTagMeta,
        cattleTag.isAcceptableOrUnknown(data['cattle_tag']!, _cattleTagMeta),
      );
    } else if (isInserting) {
      context.missing(_cattleTagMeta);
    }
    if (data.containsKey('bull_tag')) {
      context.handle(
        _bullTagMeta,
        bullTag.isAcceptableOrUnknown(data['bull_tag']!, _bullTagMeta),
      );
    }
    if (data.containsKey('calf_tag')) {
      context.handle(
        _calfTagMeta,
        calfTag.isAcceptableOrUnknown(data['calf_tag']!, _calfTagMeta),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('event_date')) {
      context.handle(
        _eventDateMeta,
        eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta),
      );
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('sickness_symptoms')) {
      context.handle(
        _sicknessSymptomsMeta,
        sicknessSymptoms.isAcceptableOrUnknown(
          data['sickness_symptoms']!,
          _sicknessSymptomsMeta,
        ),
      );
    }
    if (data.containsKey('diagnosis')) {
      context.handle(
        _diagnosisMeta,
        diagnosis.isAcceptableOrUnknown(data['diagnosis']!, _diagnosisMeta),
      );
    }
    if (data.containsKey('technician')) {
      context.handle(
        _technicianMeta,
        technician.isAcceptableOrUnknown(data['technician']!, _technicianMeta),
      );
    }
    if (data.containsKey('medicine_given')) {
      context.handle(
        _medicineGivenMeta,
        medicineGiven.isAcceptableOrUnknown(
          data['medicine_given']!,
          _medicineGivenMeta,
        ),
      );
    }
    if (data.containsKey('semen_used')) {
      context.handle(
        _semenUsedMeta,
        semenUsed.isAcceptableOrUnknown(data['semen_used']!, _semenUsedMeta),
      );
    }
    if (data.containsKey('estimated_return_date')) {
      context.handle(
        _estimatedReturnDateMeta,
        estimatedReturnDate.isAcceptableOrUnknown(
          data['estimated_return_date']!,
          _estimatedReturnDateMeta,
        ),
      );
    }
    if (data.containsKey('weighed_result')) {
      context.handle(
        _weighedResultMeta,
        weighedResult.isAcceptableOrUnknown(
          data['weighed_result']!,
          _weighedResultMeta,
        ),
      );
    }
    if (data.containsKey('breeding_date')) {
      context.handle(
        _breedingDateMeta,
        breedingDate.isAcceptableOrUnknown(
          data['breeding_date']!,
          _breedingDateMeta,
        ),
      );
    }
    if (data.containsKey('expected_delivery_date')) {
      context.handle(
        _expectedDeliveryDateMeta,
        expectedDeliveryDate.isAcceptableOrUnknown(
          data['expected_delivery_date']!,
          _expectedDeliveryDateMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('last_known_location')) {
      context.handle(
        _lastKnownLocationMeta,
        lastKnownLocation.isAcceptableOrUnknown(
          data['last_known_location']!,
          _lastKnownLocationMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CattleEventsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CattleEventsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      cattleTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cattle_tag'],
      )!,
      bullTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bull_tag'],
      ),
      calfTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calf_tag'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_date'],
      )!,
      sicknessSymptoms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sickness_symptoms'],
      ),
      diagnosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis'],
      ),
      technician: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}technician'],
      ),
      medicineGiven: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicine_given'],
      ),
      semenUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semen_used'],
      ),
      estimatedReturnDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimated_return_date'],
      ),
      weighedResult: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weighed_result'],
      ),
      breedingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breeding_date'],
      ),
      expectedDeliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_delivery_date'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      lastKnownLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_known_location'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CattleEventsTableTable createAlias(String alias) {
    return $CattleEventsTableTable(attachedDatabase, alias);
  }
}

class CattleEventsTableData extends DataClass
    implements Insertable<CattleEventsTableData> {
  final int id;
  final int userId;
  final String cattleTag;
  final String? bullTag;
  final String? calfTag;
  final String eventType;
  final String eventDate;
  final String? sicknessSymptoms;
  final String? diagnosis;
  final String? technician;
  final String? medicineGiven;
  final String? semenUsed;
  final String? estimatedReturnDate;
  final double? weighedResult;
  final String? breedingDate;
  final String? expectedDeliveryDate;
  final String? notes;
  final String? lastKnownLocation;
  final String? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const CattleEventsTableData({
    required this.id,
    required this.userId,
    required this.cattleTag,
    this.bullTag,
    this.calfTag,
    required this.eventType,
    required this.eventDate,
    this.sicknessSymptoms,
    this.diagnosis,
    this.technician,
    this.medicineGiven,
    this.semenUsed,
    this.estimatedReturnDate,
    this.weighedResult,
    this.breedingDate,
    this.expectedDeliveryDate,
    this.notes,
    this.lastKnownLocation,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['cattle_tag'] = Variable<String>(cattleTag);
    if (!nullToAbsent || bullTag != null) {
      map['bull_tag'] = Variable<String>(bullTag);
    }
    if (!nullToAbsent || calfTag != null) {
      map['calf_tag'] = Variable<String>(calfTag);
    }
    map['event_type'] = Variable<String>(eventType);
    map['event_date'] = Variable<String>(eventDate);
    if (!nullToAbsent || sicknessSymptoms != null) {
      map['sickness_symptoms'] = Variable<String>(sicknessSymptoms);
    }
    if (!nullToAbsent || diagnosis != null) {
      map['diagnosis'] = Variable<String>(diagnosis);
    }
    if (!nullToAbsent || technician != null) {
      map['technician'] = Variable<String>(technician);
    }
    if (!nullToAbsent || medicineGiven != null) {
      map['medicine_given'] = Variable<String>(medicineGiven);
    }
    if (!nullToAbsent || semenUsed != null) {
      map['semen_used'] = Variable<String>(semenUsed);
    }
    if (!nullToAbsent || estimatedReturnDate != null) {
      map['estimated_return_date'] = Variable<String>(estimatedReturnDate);
    }
    if (!nullToAbsent || weighedResult != null) {
      map['weighed_result'] = Variable<double>(weighedResult);
    }
    if (!nullToAbsent || breedingDate != null) {
      map['breeding_date'] = Variable<String>(breedingDate);
    }
    if (!nullToAbsent || expectedDeliveryDate != null) {
      map['expected_delivery_date'] = Variable<String>(expectedDeliveryDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || lastKnownLocation != null) {
      map['last_known_location'] = Variable<String>(lastKnownLocation);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CattleEventsTableCompanion toCompanion(bool nullToAbsent) {
    return CattleEventsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      cattleTag: Value(cattleTag),
      bullTag: bullTag == null && nullToAbsent
          ? const Value.absent()
          : Value(bullTag),
      calfTag: calfTag == null && nullToAbsent
          ? const Value.absent()
          : Value(calfTag),
      eventType: Value(eventType),
      eventDate: Value(eventDate),
      sicknessSymptoms: sicknessSymptoms == null && nullToAbsent
          ? const Value.absent()
          : Value(sicknessSymptoms),
      diagnosis: diagnosis == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosis),
      technician: technician == null && nullToAbsent
          ? const Value.absent()
          : Value(technician),
      medicineGiven: medicineGiven == null && nullToAbsent
          ? const Value.absent()
          : Value(medicineGiven),
      semenUsed: semenUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(semenUsed),
      estimatedReturnDate: estimatedReturnDate == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedReturnDate),
      weighedResult: weighedResult == null && nullToAbsent
          ? const Value.absent()
          : Value(weighedResult),
      breedingDate: breedingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(breedingDate),
      expectedDeliveryDate: expectedDeliveryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedDeliveryDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      lastKnownLocation: lastKnownLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownLocation),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CattleEventsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CattleEventsTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      cattleTag: serializer.fromJson<String>(json['cattleTag']),
      bullTag: serializer.fromJson<String?>(json['bullTag']),
      calfTag: serializer.fromJson<String?>(json['calfTag']),
      eventType: serializer.fromJson<String>(json['eventType']),
      eventDate: serializer.fromJson<String>(json['eventDate']),
      sicknessSymptoms: serializer.fromJson<String?>(json['sicknessSymptoms']),
      diagnosis: serializer.fromJson<String?>(json['diagnosis']),
      technician: serializer.fromJson<String?>(json['technician']),
      medicineGiven: serializer.fromJson<String?>(json['medicineGiven']),
      semenUsed: serializer.fromJson<String?>(json['semenUsed']),
      estimatedReturnDate: serializer.fromJson<String?>(
        json['estimatedReturnDate'],
      ),
      weighedResult: serializer.fromJson<double?>(json['weighedResult']),
      breedingDate: serializer.fromJson<String?>(json['breedingDate']),
      expectedDeliveryDate: serializer.fromJson<String?>(
        json['expectedDeliveryDate'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      lastKnownLocation: serializer.fromJson<String?>(
        json['lastKnownLocation'],
      ),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'cattleTag': serializer.toJson<String>(cattleTag),
      'bullTag': serializer.toJson<String?>(bullTag),
      'calfTag': serializer.toJson<String?>(calfTag),
      'eventType': serializer.toJson<String>(eventType),
      'eventDate': serializer.toJson<String>(eventDate),
      'sicknessSymptoms': serializer.toJson<String?>(sicknessSymptoms),
      'diagnosis': serializer.toJson<String?>(diagnosis),
      'technician': serializer.toJson<String?>(technician),
      'medicineGiven': serializer.toJson<String?>(medicineGiven),
      'semenUsed': serializer.toJson<String?>(semenUsed),
      'estimatedReturnDate': serializer.toJson<String?>(estimatedReturnDate),
      'weighedResult': serializer.toJson<double?>(weighedResult),
      'breedingDate': serializer.toJson<String?>(breedingDate),
      'expectedDeliveryDate': serializer.toJson<String?>(expectedDeliveryDate),
      'notes': serializer.toJson<String?>(notes),
      'lastKnownLocation': serializer.toJson<String?>(lastKnownLocation),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CattleEventsTableData copyWith({
    int? id,
    int? userId,
    String? cattleTag,
    Value<String?> bullTag = const Value.absent(),
    Value<String?> calfTag = const Value.absent(),
    String? eventType,
    String? eventDate,
    Value<String?> sicknessSymptoms = const Value.absent(),
    Value<String?> diagnosis = const Value.absent(),
    Value<String?> technician = const Value.absent(),
    Value<String?> medicineGiven = const Value.absent(),
    Value<String?> semenUsed = const Value.absent(),
    Value<String?> estimatedReturnDate = const Value.absent(),
    Value<double?> weighedResult = const Value.absent(),
    Value<String?> breedingDate = const Value.absent(),
    Value<String?> expectedDeliveryDate = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> lastKnownLocation = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CattleEventsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    cattleTag: cattleTag ?? this.cattleTag,
    bullTag: bullTag.present ? bullTag.value : this.bullTag,
    calfTag: calfTag.present ? calfTag.value : this.calfTag,
    eventType: eventType ?? this.eventType,
    eventDate: eventDate ?? this.eventDate,
    sicknessSymptoms: sicknessSymptoms.present
        ? sicknessSymptoms.value
        : this.sicknessSymptoms,
    diagnosis: diagnosis.present ? diagnosis.value : this.diagnosis,
    technician: technician.present ? technician.value : this.technician,
    medicineGiven: medicineGiven.present
        ? medicineGiven.value
        : this.medicineGiven,
    semenUsed: semenUsed.present ? semenUsed.value : this.semenUsed,
    estimatedReturnDate: estimatedReturnDate.present
        ? estimatedReturnDate.value
        : this.estimatedReturnDate,
    weighedResult: weighedResult.present
        ? weighedResult.value
        : this.weighedResult,
    breedingDate: breedingDate.present ? breedingDate.value : this.breedingDate,
    expectedDeliveryDate: expectedDeliveryDate.present
        ? expectedDeliveryDate.value
        : this.expectedDeliveryDate,
    notes: notes.present ? notes.value : this.notes,
    lastKnownLocation: lastKnownLocation.present
        ? lastKnownLocation.value
        : this.lastKnownLocation,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CattleEventsTableData copyWithCompanion(CattleEventsTableCompanion data) {
    return CattleEventsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      cattleTag: data.cattleTag.present ? data.cattleTag.value : this.cattleTag,
      bullTag: data.bullTag.present ? data.bullTag.value : this.bullTag,
      calfTag: data.calfTag.present ? data.calfTag.value : this.calfTag,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      sicknessSymptoms: data.sicknessSymptoms.present
          ? data.sicknessSymptoms.value
          : this.sicknessSymptoms,
      diagnosis: data.diagnosis.present ? data.diagnosis.value : this.diagnosis,
      technician: data.technician.present
          ? data.technician.value
          : this.technician,
      medicineGiven: data.medicineGiven.present
          ? data.medicineGiven.value
          : this.medicineGiven,
      semenUsed: data.semenUsed.present ? data.semenUsed.value : this.semenUsed,
      estimatedReturnDate: data.estimatedReturnDate.present
          ? data.estimatedReturnDate.value
          : this.estimatedReturnDate,
      weighedResult: data.weighedResult.present
          ? data.weighedResult.value
          : this.weighedResult,
      breedingDate: data.breedingDate.present
          ? data.breedingDate.value
          : this.breedingDate,
      expectedDeliveryDate: data.expectedDeliveryDate.present
          ? data.expectedDeliveryDate.value
          : this.expectedDeliveryDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      lastKnownLocation: data.lastKnownLocation.present
          ? data.lastKnownLocation.value
          : this.lastKnownLocation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CattleEventsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cattleTag: $cattleTag, ')
          ..write('bullTag: $bullTag, ')
          ..write('calfTag: $calfTag, ')
          ..write('eventType: $eventType, ')
          ..write('eventDate: $eventDate, ')
          ..write('sicknessSymptoms: $sicknessSymptoms, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('technician: $technician, ')
          ..write('medicineGiven: $medicineGiven, ')
          ..write('semenUsed: $semenUsed, ')
          ..write('estimatedReturnDate: $estimatedReturnDate, ')
          ..write('weighedResult: $weighedResult, ')
          ..write('breedingDate: $breedingDate, ')
          ..write('expectedDeliveryDate: $expectedDeliveryDate, ')
          ..write('notes: $notes, ')
          ..write('lastKnownLocation: $lastKnownLocation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    cattleTag,
    bullTag,
    calfTag,
    eventType,
    eventDate,
    sicknessSymptoms,
    diagnosis,
    technician,
    medicineGiven,
    semenUsed,
    estimatedReturnDate,
    weighedResult,
    breedingDate,
    expectedDeliveryDate,
    notes,
    lastKnownLocation,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CattleEventsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.cattleTag == this.cattleTag &&
          other.bullTag == this.bullTag &&
          other.calfTag == this.calfTag &&
          other.eventType == this.eventType &&
          other.eventDate == this.eventDate &&
          other.sicknessSymptoms == this.sicknessSymptoms &&
          other.diagnosis == this.diagnosis &&
          other.technician == this.technician &&
          other.medicineGiven == this.medicineGiven &&
          other.semenUsed == this.semenUsed &&
          other.estimatedReturnDate == this.estimatedReturnDate &&
          other.weighedResult == this.weighedResult &&
          other.breedingDate == this.breedingDate &&
          other.expectedDeliveryDate == this.expectedDeliveryDate &&
          other.notes == this.notes &&
          other.lastKnownLocation == this.lastKnownLocation &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CattleEventsTableCompanion
    extends UpdateCompanion<CattleEventsTableData> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> cattleTag;
  final Value<String?> bullTag;
  final Value<String?> calfTag;
  final Value<String> eventType;
  final Value<String> eventDate;
  final Value<String?> sicknessSymptoms;
  final Value<String?> diagnosis;
  final Value<String?> technician;
  final Value<String?> medicineGiven;
  final Value<String?> semenUsed;
  final Value<String?> estimatedReturnDate;
  final Value<double?> weighedResult;
  final Value<String?> breedingDate;
  final Value<String?> expectedDeliveryDate;
  final Value<String?> notes;
  final Value<String?> lastKnownLocation;
  final Value<String?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  const CattleEventsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.cattleTag = const Value.absent(),
    this.bullTag = const Value.absent(),
    this.calfTag = const Value.absent(),
    this.eventType = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.sicknessSymptoms = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.technician = const Value.absent(),
    this.medicineGiven = const Value.absent(),
    this.semenUsed = const Value.absent(),
    this.estimatedReturnDate = const Value.absent(),
    this.weighedResult = const Value.absent(),
    this.breedingDate = const Value.absent(),
    this.expectedDeliveryDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.lastKnownLocation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CattleEventsTableCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String cattleTag,
    this.bullTag = const Value.absent(),
    this.calfTag = const Value.absent(),
    required String eventType,
    required String eventDate,
    this.sicknessSymptoms = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.technician = const Value.absent(),
    this.medicineGiven = const Value.absent(),
    this.semenUsed = const Value.absent(),
    this.estimatedReturnDate = const Value.absent(),
    this.weighedResult = const Value.absent(),
    this.breedingDate = const Value.absent(),
    this.expectedDeliveryDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.lastKnownLocation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : userId = Value(userId),
       cattleTag = Value(cattleTag),
       eventType = Value(eventType),
       eventDate = Value(eventDate);
  static Insertable<CattleEventsTableData> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? cattleTag,
    Expression<String>? bullTag,
    Expression<String>? calfTag,
    Expression<String>? eventType,
    Expression<String>? eventDate,
    Expression<String>? sicknessSymptoms,
    Expression<String>? diagnosis,
    Expression<String>? technician,
    Expression<String>? medicineGiven,
    Expression<String>? semenUsed,
    Expression<String>? estimatedReturnDate,
    Expression<double>? weighedResult,
    Expression<String>? breedingDate,
    Expression<String>? expectedDeliveryDate,
    Expression<String>? notes,
    Expression<String>? lastKnownLocation,
    Expression<String>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (cattleTag != null) 'cattle_tag': cattleTag,
      if (bullTag != null) 'bull_tag': bullTag,
      if (calfTag != null) 'calf_tag': calfTag,
      if (eventType != null) 'event_type': eventType,
      if (eventDate != null) 'event_date': eventDate,
      if (sicknessSymptoms != null) 'sickness_symptoms': sicknessSymptoms,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (technician != null) 'technician': technician,
      if (medicineGiven != null) 'medicine_given': medicineGiven,
      if (semenUsed != null) 'semen_used': semenUsed,
      if (estimatedReturnDate != null)
        'estimated_return_date': estimatedReturnDate,
      if (weighedResult != null) 'weighed_result': weighedResult,
      if (breedingDate != null) 'breeding_date': breedingDate,
      if (expectedDeliveryDate != null)
        'expected_delivery_date': expectedDeliveryDate,
      if (notes != null) 'notes': notes,
      if (lastKnownLocation != null) 'last_known_location': lastKnownLocation,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CattleEventsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? cattleTag,
    Value<String?>? bullTag,
    Value<String?>? calfTag,
    Value<String>? eventType,
    Value<String>? eventDate,
    Value<String?>? sicknessSymptoms,
    Value<String?>? diagnosis,
    Value<String?>? technician,
    Value<String?>? medicineGiven,
    Value<String?>? semenUsed,
    Value<String?>? estimatedReturnDate,
    Value<double?>? weighedResult,
    Value<String?>? breedingDate,
    Value<String?>? expectedDeliveryDate,
    Value<String?>? notes,
    Value<String?>? lastKnownLocation,
    Value<String?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return CattleEventsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cattleTag: cattleTag ?? this.cattleTag,
      bullTag: bullTag ?? this.bullTag,
      calfTag: calfTag ?? this.calfTag,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      sicknessSymptoms: sicknessSymptoms ?? this.sicknessSymptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      technician: technician ?? this.technician,
      medicineGiven: medicineGiven ?? this.medicineGiven,
      semenUsed: semenUsed ?? this.semenUsed,
      estimatedReturnDate: estimatedReturnDate ?? this.estimatedReturnDate,
      weighedResult: weighedResult ?? this.weighedResult,
      breedingDate: breedingDate ?? this.breedingDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      notes: notes ?? this.notes,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (cattleTag.present) {
      map['cattle_tag'] = Variable<String>(cattleTag.value);
    }
    if (bullTag.present) {
      map['bull_tag'] = Variable<String>(bullTag.value);
    }
    if (calfTag.present) {
      map['calf_tag'] = Variable<String>(calfTag.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<String>(eventDate.value);
    }
    if (sicknessSymptoms.present) {
      map['sickness_symptoms'] = Variable<String>(sicknessSymptoms.value);
    }
    if (diagnosis.present) {
      map['diagnosis'] = Variable<String>(diagnosis.value);
    }
    if (technician.present) {
      map['technician'] = Variable<String>(technician.value);
    }
    if (medicineGiven.present) {
      map['medicine_given'] = Variable<String>(medicineGiven.value);
    }
    if (semenUsed.present) {
      map['semen_used'] = Variable<String>(semenUsed.value);
    }
    if (estimatedReturnDate.present) {
      map['estimated_return_date'] = Variable<String>(
        estimatedReturnDate.value,
      );
    }
    if (weighedResult.present) {
      map['weighed_result'] = Variable<double>(weighedResult.value);
    }
    if (breedingDate.present) {
      map['breeding_date'] = Variable<String>(breedingDate.value);
    }
    if (expectedDeliveryDate.present) {
      map['expected_delivery_date'] = Variable<String>(
        expectedDeliveryDate.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (lastKnownLocation.present) {
      map['last_known_location'] = Variable<String>(lastKnownLocation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CattleEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cattleTag: $cattleTag, ')
          ..write('bullTag: $bullTag, ')
          ..write('calfTag: $calfTag, ')
          ..write('eventType: $eventType, ')
          ..write('eventDate: $eventDate, ')
          ..write('sicknessSymptoms: $sicknessSymptoms, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('technician: $technician, ')
          ..write('medicineGiven: $medicineGiven, ')
          ..write('semenUsed: $semenUsed, ')
          ..write('estimatedReturnDate: $estimatedReturnDate, ')
          ..write('weighedResult: $weighedResult, ')
          ..write('breedingDate: $breedingDate, ')
          ..write('expectedDeliveryDate: $expectedDeliveryDate, ')
          ..write('notes: $notes, ')
          ..write('lastKnownLocation: $lastKnownLocation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTableTable extends SchedulesTable
    with TableInfo<$SchedulesTableTable, SchedulesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cattleTagMeta = const VerificationMeta(
    'cattleTag',
  );
  @override
  late final GeneratedColumn<String> cattleTag = GeneratedColumn<String>(
    'cattle_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleDateTimeMeta = const VerificationMeta(
    'scheduleDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> scheduleDateTime =
      GeneratedColumn<DateTime>(
        'schedule_date_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<String> duration = GeneratedColumn<String>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMeta = const VerificationMeta(
    'reminder',
  );
  @override
  late final GeneratedColumn<String> reminder = GeneratedColumn<String>(
    'reminder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledByMeta = const VerificationMeta(
    'scheduledBy',
  );
  @override
  late final GeneratedColumn<String> scheduledBy = GeneratedColumn<String>(
    'scheduled_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vaccineTypeMeta = const VerificationMeta(
    'vaccineType',
  );
  @override
  late final GeneratedColumn<String> vaccineType = GeneratedColumn<String>(
    'vaccine_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    cattleTag,
    type,
    scheduleDateTime,
    duration,
    reminder,
    status,
    scheduledBy,
    details,
    vaccineType,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchedulesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cattle_tag')) {
      context.handle(
        _cattleTagMeta,
        cattleTag.isAcceptableOrUnknown(data['cattle_tag']!, _cattleTagMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('schedule_date_time')) {
      context.handle(
        _scheduleDateTimeMeta,
        scheduleDateTime.isAcceptableOrUnknown(
          data['schedule_date_time']!,
          _scheduleDateTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleDateTimeMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('reminder')) {
      context.handle(
        _reminderMeta,
        reminder.isAcceptableOrUnknown(data['reminder']!, _reminderMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('scheduled_by')) {
      context.handle(
        _scheduledByMeta,
        scheduledBy.isAcceptableOrUnknown(
          data['scheduled_by']!,
          _scheduledByMeta,
        ),
      );
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('vaccine_type')) {
      context.handle(
        _vaccineTypeMeta,
        vaccineType.isAcceptableOrUnknown(
          data['vaccine_type']!,
          _vaccineTypeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchedulesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchedulesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cattleTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cattle_tag'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      scheduleDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}schedule_date_time'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration'],
      ),
      reminder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scheduledBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_by'],
      ),
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      vaccineType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vaccine_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SchedulesTableTable createAlias(String alias) {
    return $SchedulesTableTable(attachedDatabase, alias);
  }
}

class SchedulesTableData extends DataClass
    implements Insertable<SchedulesTableData> {
  final int? id;
  final int userId;
  final String title;
  final String? cattleTag;
  final String type;
  final DateTime scheduleDateTime;
  final String? duration;
  final String? reminder;
  final String status;
  final String? scheduledBy;
  final String? details;
  final String? vaccineType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const SchedulesTableData({
    this.id,
    required this.userId,
    required this.title,
    this.cattleTag,
    required this.type,
    required this.scheduleDateTime,
    this.duration,
    this.reminder,
    required this.status,
    this.scheduledBy,
    this.details,
    this.vaccineType,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    map['user_id'] = Variable<int>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || cattleTag != null) {
      map['cattle_tag'] = Variable<String>(cattleTag);
    }
    map['type'] = Variable<String>(type);
    map['schedule_date_time'] = Variable<DateTime>(scheduleDateTime);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<String>(duration);
    }
    if (!nullToAbsent || reminder != null) {
      map['reminder'] = Variable<String>(reminder);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || scheduledBy != null) {
      map['scheduled_by'] = Variable<String>(scheduledBy);
    }
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    if (!nullToAbsent || vaccineType != null) {
      map['vaccine_type'] = Variable<String>(vaccineType);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SchedulesTableCompanion toCompanion(bool nullToAbsent) {
    return SchedulesTableCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      userId: Value(userId),
      title: Value(title),
      cattleTag: cattleTag == null && nullToAbsent
          ? const Value.absent()
          : Value(cattleTag),
      type: Value(type),
      scheduleDateTime: Value(scheduleDateTime),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      reminder: reminder == null && nullToAbsent
          ? const Value.absent()
          : Value(reminder),
      status: Value(status),
      scheduledBy: scheduledBy == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledBy),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      vaccineType: vaccineType == null && nullToAbsent
          ? const Value.absent()
          : Value(vaccineType),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SchedulesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchedulesTableData(
      id: serializer.fromJson<int?>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      cattleTag: serializer.fromJson<String?>(json['cattleTag']),
      type: serializer.fromJson<String>(json['type']),
      scheduleDateTime: serializer.fromJson<DateTime>(json['scheduleDateTime']),
      duration: serializer.fromJson<String?>(json['duration']),
      reminder: serializer.fromJson<String?>(json['reminder']),
      status: serializer.fromJson<String>(json['status']),
      scheduledBy: serializer.fromJson<String?>(json['scheduledBy']),
      details: serializer.fromJson<String?>(json['details']),
      vaccineType: serializer.fromJson<String?>(json['vaccineType']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'userId': serializer.toJson<int>(userId),
      'title': serializer.toJson<String>(title),
      'cattleTag': serializer.toJson<String?>(cattleTag),
      'type': serializer.toJson<String>(type),
      'scheduleDateTime': serializer.toJson<DateTime>(scheduleDateTime),
      'duration': serializer.toJson<String?>(duration),
      'reminder': serializer.toJson<String?>(reminder),
      'status': serializer.toJson<String>(status),
      'scheduledBy': serializer.toJson<String?>(scheduledBy),
      'details': serializer.toJson<String?>(details),
      'vaccineType': serializer.toJson<String?>(vaccineType),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SchedulesTableData copyWith({
    Value<int?> id = const Value.absent(),
    int? userId,
    String? title,
    Value<String?> cattleTag = const Value.absent(),
    String? type,
    DateTime? scheduleDateTime,
    Value<String?> duration = const Value.absent(),
    Value<String?> reminder = const Value.absent(),
    String? status,
    Value<String?> scheduledBy = const Value.absent(),
    Value<String?> details = const Value.absent(),
    Value<String?> vaccineType = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SchedulesTableData(
    id: id.present ? id.value : this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    cattleTag: cattleTag.present ? cattleTag.value : this.cattleTag,
    type: type ?? this.type,
    scheduleDateTime: scheduleDateTime ?? this.scheduleDateTime,
    duration: duration.present ? duration.value : this.duration,
    reminder: reminder.present ? reminder.value : this.reminder,
    status: status ?? this.status,
    scheduledBy: scheduledBy.present ? scheduledBy.value : this.scheduledBy,
    details: details.present ? details.value : this.details,
    vaccineType: vaccineType.present ? vaccineType.value : this.vaccineType,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SchedulesTableData copyWithCompanion(SchedulesTableCompanion data) {
    return SchedulesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      cattleTag: data.cattleTag.present ? data.cattleTag.value : this.cattleTag,
      type: data.type.present ? data.type.value : this.type,
      scheduleDateTime: data.scheduleDateTime.present
          ? data.scheduleDateTime.value
          : this.scheduleDateTime,
      duration: data.duration.present ? data.duration.value : this.duration,
      reminder: data.reminder.present ? data.reminder.value : this.reminder,
      status: data.status.present ? data.status.value : this.status,
      scheduledBy: data.scheduledBy.present
          ? data.scheduledBy.value
          : this.scheduledBy,
      details: data.details.present ? data.details.value : this.details,
      vaccineType: data.vaccineType.present
          ? data.vaccineType.value
          : this.vaccineType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('cattleTag: $cattleTag, ')
          ..write('type: $type, ')
          ..write('scheduleDateTime: $scheduleDateTime, ')
          ..write('duration: $duration, ')
          ..write('reminder: $reminder, ')
          ..write('status: $status, ')
          ..write('scheduledBy: $scheduledBy, ')
          ..write('details: $details, ')
          ..write('vaccineType: $vaccineType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    cattleTag,
    type,
    scheduleDateTime,
    duration,
    reminder,
    status,
    scheduledBy,
    details,
    vaccineType,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchedulesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.cattleTag == this.cattleTag &&
          other.type == this.type &&
          other.scheduleDateTime == this.scheduleDateTime &&
          other.duration == this.duration &&
          other.reminder == this.reminder &&
          other.status == this.status &&
          other.scheduledBy == this.scheduledBy &&
          other.details == this.details &&
          other.vaccineType == this.vaccineType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SchedulesTableCompanion extends UpdateCompanion<SchedulesTableData> {
  final Value<int?> id;
  final Value<int> userId;
  final Value<String> title;
  final Value<String?> cattleTag;
  final Value<String> type;
  final Value<DateTime> scheduleDateTime;
  final Value<String?> duration;
  final Value<String?> reminder;
  final Value<String> status;
  final Value<String?> scheduledBy;
  final Value<String?> details;
  final Value<String?> vaccineType;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  const SchedulesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.cattleTag = const Value.absent(),
    this.type = const Value.absent(),
    this.scheduleDateTime = const Value.absent(),
    this.duration = const Value.absent(),
    this.reminder = const Value.absent(),
    this.status = const Value.absent(),
    this.scheduledBy = const Value.absent(),
    this.details = const Value.absent(),
    this.vaccineType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  SchedulesTableCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String title,
    this.cattleTag = const Value.absent(),
    required String type,
    required DateTime scheduleDateTime,
    this.duration = const Value.absent(),
    this.reminder = const Value.absent(),
    required String status,
    this.scheduledBy = const Value.absent(),
    this.details = const Value.absent(),
    this.vaccineType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : userId = Value(userId),
       title = Value(title),
       type = Value(type),
       scheduleDateTime = Value(scheduleDateTime),
       status = Value(status);
  static Insertable<SchedulesTableData> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? title,
    Expression<String>? cattleTag,
    Expression<String>? type,
    Expression<DateTime>? scheduleDateTime,
    Expression<String>? duration,
    Expression<String>? reminder,
    Expression<String>? status,
    Expression<String>? scheduledBy,
    Expression<String>? details,
    Expression<String>? vaccineType,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (cattleTag != null) 'cattle_tag': cattleTag,
      if (type != null) 'type': type,
      if (scheduleDateTime != null) 'schedule_date_time': scheduleDateTime,
      if (duration != null) 'duration': duration,
      if (reminder != null) 'reminder': reminder,
      if (status != null) 'status': status,
      if (scheduledBy != null) 'scheduled_by': scheduledBy,
      if (details != null) 'details': details,
      if (vaccineType != null) 'vaccine_type': vaccineType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  SchedulesTableCompanion copyWith({
    Value<int?>? id,
    Value<int>? userId,
    Value<String>? title,
    Value<String?>? cattleTag,
    Value<String>? type,
    Value<DateTime>? scheduleDateTime,
    Value<String?>? duration,
    Value<String?>? reminder,
    Value<String>? status,
    Value<String?>? scheduledBy,
    Value<String?>? details,
    Value<String?>? vaccineType,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return SchedulesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      cattleTag: cattleTag ?? this.cattleTag,
      type: type ?? this.type,
      scheduleDateTime: scheduleDateTime ?? this.scheduleDateTime,
      duration: duration ?? this.duration,
      reminder: reminder ?? this.reminder,
      status: status ?? this.status,
      scheduledBy: scheduledBy ?? this.scheduledBy,
      details: details ?? this.details,
      vaccineType: vaccineType ?? this.vaccineType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cattleTag.present) {
      map['cattle_tag'] = Variable<String>(cattleTag.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (scheduleDateTime.present) {
      map['schedule_date_time'] = Variable<DateTime>(scheduleDateTime.value);
    }
    if (duration.present) {
      map['duration'] = Variable<String>(duration.value);
    }
    if (reminder.present) {
      map['reminder'] = Variable<String>(reminder.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scheduledBy.present) {
      map['scheduled_by'] = Variable<String>(scheduledBy.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (vaccineType.present) {
      map['vaccine_type'] = Variable<String>(vaccineType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('cattleTag: $cattleTag, ')
          ..write('type: $type, ')
          ..write('scheduleDateTime: $scheduleDateTime, ')
          ..write('duration: $duration, ')
          ..write('reminder: $reminder, ')
          ..write('status: $status, ')
          ..write('scheduledBy: $scheduledBy, ')
          ..write('details: $details, ')
          ..write('vaccineType: $vaccineType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $VaccinationSchedulesTableTable extends VaccinationSchedulesTable
    with
        TableInfo<
          $VaccinationSchedulesTableTable,
          VaccinationSchedulesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaccinationSchedulesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cattleTagMeta = const VerificationMeta(
    'cattleTag',
  );
  @override
  late final GeneratedColumn<String> cattleTag = GeneratedColumn<String>(
    'cattle_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vaccineTypeMeta = const VerificationMeta(
    'vaccineType',
  );
  @override
  late final GeneratedColumn<String> vaccineType = GeneratedColumn<String>(
    'vaccine_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cattleStageMeta = const VerificationMeta(
    'cattleStage',
  );
  @override
  late final GeneratedColumn<String> cattleStage = GeneratedColumn<String>(
    'cattle_stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendedDateMeta = const VerificationMeta(
    'recommendedDate',
  );
  @override
  late final GeneratedColumn<DateTime> recommendedDate =
      GeneratedColumn<DateTime>(
        'recommended_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _actualDateMeta = const VerificationMeta(
    'actualDate',
  );
  @override
  late final GeneratedColumn<DateTime> actualDate = GeneratedColumn<DateTime>(
    'actual_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _administeredByMeta = const VerificationMeta(
    'administeredBy',
  );
  @override
  late final GeneratedColumn<String> administeredBy = GeneratedColumn<String>(
    'administered_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cattleTag,
    vaccineType,
    cattleStage,
    recommendedDate,
    actualDate,
    status,
    notes,
    administeredBy,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vaccination_schedules_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaccinationSchedulesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cattle_tag')) {
      context.handle(
        _cattleTagMeta,
        cattleTag.isAcceptableOrUnknown(data['cattle_tag']!, _cattleTagMeta),
      );
    } else if (isInserting) {
      context.missing(_cattleTagMeta);
    }
    if (data.containsKey('vaccine_type')) {
      context.handle(
        _vaccineTypeMeta,
        vaccineType.isAcceptableOrUnknown(
          data['vaccine_type']!,
          _vaccineTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaccineTypeMeta);
    }
    if (data.containsKey('cattle_stage')) {
      context.handle(
        _cattleStageMeta,
        cattleStage.isAcceptableOrUnknown(
          data['cattle_stage']!,
          _cattleStageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cattleStageMeta);
    }
    if (data.containsKey('recommended_date')) {
      context.handle(
        _recommendedDateMeta,
        recommendedDate.isAcceptableOrUnknown(
          data['recommended_date']!,
          _recommendedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedDateMeta);
    }
    if (data.containsKey('actual_date')) {
      context.handle(
        _actualDateMeta,
        actualDate.isAcceptableOrUnknown(data['actual_date']!, _actualDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('administered_by')) {
      context.handle(
        _administeredByMeta,
        administeredBy.isAcceptableOrUnknown(
          data['administered_by']!,
          _administeredByMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaccinationSchedulesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaccinationSchedulesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      cattleTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cattle_tag'],
      )!,
      vaccineType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vaccine_type'],
      )!,
      cattleStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cattle_stage'],
      )!,
      recommendedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recommended_date'],
      )!,
      actualDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actual_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      administeredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}administered_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $VaccinationSchedulesTableTable createAlias(String alias) {
    return $VaccinationSchedulesTableTable(attachedDatabase, alias);
  }
}

class VaccinationSchedulesTableData extends DataClass
    implements Insertable<VaccinationSchedulesTableData> {
  final int? id;
  final String cattleTag;
  final String vaccineType;
  final String cattleStage;
  final DateTime recommendedDate;
  final DateTime? actualDate;
  final String status;
  final String? notes;
  final String? administeredBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const VaccinationSchedulesTableData({
    this.id,
    required this.cattleTag,
    required this.vaccineType,
    required this.cattleStage,
    required this.recommendedDate,
    this.actualDate,
    required this.status,
    this.notes,
    this.administeredBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    map['cattle_tag'] = Variable<String>(cattleTag);
    map['vaccine_type'] = Variable<String>(vaccineType);
    map['cattle_stage'] = Variable<String>(cattleStage);
    map['recommended_date'] = Variable<DateTime>(recommendedDate);
    if (!nullToAbsent || actualDate != null) {
      map['actual_date'] = Variable<DateTime>(actualDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || administeredBy != null) {
      map['administered_by'] = Variable<String>(administeredBy);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  VaccinationSchedulesTableCompanion toCompanion(bool nullToAbsent) {
    return VaccinationSchedulesTableCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      cattleTag: Value(cattleTag),
      vaccineType: Value(vaccineType),
      cattleStage: Value(cattleStage),
      recommendedDate: Value(recommendedDate),
      actualDate: actualDate == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDate),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      administeredBy: administeredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(administeredBy),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory VaccinationSchedulesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaccinationSchedulesTableData(
      id: serializer.fromJson<int?>(json['id']),
      cattleTag: serializer.fromJson<String>(json['cattleTag']),
      vaccineType: serializer.fromJson<String>(json['vaccineType']),
      cattleStage: serializer.fromJson<String>(json['cattleStage']),
      recommendedDate: serializer.fromJson<DateTime>(json['recommendedDate']),
      actualDate: serializer.fromJson<DateTime?>(json['actualDate']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      administeredBy: serializer.fromJson<String?>(json['administeredBy']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'cattleTag': serializer.toJson<String>(cattleTag),
      'vaccineType': serializer.toJson<String>(vaccineType),
      'cattleStage': serializer.toJson<String>(cattleStage),
      'recommendedDate': serializer.toJson<DateTime>(recommendedDate),
      'actualDate': serializer.toJson<DateTime?>(actualDate),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'administeredBy': serializer.toJson<String?>(administeredBy),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  VaccinationSchedulesTableData copyWith({
    Value<int?> id = const Value.absent(),
    String? cattleTag,
    String? vaccineType,
    String? cattleStage,
    DateTime? recommendedDate,
    Value<DateTime?> actualDate = const Value.absent(),
    String? status,
    Value<String?> notes = const Value.absent(),
    Value<String?> administeredBy = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => VaccinationSchedulesTableData(
    id: id.present ? id.value : this.id,
    cattleTag: cattleTag ?? this.cattleTag,
    vaccineType: vaccineType ?? this.vaccineType,
    cattleStage: cattleStage ?? this.cattleStage,
    recommendedDate: recommendedDate ?? this.recommendedDate,
    actualDate: actualDate.present ? actualDate.value : this.actualDate,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    administeredBy: administeredBy.present
        ? administeredBy.value
        : this.administeredBy,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  VaccinationSchedulesTableData copyWithCompanion(
    VaccinationSchedulesTableCompanion data,
  ) {
    return VaccinationSchedulesTableData(
      id: data.id.present ? data.id.value : this.id,
      cattleTag: data.cattleTag.present ? data.cattleTag.value : this.cattleTag,
      vaccineType: data.vaccineType.present
          ? data.vaccineType.value
          : this.vaccineType,
      cattleStage: data.cattleStage.present
          ? data.cattleStage.value
          : this.cattleStage,
      recommendedDate: data.recommendedDate.present
          ? data.recommendedDate.value
          : this.recommendedDate,
      actualDate: data.actualDate.present
          ? data.actualDate.value
          : this.actualDate,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      administeredBy: data.administeredBy.present
          ? data.administeredBy.value
          : this.administeredBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaccinationSchedulesTableData(')
          ..write('id: $id, ')
          ..write('cattleTag: $cattleTag, ')
          ..write('vaccineType: $vaccineType, ')
          ..write('cattleStage: $cattleStage, ')
          ..write('recommendedDate: $recommendedDate, ')
          ..write('actualDate: $actualDate, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('administeredBy: $administeredBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cattleTag,
    vaccineType,
    cattleStage,
    recommendedDate,
    actualDate,
    status,
    notes,
    administeredBy,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaccinationSchedulesTableData &&
          other.id == this.id &&
          other.cattleTag == this.cattleTag &&
          other.vaccineType == this.vaccineType &&
          other.cattleStage == this.cattleStage &&
          other.recommendedDate == this.recommendedDate &&
          other.actualDate == this.actualDate &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.administeredBy == this.administeredBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class VaccinationSchedulesTableCompanion
    extends UpdateCompanion<VaccinationSchedulesTableData> {
  final Value<int?> id;
  final Value<String> cattleTag;
  final Value<String> vaccineType;
  final Value<String> cattleStage;
  final Value<DateTime> recommendedDate;
  final Value<DateTime?> actualDate;
  final Value<String> status;
  final Value<String?> notes;
  final Value<String?> administeredBy;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  const VaccinationSchedulesTableCompanion({
    this.id = const Value.absent(),
    this.cattleTag = const Value.absent(),
    this.vaccineType = const Value.absent(),
    this.cattleStage = const Value.absent(),
    this.recommendedDate = const Value.absent(),
    this.actualDate = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.administeredBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  VaccinationSchedulesTableCompanion.insert({
    this.id = const Value.absent(),
    required String cattleTag,
    required String vaccineType,
    required String cattleStage,
    required DateTime recommendedDate,
    this.actualDate = const Value.absent(),
    required String status,
    this.notes = const Value.absent(),
    this.administeredBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : cattleTag = Value(cattleTag),
       vaccineType = Value(vaccineType),
       cattleStage = Value(cattleStage),
       recommendedDate = Value(recommendedDate),
       status = Value(status);
  static Insertable<VaccinationSchedulesTableData> custom({
    Expression<int>? id,
    Expression<String>? cattleTag,
    Expression<String>? vaccineType,
    Expression<String>? cattleStage,
    Expression<DateTime>? recommendedDate,
    Expression<DateTime>? actualDate,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? administeredBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cattleTag != null) 'cattle_tag': cattleTag,
      if (vaccineType != null) 'vaccine_type': vaccineType,
      if (cattleStage != null) 'cattle_stage': cattleStage,
      if (recommendedDate != null) 'recommended_date': recommendedDate,
      if (actualDate != null) 'actual_date': actualDate,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (administeredBy != null) 'administered_by': administeredBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  VaccinationSchedulesTableCompanion copyWith({
    Value<int?>? id,
    Value<String>? cattleTag,
    Value<String>? vaccineType,
    Value<String>? cattleStage,
    Value<DateTime>? recommendedDate,
    Value<DateTime?>? actualDate,
    Value<String>? status,
    Value<String?>? notes,
    Value<String?>? administeredBy,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return VaccinationSchedulesTableCompanion(
      id: id ?? this.id,
      cattleTag: cattleTag ?? this.cattleTag,
      vaccineType: vaccineType ?? this.vaccineType,
      cattleStage: cattleStage ?? this.cattleStage,
      recommendedDate: recommendedDate ?? this.recommendedDate,
      actualDate: actualDate ?? this.actualDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      administeredBy: administeredBy ?? this.administeredBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cattleTag.present) {
      map['cattle_tag'] = Variable<String>(cattleTag.value);
    }
    if (vaccineType.present) {
      map['vaccine_type'] = Variable<String>(vaccineType.value);
    }
    if (cattleStage.present) {
      map['cattle_stage'] = Variable<String>(cattleStage.value);
    }
    if (recommendedDate.present) {
      map['recommended_date'] = Variable<DateTime>(recommendedDate.value);
    }
    if (actualDate.present) {
      map['actual_date'] = Variable<DateTime>(actualDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (administeredBy.present) {
      map['administered_by'] = Variable<String>(administeredBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaccinationSchedulesTableCompanion(')
          ..write('id: $id, ')
          ..write('cattleTag: $cattleTag, ')
          ..write('vaccineType: $vaccineType, ')
          ..write('cattleStage: $cattleStage, ')
          ..write('recommendedDate: $recommendedDate, ')
          ..write('actualDate: $actualDate, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('administeredBy: $administeredBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $OutboxTableTable extends OutboxTable
    with TableInfo<$OutboxTableTable, OutboxTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    entityId,
    operation,
    payload,
    attemptCount,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OutboxTableTable createAlias(String alias) {
    return $OutboxTableTable(attachedDatabase, alias);
  }
}

class OutboxTableData extends DataClass implements Insertable<OutboxTableData> {
  final String id;
  final String entity;
  final String? entityId;
  final String operation;
  final String payload;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OutboxTableData({
    required this.id,
    required this.entity,
    this.entityId,
    required this.operation,
    required this.payload,
    required this.attemptCount,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity'] = Variable<String>(entity);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxTableCompanion toCompanion(bool nullToAbsent) {
    return OutboxTableCompanion(
      id: Value(id),
      entity: Value(entity),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxTableData(
      id: serializer.fromJson<String>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String?>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxTableData copyWith({
    String? id,
    String? entity,
    Value<String?> entityId = const Value.absent(),
    String? operation,
    String? payload,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OutboxTableData(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    entityId: entityId.present ? entityId.value : this.entityId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OutboxTableData copyWithCompanion(OutboxTableCompanion data) {
    return OutboxTableData(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxTableData(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entity,
    entityId,
    operation,
    payload,
    attemptCount,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxTableData &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxTableCompanion extends UpdateCompanion<OutboxTableData> {
  final Value<String> id;
  final Value<String> entity;
  final Value<String?> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutboxTableCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxTableCompanion.insert({
    required String id,
    required String entity,
    this.entityId = const Value.absent(),
    required String operation,
    required String payload,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entity = Value(entity),
       operation = Value(operation),
       payload = Value(payload);
  static Insertable<OutboxTableData> custom({
    Expression<String>? id,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxTableCompanion copyWith({
    Value<String>? id,
    Value<String>? entity,
    Value<String?>? entityId,
    Value<String>? operation,
    Value<String>? payload,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OutboxTableCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaTableTable extends MetaTable
    with TableInfo<$MetaTableTable, MetaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaTableTable createAlias(String alias) {
    return $MetaTableTable(attachedDatabase, alias);
  }
}

class MetaTableData extends DataClass implements Insertable<MetaTableData> {
  final String key;
  final String value;
  const MetaTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaTableCompanion toCompanion(bool nullToAbsent) {
    return MetaTableCompanion(key: Value(key), value: Value(value));
  }

  factory MetaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaTableData copyWith({String? key, String? value}) =>
      MetaTableData(key: key ?? this.key, value: value ?? this.value);
  MetaTableData copyWithCompanion(MetaTableCompanion data) {
    return MetaTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class MetaTableCompanion extends UpdateCompanion<MetaTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CattlesTableTable cattlesTable = $CattlesTableTable(this);
  late final $CattleEventsTableTable cattleEventsTable =
      $CattleEventsTableTable(this);
  late final $SchedulesTableTable schedulesTable = $SchedulesTableTable(this);
  late final $VaccinationSchedulesTableTable vaccinationSchedulesTable =
      $VaccinationSchedulesTableTable(this);
  late final $OutboxTableTable outboxTable = $OutboxTableTable(this);
  late final $MetaTableTable metaTable = $MetaTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cattlesTable,
    cattleEventsTable,
    schedulesTable,
    vaccinationSchedulesTable,
    outboxTable,
    metaTable,
  ];
}

typedef $$CattlesTableTableCreateCompanionBuilder =
    CattlesTableCompanion Function({
      Value<int> id,
      required String tagNo,
      Value<String?> dateOfBirth,
      required String sex,
      Value<double?> weight,
      required String classification,
      required String status,
      Value<String?> breed,
      Value<String?> groupName,
      required String source,
      Value<String?> sourceDetails,
      Value<String?> motherTag,
      Value<String?> fatherTag,
      Value<String?> offspring,
      Value<String?> notes,
      Value<String?> cattlePicture,
      Value<String?> age,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$CattlesTableTableUpdateCompanionBuilder =
    CattlesTableCompanion Function({
      Value<int> id,
      Value<String> tagNo,
      Value<String?> dateOfBirth,
      Value<String> sex,
      Value<double?> weight,
      Value<String> classification,
      Value<String> status,
      Value<String?> breed,
      Value<String?> groupName,
      Value<String> source,
      Value<String?> sourceDetails,
      Value<String?> motherTag,
      Value<String?> fatherTag,
      Value<String?> offspring,
      Value<String?> notes,
      Value<String?> cattlePicture,
      Value<String?> age,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });

class $$CattlesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CattlesTableTable> {
  $$CattlesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagNo => $composableBuilder(
    column: $table.tagNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDetails => $composableBuilder(
    column: $table.sourceDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motherTag => $composableBuilder(
    column: $table.motherTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fatherTag => $composableBuilder(
    column: $table.fatherTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offspring => $composableBuilder(
    column: $table.offspring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cattlePicture => $composableBuilder(
    column: $table.cattlePicture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CattlesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CattlesTableTable> {
  $$CattlesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagNo => $composableBuilder(
    column: $table.tagNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDetails => $composableBuilder(
    column: $table.sourceDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motherTag => $composableBuilder(
    column: $table.motherTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fatherTag => $composableBuilder(
    column: $table.fatherTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offspring => $composableBuilder(
    column: $table.offspring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cattlePicture => $composableBuilder(
    column: $table.cattlePicture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CattlesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CattlesTableTable> {
  $$CattlesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tagNo =>
      $composableBuilder(column: $table.tagNo, builder: (column) => column);

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceDetails => $composableBuilder(
    column: $table.sourceDetails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motherTag =>
      $composableBuilder(column: $table.motherTag, builder: (column) => column);

  GeneratedColumn<String> get fatherTag =>
      $composableBuilder(column: $table.fatherTag, builder: (column) => column);

  GeneratedColumn<String> get offspring =>
      $composableBuilder(column: $table.offspring, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get cattlePicture => $composableBuilder(
    column: $table.cattlePicture,
    builder: (column) => column,
  );

  GeneratedColumn<String> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CattlesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CattlesTableTable,
          CattlesTableData,
          $$CattlesTableTableFilterComposer,
          $$CattlesTableTableOrderingComposer,
          $$CattlesTableTableAnnotationComposer,
          $$CattlesTableTableCreateCompanionBuilder,
          $$CattlesTableTableUpdateCompanionBuilder,
          (
            CattlesTableData,
            BaseReferences<_$AppDatabase, $CattlesTableTable, CattlesTableData>,
          ),
          CattlesTableData,
          PrefetchHooks Function()
        > {
  $$CattlesTableTableTableManager(_$AppDatabase db, $CattlesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CattlesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CattlesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CattlesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tagNo = const Value.absent(),
                Value<String?> dateOfBirth = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<String> classification = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceDetails = const Value.absent(),
                Value<String?> motherTag = const Value.absent(),
                Value<String?> fatherTag = const Value.absent(),
                Value<String?> offspring = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> cattlePicture = const Value.absent(),
                Value<String?> age = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CattlesTableCompanion(
                id: id,
                tagNo: tagNo,
                dateOfBirth: dateOfBirth,
                sex: sex,
                weight: weight,
                classification: classification,
                status: status,
                breed: breed,
                groupName: groupName,
                source: source,
                sourceDetails: sourceDetails,
                motherTag: motherTag,
                fatherTag: fatherTag,
                offspring: offspring,
                notes: notes,
                cattlePicture: cattlePicture,
                age: age,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tagNo,
                Value<String?> dateOfBirth = const Value.absent(),
                required String sex,
                Value<double?> weight = const Value.absent(),
                required String classification,
                required String status,
                Value<String?> breed = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                required String source,
                Value<String?> sourceDetails = const Value.absent(),
                Value<String?> motherTag = const Value.absent(),
                Value<String?> fatherTag = const Value.absent(),
                Value<String?> offspring = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> cattlePicture = const Value.absent(),
                Value<String?> age = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CattlesTableCompanion.insert(
                id: id,
                tagNo: tagNo,
                dateOfBirth: dateOfBirth,
                sex: sex,
                weight: weight,
                classification: classification,
                status: status,
                breed: breed,
                groupName: groupName,
                source: source,
                sourceDetails: sourceDetails,
                motherTag: motherTag,
                fatherTag: fatherTag,
                offspring: offspring,
                notes: notes,
                cattlePicture: cattlePicture,
                age: age,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CattlesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CattlesTableTable,
      CattlesTableData,
      $$CattlesTableTableFilterComposer,
      $$CattlesTableTableOrderingComposer,
      $$CattlesTableTableAnnotationComposer,
      $$CattlesTableTableCreateCompanionBuilder,
      $$CattlesTableTableUpdateCompanionBuilder,
      (
        CattlesTableData,
        BaseReferences<_$AppDatabase, $CattlesTableTable, CattlesTableData>,
      ),
      CattlesTableData,
      PrefetchHooks Function()
    >;
typedef $$CattleEventsTableTableCreateCompanionBuilder =
    CattleEventsTableCompanion Function({
      Value<int> id,
      required int userId,
      required String cattleTag,
      Value<String?> bullTag,
      Value<String?> calfTag,
      required String eventType,
      required String eventDate,
      Value<String?> sicknessSymptoms,
      Value<String?> diagnosis,
      Value<String?> technician,
      Value<String?> medicineGiven,
      Value<String?> semenUsed,
      Value<String?> estimatedReturnDate,
      Value<double?> weighedResult,
      Value<String?> breedingDate,
      Value<String?> expectedDeliveryDate,
      Value<String?> notes,
      Value<String?> lastKnownLocation,
      Value<String?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$CattleEventsTableTableUpdateCompanionBuilder =
    CattleEventsTableCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> cattleTag,
      Value<String?> bullTag,
      Value<String?> calfTag,
      Value<String> eventType,
      Value<String> eventDate,
      Value<String?> sicknessSymptoms,
      Value<String?> diagnosis,
      Value<String?> technician,
      Value<String?> medicineGiven,
      Value<String?> semenUsed,
      Value<String?> estimatedReturnDate,
      Value<double?> weighedResult,
      Value<String?> breedingDate,
      Value<String?> expectedDeliveryDate,
      Value<String?> notes,
      Value<String?> lastKnownLocation,
      Value<String?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });

class $$CattleEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CattleEventsTableTable> {
  $$CattleEventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cattleTag => $composableBuilder(
    column: $table.cattleTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bullTag => $composableBuilder(
    column: $table.bullTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calfTag => $composableBuilder(
    column: $table.calfTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sicknessSymptoms => $composableBuilder(
    column: $table.sicknessSymptoms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get technician => $composableBuilder(
    column: $table.technician,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicineGiven => $composableBuilder(
    column: $table.medicineGiven,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semenUsed => $composableBuilder(
    column: $table.semenUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estimatedReturnDate => $composableBuilder(
    column: $table.estimatedReturnDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weighedResult => $composableBuilder(
    column: $table.weighedResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breedingDate => $composableBuilder(
    column: $table.breedingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedDeliveryDate => $composableBuilder(
    column: $table.expectedDeliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastKnownLocation => $composableBuilder(
    column: $table.lastKnownLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CattleEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CattleEventsTableTable> {
  $$CattleEventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cattleTag => $composableBuilder(
    column: $table.cattleTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bullTag => $composableBuilder(
    column: $table.bullTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calfTag => $composableBuilder(
    column: $table.calfTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sicknessSymptoms => $composableBuilder(
    column: $table.sicknessSymptoms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get technician => $composableBuilder(
    column: $table.technician,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicineGiven => $composableBuilder(
    column: $table.medicineGiven,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semenUsed => $composableBuilder(
    column: $table.semenUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estimatedReturnDate => $composableBuilder(
    column: $table.estimatedReturnDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weighedResult => $composableBuilder(
    column: $table.weighedResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breedingDate => $composableBuilder(
    column: $table.breedingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedDeliveryDate => $composableBuilder(
    column: $table.expectedDeliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastKnownLocation => $composableBuilder(
    column: $table.lastKnownLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CattleEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CattleEventsTableTable> {
  $$CattleEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get cattleTag =>
      $composableBuilder(column: $table.cattleTag, builder: (column) => column);

  GeneratedColumn<String> get bullTag =>
      $composableBuilder(column: $table.bullTag, builder: (column) => column);

  GeneratedColumn<String> get calfTag =>
      $composableBuilder(column: $table.calfTag, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get sicknessSymptoms => $composableBuilder(
    column: $table.sicknessSymptoms,
    builder: (column) => column,
  );

  GeneratedColumn<String> get diagnosis =>
      $composableBuilder(column: $table.diagnosis, builder: (column) => column);

  GeneratedColumn<String> get technician => $composableBuilder(
    column: $table.technician,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicineGiven => $composableBuilder(
    column: $table.medicineGiven,
    builder: (column) => column,
  );

  GeneratedColumn<String> get semenUsed =>
      $composableBuilder(column: $table.semenUsed, builder: (column) => column);

  GeneratedColumn<String> get estimatedReturnDate => $composableBuilder(
    column: $table.estimatedReturnDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weighedResult => $composableBuilder(
    column: $table.weighedResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get breedingDate => $composableBuilder(
    column: $table.breedingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedDeliveryDate => $composableBuilder(
    column: $table.expectedDeliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get lastKnownLocation => $composableBuilder(
    column: $table.lastKnownLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CattleEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CattleEventsTableTable,
          CattleEventsTableData,
          $$CattleEventsTableTableFilterComposer,
          $$CattleEventsTableTableOrderingComposer,
          $$CattleEventsTableTableAnnotationComposer,
          $$CattleEventsTableTableCreateCompanionBuilder,
          $$CattleEventsTableTableUpdateCompanionBuilder,
          (
            CattleEventsTableData,
            BaseReferences<
              _$AppDatabase,
              $CattleEventsTableTable,
              CattleEventsTableData
            >,
          ),
          CattleEventsTableData,
          PrefetchHooks Function()
        > {
  $$CattleEventsTableTableTableManager(
    _$AppDatabase db,
    $CattleEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CattleEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CattleEventsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CattleEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> cattleTag = const Value.absent(),
                Value<String?> bullTag = const Value.absent(),
                Value<String?> calfTag = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> eventDate = const Value.absent(),
                Value<String?> sicknessSymptoms = const Value.absent(),
                Value<String?> diagnosis = const Value.absent(),
                Value<String?> technician = const Value.absent(),
                Value<String?> medicineGiven = const Value.absent(),
                Value<String?> semenUsed = const Value.absent(),
                Value<String?> estimatedReturnDate = const Value.absent(),
                Value<double?> weighedResult = const Value.absent(),
                Value<String?> breedingDate = const Value.absent(),
                Value<String?> expectedDeliveryDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> lastKnownLocation = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CattleEventsTableCompanion(
                id: id,
                userId: userId,
                cattleTag: cattleTag,
                bullTag: bullTag,
                calfTag: calfTag,
                eventType: eventType,
                eventDate: eventDate,
                sicknessSymptoms: sicknessSymptoms,
                diagnosis: diagnosis,
                technician: technician,
                medicineGiven: medicineGiven,
                semenUsed: semenUsed,
                estimatedReturnDate: estimatedReturnDate,
                weighedResult: weighedResult,
                breedingDate: breedingDate,
                expectedDeliveryDate: expectedDeliveryDate,
                notes: notes,
                lastKnownLocation: lastKnownLocation,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String cattleTag,
                Value<String?> bullTag = const Value.absent(),
                Value<String?> calfTag = const Value.absent(),
                required String eventType,
                required String eventDate,
                Value<String?> sicknessSymptoms = const Value.absent(),
                Value<String?> diagnosis = const Value.absent(),
                Value<String?> technician = const Value.absent(),
                Value<String?> medicineGiven = const Value.absent(),
                Value<String?> semenUsed = const Value.absent(),
                Value<String?> estimatedReturnDate = const Value.absent(),
                Value<double?> weighedResult = const Value.absent(),
                Value<String?> breedingDate = const Value.absent(),
                Value<String?> expectedDeliveryDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> lastKnownLocation = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CattleEventsTableCompanion.insert(
                id: id,
                userId: userId,
                cattleTag: cattleTag,
                bullTag: bullTag,
                calfTag: calfTag,
                eventType: eventType,
                eventDate: eventDate,
                sicknessSymptoms: sicknessSymptoms,
                diagnosis: diagnosis,
                technician: technician,
                medicineGiven: medicineGiven,
                semenUsed: semenUsed,
                estimatedReturnDate: estimatedReturnDate,
                weighedResult: weighedResult,
                breedingDate: breedingDate,
                expectedDeliveryDate: expectedDeliveryDate,
                notes: notes,
                lastKnownLocation: lastKnownLocation,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CattleEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CattleEventsTableTable,
      CattleEventsTableData,
      $$CattleEventsTableTableFilterComposer,
      $$CattleEventsTableTableOrderingComposer,
      $$CattleEventsTableTableAnnotationComposer,
      $$CattleEventsTableTableCreateCompanionBuilder,
      $$CattleEventsTableTableUpdateCompanionBuilder,
      (
        CattleEventsTableData,
        BaseReferences<
          _$AppDatabase,
          $CattleEventsTableTable,
          CattleEventsTableData
        >,
      ),
      CattleEventsTableData,
      PrefetchHooks Function()
    >;
typedef $$SchedulesTableTableCreateCompanionBuilder =
    SchedulesTableCompanion Function({
      Value<int?> id,
      required int userId,
      required String title,
      Value<String?> cattleTag,
      required String type,
      required DateTime scheduleDateTime,
      Value<String?> duration,
      Value<String?> reminder,
      required String status,
      Value<String?> scheduledBy,
      Value<String?> details,
      Value<String?> vaccineType,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$SchedulesTableTableUpdateCompanionBuilder =
    SchedulesTableCompanion Function({
      Value<int?> id,
      Value<int> userId,
      Value<String> title,
      Value<String?> cattleTag,
      Value<String> type,
      Value<DateTime> scheduleDateTime,
      Value<String?> duration,
      Value<String?> reminder,
      Value<String> status,
      Value<String?> scheduledBy,
      Value<String?> details,
      Value<String?> vaccineType,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });

class $$SchedulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTableTable> {
  $$SchedulesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cattleTag => $composableBuilder(
    column: $table.cattleTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduleDateTime => $composableBuilder(
    column: $table.scheduleDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminder => $composableBuilder(
    column: $table.reminder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledBy => $composableBuilder(
    column: $table.scheduledBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vaccineType => $composableBuilder(
    column: $table.vaccineType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchedulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTableTable> {
  $$SchedulesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cattleTag => $composableBuilder(
    column: $table.cattleTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduleDateTime => $composableBuilder(
    column: $table.scheduleDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminder => $composableBuilder(
    column: $table.reminder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledBy => $composableBuilder(
    column: $table.scheduledBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vaccineType => $composableBuilder(
    column: $table.vaccineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchedulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTableTable> {
  $$SchedulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get cattleTag =>
      $composableBuilder(column: $table.cattleTag, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduleDateTime => $composableBuilder(
    column: $table.scheduleDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get reminder =>
      $composableBuilder(column: $table.reminder, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get scheduledBy => $composableBuilder(
    column: $table.scheduledBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get vaccineType => $composableBuilder(
    column: $table.vaccineType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SchedulesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedulesTableTable,
          SchedulesTableData,
          $$SchedulesTableTableFilterComposer,
          $$SchedulesTableTableOrderingComposer,
          $$SchedulesTableTableAnnotationComposer,
          $$SchedulesTableTableCreateCompanionBuilder,
          $$SchedulesTableTableUpdateCompanionBuilder,
          (
            SchedulesTableData,
            BaseReferences<
              _$AppDatabase,
              $SchedulesTableTable,
              SchedulesTableData
            >,
          ),
          SchedulesTableData,
          PrefetchHooks Function()
        > {
  $$SchedulesTableTableTableManager(
    _$AppDatabase db,
    $SchedulesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> cattleTag = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> scheduleDateTime = const Value.absent(),
                Value<String?> duration = const Value.absent(),
                Value<String?> reminder = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> scheduledBy = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<String?> vaccineType = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => SchedulesTableCompanion(
                id: id,
                userId: userId,
                title: title,
                cattleTag: cattleTag,
                type: type,
                scheduleDateTime: scheduleDateTime,
                duration: duration,
                reminder: reminder,
                status: status,
                scheduledBy: scheduledBy,
                details: details,
                vaccineType: vaccineType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                required int userId,
                required String title,
                Value<String?> cattleTag = const Value.absent(),
                required String type,
                required DateTime scheduleDateTime,
                Value<String?> duration = const Value.absent(),
                Value<String?> reminder = const Value.absent(),
                required String status,
                Value<String?> scheduledBy = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<String?> vaccineType = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => SchedulesTableCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                cattleTag: cattleTag,
                type: type,
                scheduleDateTime: scheduleDateTime,
                duration: duration,
                reminder: reminder,
                status: status,
                scheduledBy: scheduledBy,
                details: details,
                vaccineType: vaccineType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchedulesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedulesTableTable,
      SchedulesTableData,
      $$SchedulesTableTableFilterComposer,
      $$SchedulesTableTableOrderingComposer,
      $$SchedulesTableTableAnnotationComposer,
      $$SchedulesTableTableCreateCompanionBuilder,
      $$SchedulesTableTableUpdateCompanionBuilder,
      (
        SchedulesTableData,
        BaseReferences<_$AppDatabase, $SchedulesTableTable, SchedulesTableData>,
      ),
      SchedulesTableData,
      PrefetchHooks Function()
    >;
typedef $$VaccinationSchedulesTableTableCreateCompanionBuilder =
    VaccinationSchedulesTableCompanion Function({
      Value<int?> id,
      required String cattleTag,
      required String vaccineType,
      required String cattleStage,
      required DateTime recommendedDate,
      Value<DateTime?> actualDate,
      required String status,
      Value<String?> notes,
      Value<String?> administeredBy,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$VaccinationSchedulesTableTableUpdateCompanionBuilder =
    VaccinationSchedulesTableCompanion Function({
      Value<int?> id,
      Value<String> cattleTag,
      Value<String> vaccineType,
      Value<String> cattleStage,
      Value<DateTime> recommendedDate,
      Value<DateTime?> actualDate,
      Value<String> status,
      Value<String?> notes,
      Value<String?> administeredBy,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
    });

class $$VaccinationSchedulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $VaccinationSchedulesTableTable> {
  $$VaccinationSchedulesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cattleTag => $composableBuilder(
    column: $table.cattleTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vaccineType => $composableBuilder(
    column: $table.vaccineType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cattleStage => $composableBuilder(
    column: $table.cattleStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recommendedDate => $composableBuilder(
    column: $table.recommendedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualDate => $composableBuilder(
    column: $table.actualDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get administeredBy => $composableBuilder(
    column: $table.administeredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaccinationSchedulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VaccinationSchedulesTableTable> {
  $$VaccinationSchedulesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cattleTag => $composableBuilder(
    column: $table.cattleTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vaccineType => $composableBuilder(
    column: $table.vaccineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cattleStage => $composableBuilder(
    column: $table.cattleStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recommendedDate => $composableBuilder(
    column: $table.recommendedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualDate => $composableBuilder(
    column: $table.actualDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get administeredBy => $composableBuilder(
    column: $table.administeredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaccinationSchedulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaccinationSchedulesTableTable> {
  $$VaccinationSchedulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cattleTag =>
      $composableBuilder(column: $table.cattleTag, builder: (column) => column);

  GeneratedColumn<String> get vaccineType => $composableBuilder(
    column: $table.vaccineType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cattleStage => $composableBuilder(
    column: $table.cattleStage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recommendedDate => $composableBuilder(
    column: $table.recommendedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actualDate => $composableBuilder(
    column: $table.actualDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get administeredBy => $composableBuilder(
    column: $table.administeredBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$VaccinationSchedulesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaccinationSchedulesTableTable,
          VaccinationSchedulesTableData,
          $$VaccinationSchedulesTableTableFilterComposer,
          $$VaccinationSchedulesTableTableOrderingComposer,
          $$VaccinationSchedulesTableTableAnnotationComposer,
          $$VaccinationSchedulesTableTableCreateCompanionBuilder,
          $$VaccinationSchedulesTableTableUpdateCompanionBuilder,
          (
            VaccinationSchedulesTableData,
            BaseReferences<
              _$AppDatabase,
              $VaccinationSchedulesTableTable,
              VaccinationSchedulesTableData
            >,
          ),
          VaccinationSchedulesTableData,
          PrefetchHooks Function()
        > {
  $$VaccinationSchedulesTableTableTableManager(
    _$AppDatabase db,
    $VaccinationSchedulesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaccinationSchedulesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$VaccinationSchedulesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VaccinationSchedulesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<String> cattleTag = const Value.absent(),
                Value<String> vaccineType = const Value.absent(),
                Value<String> cattleStage = const Value.absent(),
                Value<DateTime> recommendedDate = const Value.absent(),
                Value<DateTime?> actualDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> administeredBy = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => VaccinationSchedulesTableCompanion(
                id: id,
                cattleTag: cattleTag,
                vaccineType: vaccineType,
                cattleStage: cattleStage,
                recommendedDate: recommendedDate,
                actualDate: actualDate,
                status: status,
                notes: notes,
                administeredBy: administeredBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                required String cattleTag,
                required String vaccineType,
                required String cattleStage,
                required DateTime recommendedDate,
                Value<DateTime?> actualDate = const Value.absent(),
                required String status,
                Value<String?> notes = const Value.absent(),
                Value<String?> administeredBy = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => VaccinationSchedulesTableCompanion.insert(
                id: id,
                cattleTag: cattleTag,
                vaccineType: vaccineType,
                cattleStage: cattleStage,
                recommendedDate: recommendedDate,
                actualDate: actualDate,
                status: status,
                notes: notes,
                administeredBy: administeredBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaccinationSchedulesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaccinationSchedulesTableTable,
      VaccinationSchedulesTableData,
      $$VaccinationSchedulesTableTableFilterComposer,
      $$VaccinationSchedulesTableTableOrderingComposer,
      $$VaccinationSchedulesTableTableAnnotationComposer,
      $$VaccinationSchedulesTableTableCreateCompanionBuilder,
      $$VaccinationSchedulesTableTableUpdateCompanionBuilder,
      (
        VaccinationSchedulesTableData,
        BaseReferences<
          _$AppDatabase,
          $VaccinationSchedulesTableTable,
          VaccinationSchedulesTableData
        >,
      ),
      VaccinationSchedulesTableData,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableTableCreateCompanionBuilder =
    OutboxTableCompanion Function({
      required String id,
      required String entity,
      Value<String?> entityId,
      required String operation,
      required String payload,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$OutboxTableTableUpdateCompanionBuilder =
    OutboxTableCompanion Function({
      Value<String> id,
      Value<String> entity,
      Value<String?> entityId,
      Value<String> operation,
      Value<String> payload,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTableTable,
          OutboxTableData,
          $$OutboxTableTableFilterComposer,
          $$OutboxTableTableOrderingComposer,
          $$OutboxTableTableAnnotationComposer,
          $$OutboxTableTableCreateCompanionBuilder,
          $$OutboxTableTableUpdateCompanionBuilder,
          (
            OutboxTableData,
            BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxTableData>,
          ),
          OutboxTableData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableTableManager(_$AppDatabase db, $OutboxTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxTableCompanion(
                id: id,
                entity: entity,
                entityId: entityId,
                operation: operation,
                payload: payload,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entity,
                Value<String?> entityId = const Value.absent(),
                required String operation,
                required String payload,
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxTableCompanion.insert(
                id: id,
                entity: entity,
                entityId: entityId,
                operation: operation,
                payload: payload,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTableTable,
      OutboxTableData,
      $$OutboxTableTableFilterComposer,
      $$OutboxTableTableOrderingComposer,
      $$OutboxTableTableAnnotationComposer,
      $$OutboxTableTableCreateCompanionBuilder,
      $$OutboxTableTableUpdateCompanionBuilder,
      (
        OutboxTableData,
        BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxTableData>,
      ),
      OutboxTableData,
      PrefetchHooks Function()
    >;
typedef $$MetaTableTableCreateCompanionBuilder =
    MetaTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetaTableTableUpdateCompanionBuilder =
    MetaTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetaTableTableFilterComposer
    extends Composer<_$AppDatabase, $MetaTableTable> {
  $$MetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MetaTableTable> {
  $$MetaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaTableTable> {
  $$MetaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaTableTable,
          MetaTableData,
          $$MetaTableTableFilterComposer,
          $$MetaTableTableOrderingComposer,
          $$MetaTableTableAnnotationComposer,
          $$MetaTableTableCreateCompanionBuilder,
          $$MetaTableTableUpdateCompanionBuilder,
          (
            MetaTableData,
            BaseReferences<_$AppDatabase, $MetaTableTable, MetaTableData>,
          ),
          MetaTableData,
          PrefetchHooks Function()
        > {
  $$MetaTableTableTableManager(_$AppDatabase db, $MetaTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetaTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaTableTable,
      MetaTableData,
      $$MetaTableTableFilterComposer,
      $$MetaTableTableOrderingComposer,
      $$MetaTableTableAnnotationComposer,
      $$MetaTableTableCreateCompanionBuilder,
      $$MetaTableTableUpdateCompanionBuilder,
      (
        MetaTableData,
        BaseReferences<_$AppDatabase, $MetaTableTable, MetaTableData>,
      ),
      MetaTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CattlesTableTableTableManager get cattlesTable =>
      $$CattlesTableTableTableManager(_db, _db.cattlesTable);
  $$CattleEventsTableTableTableManager get cattleEventsTable =>
      $$CattleEventsTableTableTableManager(_db, _db.cattleEventsTable);
  $$SchedulesTableTableTableManager get schedulesTable =>
      $$SchedulesTableTableTableManager(_db, _db.schedulesTable);
  $$VaccinationSchedulesTableTableTableManager get vaccinationSchedulesTable =>
      $$VaccinationSchedulesTableTableTableManager(
        _db,
        _db.vaccinationSchedulesTable,
      );
  $$OutboxTableTableTableManager get outboxTable =>
      $$OutboxTableTableTableManager(_db, _db.outboxTable);
  $$MetaTableTableTableManager get metaTable =>
      $$MetaTableTableTableManager(_db, _db.metaTable);
}
