// db/models/project_model.dart

import 'package:teleferika/core/utils/uuid_generator.dart';

class ProjectModel {
  static const String tableName = 'projects';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnNote = 'note';
  static const String columnStartingPointId = 'starting_point_id';
  static const String columnEndingPointId = 'ending_point_id';
  static const String columnAzimuth = 'azimuth';
  static const String columnLastUpdate = 'last_update';
  static const String columnDate = 'date';

  final String id;
  final String name;
  final String? note;
  final String? startingPointId;
  final String? endingPointId;
  final double? azimuth;
  final DateTime? lastUpdate; // Tracks when the record was last modified in DB
  final DateTime? date; // User-settable date for the project

  ProjectModel({
    String? id, // Default to generating a UUID if not provided
    required this.name,
    this.note,
    this.startingPointId,
    this.endingPointId,
    this.azimuth,
    this.lastUpdate,
    this.date,
  }) : id = id ?? generateUuid(); // Generate UUID if id is null

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnName: name,
      columnNote: note,
      columnStartingPointId: startingPointId,
      columnEndingPointId: endingPointId,
      columnAzimuth: azimuth,
      columnLastUpdate: lastUpdate?.toIso8601String(),
      columnDate: date?.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map[columnId] as String?,
      name: map[columnName] as String,
      note: map[columnNote] as String?,
      startingPointId: map[columnStartingPointId] as String?,
      endingPointId: map[columnEndingPointId] as String?,
      azimuth: map[columnAzimuth] as double?,
      lastUpdate: map[columnLastUpdate] != null
          ? DateTime.tryParse(map[columnLastUpdate] as String)
          : null,
      date: map[columnDate] != null
          ? DateTime.tryParse(map[columnDate] as String)
          : null,
    );
  }
  ProjectModel copyWith({
    String? id, // Allow id to be explicitly part of copyWith if needed
    String? name,
    String? note,
    bool clearNote = false, // To explicitly set note to null
    String? startingPointId,
    bool clearStartingPointId = false,
    String? endingPointId,
    bool clearEndingPointId = false,
    double? azimuth,
    bool clearAzimuth = false,
    DateTime? lastUpdate,
    bool clearLastUpdate = false,
    DateTime? date,
    bool clearDate = false,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      note: clearNote ? null : (note ?? this.note),
      startingPointId: clearStartingPointId
          ? null
          : (startingPointId ?? this.startingPointId),
      endingPointId: clearEndingPointId
          ? null
          : (endingPointId ?? this.endingPointId),
      azimuth: clearAzimuth ? null : (azimuth ?? this.azimuth),
      lastUpdate: clearLastUpdate ? null : (lastUpdate ?? this.lastUpdate),
      date: clearDate ? null : (date ?? this.date),
    );
  }

  @override
  String toString() {
    return 'ProjectModel{id: $id, name: $name, note: $note, ..., date: $date, lastUpdate: $lastUpdate}';
  }

  // In ProjectModel class, corrected == operator for DateTime:
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProjectModel &&
        other.id == id &&
        other.name == name &&
        other.note == note &&
        other.startingPointId == startingPointId &&
        other.endingPointId == endingPointId &&
        other.azimuth == azimuth &&
        ((other.lastUpdate == null && lastUpdate == null) ||
            (other.lastUpdate != null &&
                lastUpdate != null &&
                other.lastUpdate!.isAtSameMomentAs(lastUpdate!))) &&
        ((other.date == null && date == null) ||
            (other.date != null &&
                date != null &&
                other.date!.isAtSameMomentAs(date!)));
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    note,
    startingPointId,
    endingPointId,
    azimuth,
    lastUpdate,
    date,
  );
}
