// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
mixin $ProjectsTableToColumns implements Insertable<Project> {
  String get id;
  String get name;
  String? get note;
  double? get azimuth;
  String? get lastUpdate;
  String? get date;
  double? get presumedTotalLength;
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || azimuth != null) {
      map['azimuth'] = Variable<double>(azimuth);
    }
    if (!nullToAbsent || lastUpdate != null) {
      map['last_update'] = Variable<String>(lastUpdate);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    if (!nullToAbsent || presumedTotalLength != null) {
      map['presumed_total_length'] = Variable<double>(presumedTotalLength);
    }
    return map;
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _azimuthMeta = const VerificationMeta(
    'azimuth',
  );
  @override
  late final GeneratedColumn<double> azimuth = GeneratedColumn<double>(
    'azimuth',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdateMeta = const VerificationMeta(
    'lastUpdate',
  );
  @override
  late final GeneratedColumn<String> lastUpdate = GeneratedColumn<String>(
    'last_update',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _presumedTotalLengthMeta =
      const VerificationMeta('presumedTotalLength');
  @override
  late final GeneratedColumn<double> presumedTotalLength =
      GeneratedColumn<double>(
        'presumed_total_length',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    note,
    azimuth,
    lastUpdate,
    date,
    presumedTotalLength,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('azimuth')) {
      context.handle(
        _azimuthMeta,
        azimuth.isAcceptableOrUnknown(data['azimuth']!, _azimuthMeta),
      );
    }
    if (data.containsKey('last_update')) {
      context.handle(
        _lastUpdateMeta,
        lastUpdate.isAcceptableOrUnknown(data['last_update']!, _lastUpdateMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('presumed_total_length')) {
      context.handle(
        _presumedTotalLengthMeta,
        presumedTotalLength.isAcceptableOrUnknown(
          data['presumed_total_length']!,
          _presumedTotalLengthMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      azimuth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}azimuth'],
      ),
      lastUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_update'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
      presumedTotalLength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}presumed_total_length'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass with $ProjectsTableToColumns {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? note;
  @override
  final double? azimuth;
  @override
  final String? lastUpdate;
  @override
  final String? date;
  @override
  final double? presumedTotalLength;
  const Project({
    required this.id,
    required this.name,
    this.note,
    this.azimuth,
    this.lastUpdate,
    this.date,
    this.presumedTotalLength,
  });
  ProjectCompanion toCompanion(bool nullToAbsent) {
    return ProjectCompanion(
      id: Value(id),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      azimuth: azimuth == null && nullToAbsent
          ? const Value.absent()
          : Value(azimuth),
      lastUpdate: lastUpdate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdate),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      presumedTotalLength: presumedTotalLength == null && nullToAbsent
          ? const Value.absent()
          : Value(presumedTotalLength),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      azimuth: serializer.fromJson<double?>(json['azimuth']),
      lastUpdate: serializer.fromJson<String?>(json['lastUpdate']),
      date: serializer.fromJson<String?>(json['date']),
      presumedTotalLength: serializer.fromJson<double?>(
        json['presumedTotalLength'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'azimuth': serializer.toJson<double?>(azimuth),
      'lastUpdate': serializer.toJson<String?>(lastUpdate),
      'date': serializer.toJson<String?>(date),
      'presumedTotalLength': serializer.toJson<double?>(presumedTotalLength),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    Value<String?> note = const Value.absent(),
    Value<double?> azimuth = const Value.absent(),
    Value<String?> lastUpdate = const Value.absent(),
    Value<String?> date = const Value.absent(),
    Value<double?> presumedTotalLength = const Value.absent(),
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
    azimuth: azimuth.present ? azimuth.value : this.azimuth,
    lastUpdate: lastUpdate.present ? lastUpdate.value : this.lastUpdate,
    date: date.present ? date.value : this.date,
    presumedTotalLength: presumedTotalLength.present
        ? presumedTotalLength.value
        : this.presumedTotalLength,
  );
  Project copyWithCompanion(ProjectCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      azimuth: data.azimuth.present ? data.azimuth.value : this.azimuth,
      lastUpdate: data.lastUpdate.present
          ? data.lastUpdate.value
          : this.lastUpdate,
      date: data.date.present ? data.date.value : this.date,
      presumedTotalLength: data.presumedTotalLength.present
          ? data.presumedTotalLength.value
          : this.presumedTotalLength,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('azimuth: $azimuth, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('date: $date, ')
          ..write('presumedTotalLength: $presumedTotalLength')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    note,
    azimuth,
    lastUpdate,
    date,
    presumedTotalLength,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.note == this.note &&
          other.azimuth == this.azimuth &&
          other.lastUpdate == this.lastUpdate &&
          other.date == this.date &&
          other.presumedTotalLength == this.presumedTotalLength);
}

class ProjectCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> note;
  final Value<double?> azimuth;
  final Value<String?> lastUpdate;
  final Value<String?> date;
  final Value<double?> presumedTotalLength;
  final Value<int> rowid;
  const ProjectCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.azimuth = const Value.absent(),
    this.lastUpdate = const Value.absent(),
    this.date = const Value.absent(),
    this.presumedTotalLength = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectCompanion.insert({
    required String id,
    required String name,
    this.note = const Value.absent(),
    this.azimuth = const Value.absent(),
    this.lastUpdate = const Value.absent(),
    this.date = const Value.absent(),
    this.presumedTotalLength = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? note,
    Expression<double>? azimuth,
    Expression<String>? lastUpdate,
    Expression<String>? date,
    Expression<double>? presumedTotalLength,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (azimuth != null) 'azimuth': azimuth,
      if (lastUpdate != null) 'last_update': lastUpdate,
      if (date != null) 'date': date,
      if (presumedTotalLength != null)
        'presumed_total_length': presumedTotalLength,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? note,
    Value<double?>? azimuth,
    Value<String?>? lastUpdate,
    Value<String?>? date,
    Value<double?>? presumedTotalLength,
    Value<int>? rowid,
  }) {
    return ProjectCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      azimuth: azimuth ?? this.azimuth,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      date: date ?? this.date,
      presumedTotalLength: presumedTotalLength ?? this.presumedTotalLength,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (azimuth.present) {
      map['azimuth'] = Variable<double>(azimuth.value);
    }
    if (lastUpdate.present) {
      map['last_update'] = Variable<String>(lastUpdate.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (presumedTotalLength.present) {
      map['presumed_total_length'] = Variable<double>(
        presumedTotalLength.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('azimuth: $azimuth, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('date: $date, ')
          ..write('presumedTotalLength: $presumedTotalLength, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

mixin $PointsTableToColumns implements Insertable<Point> {
  String get id;
  String get projectId;
  double get latitude;
  double get longitude;
  double? get altitude;
  double? get gpsPrecision;
  int get ordinalNumber;
  String? get note;
  String? get timestamp;
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || gpsPrecision != null) {
      map['gps_precision'] = Variable<double>(gpsPrecision);
    }
    map['ordinal_number'] = Variable<int>(ordinalNumber);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<String>(timestamp);
    }
    return map;
  }
}

class $PointsTable extends Points with TableInfo<$PointsTable, Point> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsPrecisionMeta = const VerificationMeta(
    'gpsPrecision',
  );
  @override
  late final GeneratedColumn<double> gpsPrecision = GeneratedColumn<double>(
    'gps_precision',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordinalNumberMeta = const VerificationMeta(
    'ordinalNumber',
  );
  @override
  late final GeneratedColumn<int> ordinalNumber = GeneratedColumn<int>(
    'ordinal_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    latitude,
    longitude,
    altitude,
    gpsPrecision,
    ordinalNumber,
    note,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'points';
  @override
  VerificationContext validateIntegrity(
    Insertable<Point> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('gps_precision')) {
      context.handle(
        _gpsPrecisionMeta,
        gpsPrecision.isAcceptableOrUnknown(
          data['gps_precision']!,
          _gpsPrecisionMeta,
        ),
      );
    }
    if (data.containsKey('ordinal_number')) {
      context.handle(
        _ordinalNumberMeta,
        ordinalNumber.isAcceptableOrUnknown(
          data['ordinal_number']!,
          _ordinalNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ordinalNumberMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Point map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Point(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      gpsPrecision: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_precision'],
      ),
      ordinalNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal_number'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      ),
    );
  }

  @override
  $PointsTable createAlias(String alias) {
    return $PointsTable(attachedDatabase, alias);
  }
}

class Point extends DataClass with $PointsTableToColumns {
  @override
  final String id;
  @override
  final String projectId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double? altitude;
  @override
  final double? gpsPrecision;
  @override
  final int ordinalNumber;
  @override
  final String? note;
  @override
  final String? timestamp;
  const Point({
    required this.id,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.gpsPrecision,
    required this.ordinalNumber,
    this.note,
    this.timestamp,
  });
  PointCompanion toCompanion(bool nullToAbsent) {
    return PointCompanion(
      id: Value(id),
      projectId: Value(projectId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      gpsPrecision: gpsPrecision == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsPrecision),
      ordinalNumber: Value(ordinalNumber),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
    );
  }

  factory Point.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Point(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      gpsPrecision: serializer.fromJson<double?>(json['gpsPrecision']),
      ordinalNumber: serializer.fromJson<int>(json['ordinalNumber']),
      note: serializer.fromJson<String?>(json['note']),
      timestamp: serializer.fromJson<String?>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'altitude': serializer.toJson<double?>(altitude),
      'gpsPrecision': serializer.toJson<double?>(gpsPrecision),
      'ordinalNumber': serializer.toJson<int>(ordinalNumber),
      'note': serializer.toJson<String?>(note),
      'timestamp': serializer.toJson<String?>(timestamp),
    };
  }

  Point copyWith({
    String? id,
    String? projectId,
    double? latitude,
    double? longitude,
    Value<double?> altitude = const Value.absent(),
    Value<double?> gpsPrecision = const Value.absent(),
    int? ordinalNumber,
    Value<String?> note = const Value.absent(),
    Value<String?> timestamp = const Value.absent(),
  }) => Point(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitude: altitude.present ? altitude.value : this.altitude,
    gpsPrecision: gpsPrecision.present ? gpsPrecision.value : this.gpsPrecision,
    ordinalNumber: ordinalNumber ?? this.ordinalNumber,
    note: note.present ? note.value : this.note,
    timestamp: timestamp.present ? timestamp.value : this.timestamp,
  );
  Point copyWithCompanion(PointCompanion data) {
    return Point(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      gpsPrecision: data.gpsPrecision.present
          ? data.gpsPrecision.value
          : this.gpsPrecision,
      ordinalNumber: data.ordinalNumber.present
          ? data.ordinalNumber.value
          : this.ordinalNumber,
      note: data.note.present ? data.note.value : this.note,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Point(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('gpsPrecision: $gpsPrecision, ')
          ..write('ordinalNumber: $ordinalNumber, ')
          ..write('note: $note, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    latitude,
    longitude,
    altitude,
    gpsPrecision,
    ordinalNumber,
    note,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Point &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitude == this.altitude &&
          other.gpsPrecision == this.gpsPrecision &&
          other.ordinalNumber == this.ordinalNumber &&
          other.note == this.note &&
          other.timestamp == this.timestamp);
}

class PointCompanion extends UpdateCompanion<Point> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> altitude;
  final Value<double?> gpsPrecision;
  final Value<int> ordinalNumber;
  final Value<String?> note;
  final Value<String?> timestamp;
  final Value<int> rowid;
  const PointCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.gpsPrecision = const Value.absent(),
    this.ordinalNumber = const Value.absent(),
    this.note = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PointCompanion.insert({
    required String id,
    required String projectId,
    required double latitude,
    required double longitude,
    this.altitude = const Value.absent(),
    this.gpsPrecision = const Value.absent(),
    required int ordinalNumber,
    this.note = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       ordinalNumber = Value(ordinalNumber);
  static Insertable<Point> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitude,
    Expression<double>? gpsPrecision,
    Expression<int>? ordinalNumber,
    Expression<String>? note,
    Expression<String>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (gpsPrecision != null) 'gps_precision': gpsPrecision,
      if (ordinalNumber != null) 'ordinal_number': ordinalNumber,
      if (note != null) 'note': note,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PointCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? altitude,
    Value<double?>? gpsPrecision,
    Value<int>? ordinalNumber,
    Value<String?>? note,
    Value<String?>? timestamp,
    Value<int>? rowid,
  }) {
    return PointCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      gpsPrecision: gpsPrecision ?? this.gpsPrecision,
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (gpsPrecision.present) {
      map['gps_precision'] = Variable<double>(gpsPrecision.value);
    }
    if (ordinalNumber.present) {
      map['ordinal_number'] = Variable<int>(ordinalNumber.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PointCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('gpsPrecision: $gpsPrecision, ')
          ..write('ordinalNumber: $ordinalNumber, ')
          ..write('note: $note, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

mixin $ImagesTableToColumns implements Insertable<Image> {
  String get id;
  String get pointId;
  int get ordinalNumber;
  String get imagePath;
  String? get note;
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['point_id'] = Variable<String>(pointId);
    map['ordinal_number'] = Variable<int>(ordinalNumber);
    map['image_path'] = Variable<String>(imagePath);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }
}

class $ImagesTable extends Images with TableInfo<$ImagesTable, Image> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointIdMeta = const VerificationMeta(
    'pointId',
  );
  @override
  late final GeneratedColumn<String> pointId = GeneratedColumn<String>(
    'point_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES points (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ordinalNumberMeta = const VerificationMeta(
    'ordinalNumber',
  );
  @override
  late final GeneratedColumn<int> ordinalNumber = GeneratedColumn<int>(
    'ordinal_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pointId,
    ordinalNumber,
    imagePath,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(
    Insertable<Image> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('point_id')) {
      context.handle(
        _pointIdMeta,
        pointId.isAcceptableOrUnknown(data['point_id']!, _pointIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pointIdMeta);
    }
    if (data.containsKey('ordinal_number')) {
      context.handle(
        _ordinalNumberMeta,
        ordinalNumber.isAcceptableOrUnknown(
          data['ordinal_number']!,
          _ordinalNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ordinalNumberMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Image map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Image(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_id'],
      )!,
      ordinalNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal_number'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }
}

class Image extends DataClass with $ImagesTableToColumns {
  @override
  final String id;
  @override
  final String pointId;
  @override
  final int ordinalNumber;
  @override
  final String imagePath;
  @override
  final String? note;
  const Image({
    required this.id,
    required this.pointId,
    required this.ordinalNumber,
    required this.imagePath,
    this.note,
  });
  ImageCompanion toCompanion(bool nullToAbsent) {
    return ImageCompanion(
      id: Value(id),
      pointId: Value(pointId),
      ordinalNumber: Value(ordinalNumber),
      imagePath: Value(imagePath),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Image.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Image(
      id: serializer.fromJson<String>(json['id']),
      pointId: serializer.fromJson<String>(json['pointId']),
      ordinalNumber: serializer.fromJson<int>(json['ordinalNumber']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pointId': serializer.toJson<String>(pointId),
      'ordinalNumber': serializer.toJson<int>(ordinalNumber),
      'imagePath': serializer.toJson<String>(imagePath),
      'note': serializer.toJson<String?>(note),
    };
  }

  Image copyWith({
    String? id,
    String? pointId,
    int? ordinalNumber,
    String? imagePath,
    Value<String?> note = const Value.absent(),
  }) => Image(
    id: id ?? this.id,
    pointId: pointId ?? this.pointId,
    ordinalNumber: ordinalNumber ?? this.ordinalNumber,
    imagePath: imagePath ?? this.imagePath,
    note: note.present ? note.value : this.note,
  );
  Image copyWithCompanion(ImageCompanion data) {
    return Image(
      id: data.id.present ? data.id.value : this.id,
      pointId: data.pointId.present ? data.pointId.value : this.pointId,
      ordinalNumber: data.ordinalNumber.present
          ? data.ordinalNumber.value
          : this.ordinalNumber,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Image(')
          ..write('id: $id, ')
          ..write('pointId: $pointId, ')
          ..write('ordinalNumber: $ordinalNumber, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pointId, ordinalNumber, imagePath, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Image &&
          other.id == this.id &&
          other.pointId == this.pointId &&
          other.ordinalNumber == this.ordinalNumber &&
          other.imagePath == this.imagePath &&
          other.note == this.note);
}

class ImageCompanion extends UpdateCompanion<Image> {
  final Value<String> id;
  final Value<String> pointId;
  final Value<int> ordinalNumber;
  final Value<String> imagePath;
  final Value<String?> note;
  final Value<int> rowid;
  const ImageCompanion({
    this.id = const Value.absent(),
    this.pointId = const Value.absent(),
    this.ordinalNumber = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageCompanion.insert({
    required String id,
    required String pointId,
    required int ordinalNumber,
    required String imagePath,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pointId = Value(pointId),
       ordinalNumber = Value(ordinalNumber),
       imagePath = Value(imagePath);
  static Insertable<Image> custom({
    Expression<String>? id,
    Expression<String>? pointId,
    Expression<int>? ordinalNumber,
    Expression<String>? imagePath,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pointId != null) 'point_id': pointId,
      if (ordinalNumber != null) 'ordinal_number': ordinalNumber,
      if (imagePath != null) 'image_path': imagePath,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageCompanion copyWith({
    Value<String>? id,
    Value<String>? pointId,
    Value<int>? ordinalNumber,
    Value<String>? imagePath,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return ImageCompanion(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pointId.present) {
      map['point_id'] = Variable<String>(pointId.value);
    }
    if (ordinalNumber.present) {
      map['ordinal_number'] = Variable<int>(ordinalNumber.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageCompanion(')
          ..write('id: $id, ')
          ..write('pointId: $pointId, ')
          ..write('ordinalNumber: $ordinalNumber, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TeleferikaDatabase extends GeneratedDatabase {
  _$TeleferikaDatabase(QueryExecutor e) : super(e);
  $TeleferikaDatabaseManager get managers => $TeleferikaDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $PointsTable points = $PointsTable(this);
  late final $ImagesTable images = $ImagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    points,
    images,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'points',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('images', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectCompanion Function({
      required String id,
      required String name,
      Value<String?> note,
      Value<double?> azimuth,
      Value<String?> lastUpdate,
      Value<String?> date,
      Value<double?> presumedTotalLength,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> note,
      Value<double?> azimuth,
      Value<String?> lastUpdate,
      Value<String?> date,
      Value<double?> presumedTotalLength,
      Value<int> rowid,
    });

final class $$ProjectsTableReferences
    extends BaseReferences<_$TeleferikaDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PointsTable, List<Point>> _pointsRefsTable(
    _$TeleferikaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.points,
    aliasName: $_aliasNameGenerator(db.projects.id, db.points.projectId),
  );

  $$PointsTableProcessedTableManager get pointsRefs {
    final manager = $$PointsTableTableManager(
      $_db,
      $_db.points,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$TeleferikaDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get azimuth => $composableBuilder(
    column: $table.azimuth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdate => $composableBuilder(
    column: $table.lastUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get presumedTotalLength => $composableBuilder(
    column: $table.presumedTotalLength,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pointsRefs(
    Expression<bool> Function($$PointsTableFilterComposer f) f,
  ) {
    final $$PointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.points,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointsTableFilterComposer(
            $db: $db,
            $table: $db.points,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$TeleferikaDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get azimuth => $composableBuilder(
    column: $table.azimuth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdate => $composableBuilder(
    column: $table.lastUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get presumedTotalLength => $composableBuilder(
    column: $table.presumedTotalLength,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$TeleferikaDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<double> get azimuth =>
      $composableBuilder(column: $table.azimuth, builder: (column) => column);

  GeneratedColumn<String> get lastUpdate => $composableBuilder(
    column: $table.lastUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get presumedTotalLength => $composableBuilder(
    column: $table.presumedTotalLength,
    builder: (column) => column,
  );

  Expression<T> pointsRefs<T extends Object>(
    Expression<T> Function($$PointsTableAnnotationComposer a) f,
  ) {
    final $$PointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.points,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointsTableAnnotationComposer(
            $db: $db,
            $table: $db.points,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$TeleferikaDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool pointsRefs})
        > {
  $$ProjectsTableTableManager(_$TeleferikaDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<double?> azimuth = const Value.absent(),
                Value<String?> lastUpdate = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<double?> presumedTotalLength = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectCompanion(
                id: id,
                name: name,
                note: note,
                azimuth: azimuth,
                lastUpdate: lastUpdate,
                date: date,
                presumedTotalLength: presumedTotalLength,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> note = const Value.absent(),
                Value<double?> azimuth = const Value.absent(),
                Value<String?> lastUpdate = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<double?> presumedTotalLength = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectCompanion.insert(
                id: id,
                name: name,
                note: note,
                azimuth: azimuth,
                lastUpdate: lastUpdate,
                date: date,
                presumedTotalLength: presumedTotalLength,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pointsRefs) db.points],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pointsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable, Point>(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._pointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProjectsTableReferences(db, table, p0).pointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$TeleferikaDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool pointsRefs})
    >;
typedef $$PointsTableCreateCompanionBuilder =
    PointCompanion Function({
      required String id,
      required String projectId,
      required double latitude,
      required double longitude,
      Value<double?> altitude,
      Value<double?> gpsPrecision,
      required int ordinalNumber,
      Value<String?> note,
      Value<String?> timestamp,
      Value<int> rowid,
    });
typedef $$PointsTableUpdateCompanionBuilder =
    PointCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> altitude,
      Value<double?> gpsPrecision,
      Value<int> ordinalNumber,
      Value<String?> note,
      Value<String?> timestamp,
      Value<int> rowid,
    });

final class $$PointsTableReferences
    extends BaseReferences<_$TeleferikaDatabase, $PointsTable, Point> {
  $$PointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$TeleferikaDatabase db) => db.projects
      .createAlias($_aliasNameGenerator(db.points.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ImagesTable, List<Image>> _imagesRefsTable(
    _$TeleferikaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.images,
    aliasName: $_aliasNameGenerator(db.points.id, db.images.pointId),
  );

  $$ImagesTableProcessedTableManager get imagesRefs {
    final manager = $$ImagesTableTableManager(
      $_db,
      $_db.images,
    ).filter((f) => f.pointId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PointsTableFilterComposer
    extends Composer<_$TeleferikaDatabase, $PointsTable> {
  $$PointsTableFilterComposer({
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

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsPrecision => $composableBuilder(
    column: $table.gpsPrecision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinalNumber => $composableBuilder(
    column: $table.ordinalNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> imagesRefs(
    Expression<bool> Function($$ImagesTableFilterComposer f) f,
  ) {
    final $$ImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.pointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableFilterComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PointsTableOrderingComposer
    extends Composer<_$TeleferikaDatabase, $PointsTable> {
  $$PointsTableOrderingComposer({
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

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsPrecision => $composableBuilder(
    column: $table.gpsPrecision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinalNumber => $composableBuilder(
    column: $table.ordinalNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PointsTableAnnotationComposer
    extends Composer<_$TeleferikaDatabase, $PointsTable> {
  $$PointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get gpsPrecision => $composableBuilder(
    column: $table.gpsPrecision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordinalNumber => $composableBuilder(
    column: $table.ordinalNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> imagesRefs<T extends Object>(
    Expression<T> Function($$ImagesTableAnnotationComposer a) f,
  ) {
    final $$ImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.pointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PointsTableTableManager
    extends
        RootTableManager<
          _$TeleferikaDatabase,
          $PointsTable,
          Point,
          $$PointsTableFilterComposer,
          $$PointsTableOrderingComposer,
          $$PointsTableAnnotationComposer,
          $$PointsTableCreateCompanionBuilder,
          $$PointsTableUpdateCompanionBuilder,
          (Point, $$PointsTableReferences),
          Point,
          PrefetchHooks Function({bool projectId, bool imagesRefs})
        > {
  $$PointsTableTableManager(_$TeleferikaDatabase db, $PointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> gpsPrecision = const Value.absent(),
                Value<int> ordinalNumber = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PointCompanion(
                id: id,
                projectId: projectId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                gpsPrecision: gpsPrecision,
                ordinalNumber: ordinalNumber,
                note: note,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required double latitude,
                required double longitude,
                Value<double?> altitude = const Value.absent(),
                Value<double?> gpsPrecision = const Value.absent(),
                required int ordinalNumber,
                Value<String?> note = const Value.absent(),
                Value<String?> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PointCompanion.insert(
                id: id,
                projectId: projectId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                gpsPrecision: gpsPrecision,
                ordinalNumber: ordinalNumber,
                note: note,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PointsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, imagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (imagesRefs) db.images],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable: $$PointsTableReferences
                                    ._projectIdTable(db),
                                referencedColumn: $$PointsTableReferences
                                    ._projectIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (imagesRefs)
                    await $_getPrefetchedData<Point, $PointsTable, Image>(
                      currentTable: table,
                      referencedTable: $$PointsTableReferences._imagesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$PointsTableReferences(db, table, p0).imagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.pointId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PointsTableProcessedTableManager =
    ProcessedTableManager<
      _$TeleferikaDatabase,
      $PointsTable,
      Point,
      $$PointsTableFilterComposer,
      $$PointsTableOrderingComposer,
      $$PointsTableAnnotationComposer,
      $$PointsTableCreateCompanionBuilder,
      $$PointsTableUpdateCompanionBuilder,
      (Point, $$PointsTableReferences),
      Point,
      PrefetchHooks Function({bool projectId, bool imagesRefs})
    >;
typedef $$ImagesTableCreateCompanionBuilder =
    ImageCompanion Function({
      required String id,
      required String pointId,
      required int ordinalNumber,
      required String imagePath,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$ImagesTableUpdateCompanionBuilder =
    ImageCompanion Function({
      Value<String> id,
      Value<String> pointId,
      Value<int> ordinalNumber,
      Value<String> imagePath,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$ImagesTableReferences
    extends BaseReferences<_$TeleferikaDatabase, $ImagesTable, Image> {
  $$ImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PointsTable _pointIdTable(_$TeleferikaDatabase db) => db.points
      .createAlias($_aliasNameGenerator(db.images.pointId, db.points.id));

  $$PointsTableProcessedTableManager get pointId {
    final $_column = $_itemColumn<String>('point_id')!;

    final manager = $$PointsTableTableManager(
      $_db,
      $_db.points,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pointIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImagesTableFilterComposer
    extends Composer<_$TeleferikaDatabase, $ImagesTable> {
  $$ImagesTableFilterComposer({
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

  ColumnFilters<int> get ordinalNumber => $composableBuilder(
    column: $table.ordinalNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$PointsTableFilterComposer get pointId {
    final $$PointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pointId,
      referencedTable: $db.points,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointsTableFilterComposer(
            $db: $db,
            $table: $db.points,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableOrderingComposer
    extends Composer<_$TeleferikaDatabase, $ImagesTable> {
  $$ImagesTableOrderingComposer({
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

  ColumnOrderings<int> get ordinalNumber => $composableBuilder(
    column: $table.ordinalNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$PointsTableOrderingComposer get pointId {
    final $$PointsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pointId,
      referencedTable: $db.points,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointsTableOrderingComposer(
            $db: $db,
            $table: $db.points,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableAnnotationComposer
    extends Composer<_$TeleferikaDatabase, $ImagesTable> {
  $$ImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ordinalNumber => $composableBuilder(
    column: $table.ordinalNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$PointsTableAnnotationComposer get pointId {
    final $$PointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pointId,
      referencedTable: $db.points,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointsTableAnnotationComposer(
            $db: $db,
            $table: $db.points,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableTableManager
    extends
        RootTableManager<
          _$TeleferikaDatabase,
          $ImagesTable,
          Image,
          $$ImagesTableFilterComposer,
          $$ImagesTableOrderingComposer,
          $$ImagesTableAnnotationComposer,
          $$ImagesTableCreateCompanionBuilder,
          $$ImagesTableUpdateCompanionBuilder,
          (Image, $$ImagesTableReferences),
          Image,
          PrefetchHooks Function({bool pointId})
        > {
  $$ImagesTableTableManager(_$TeleferikaDatabase db, $ImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pointId = const Value.absent(),
                Value<int> ordinalNumber = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageCompanion(
                id: id,
                pointId: pointId,
                ordinalNumber: ordinalNumber,
                imagePath: imagePath,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pointId,
                required int ordinalNumber,
                required String imagePath,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageCompanion.insert(
                id: id,
                pointId: pointId,
                ordinalNumber: ordinalNumber,
                imagePath: imagePath,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ImagesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({pointId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pointId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pointId,
                                referencedTable: $$ImagesTableReferences
                                    ._pointIdTable(db),
                                referencedColumn: $$ImagesTableReferences
                                    ._pointIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$TeleferikaDatabase,
      $ImagesTable,
      Image,
      $$ImagesTableFilterComposer,
      $$ImagesTableOrderingComposer,
      $$ImagesTableAnnotationComposer,
      $$ImagesTableCreateCompanionBuilder,
      $$ImagesTableUpdateCompanionBuilder,
      (Image, $$ImagesTableReferences),
      Image,
      PrefetchHooks Function({bool pointId})
    >;

class $TeleferikaDatabaseManager {
  final _$TeleferikaDatabase _db;
  $TeleferikaDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$PointsTableTableManager get points =>
      $$PointsTableTableManager(_db, _db.points);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db, _db.images);
}
