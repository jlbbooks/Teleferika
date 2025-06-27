// db/models/project_model.dart

import 'package:teleferika/core/utils/uuid_generator.dart';
import 'package:teleferika/db/models/point_model.dart';

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
  static const String columnPresumedTotalLength = 'presumed_total_length';

  final String id;
  final String name;
  final String? note;
  final String? startingPointId;
  final String? endingPointId;
  final double? azimuth;
  final DateTime? lastUpdate; // Tracks when the record was last modified in DB
  final DateTime? date; // User-settable date for the project
  final double? presumedTotalLength;
  final List<PointModel>
  points; // In-memory list of points for this project (not persisted in DB)

  ProjectModel({
    String? id, // Default to generating a UUID if not provided
    required this.name,
    this.note,
    this.startingPointId,
    this.endingPointId,
    this.azimuth,
    this.lastUpdate,
    this.date,
    List<PointModel>? points,
    this.presumedTotalLength,
  }) : id = id ?? generateUuid(),
       points = points ?? const []; // Default to empty list

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
      columnPresumedTotalLength: presumedTotalLength,
      // points is not persisted in DB, so not included here
    };
  }

  factory ProjectModel.fromMap(
    Map<String, dynamic> map, {
    List<PointModel>? points,
  }) {
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
      points: points,
      presumedTotalLength: map[columnPresumedTotalLength] as double?,
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
    List<PointModel>? points,
    double? presumedTotalLength,
    bool clearPresumedTotalLength = false,
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
      points: points ?? this.points,
      presumedTotalLength: clearPresumedTotalLength ? null : (presumedTotalLength ?? this.presumedTotalLength),
    );
  }

  @override
  String toString() {
    return 'ProjectModel{id: $id, name: $name, note: $note, ..., date: $date, lastUpdate: $lastUpdate, points: ${points.length} points}';
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
                other.date!.isAtSameMomentAs(date!))) &&
        other.presumedTotalLength == presumedTotalLength &&
        _listEquals(other.points, points);
  }

  bool _listEquals(List<PointModel> a, List<PointModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    presumedTotalLength,
    Object.hashAll(points),
  );
}
