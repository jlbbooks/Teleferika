// db/models/project_model.dart

import 'dart:math' as math;

import 'package:teleferika/core/utils/uuid_generator.dart';
import 'package:teleferika/db/models/point_model.dart';

/// Represents a photogrammetry project containing multiple geographic points.
///
/// A project has a name, optional notes, and contains an ordered list of points.
/// It can track starting and ending points, azimuth, and calculate total rope length
/// between consecutive points using 3D distance calculations.
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
  final String note;
  final String? startingPointId;
  final String? endingPointId;
  final double? azimuth;
  final DateTime? lastUpdate; // Tracks when the record was last modified in DB
  final DateTime? date; // User-settable date for the project
  final double? presumedTotalLength;
  final List<PointModel>
  _points; // In-memory list of points for this project (not persisted in DB)

  // Getter for points
  List<PointModel> get points => List.unmodifiable(_points);

  ProjectModel({
    String? id, // Default to generating a UUID if not provided
    required this.name,
    required this.note,
    this.startingPointId,
    this.endingPointId,
    this.azimuth,
    this.lastUpdate,
    this.date,
    List<PointModel>? points,
    this.presumedTotalLength,
  }) : id = id ?? generateUuid(),
       _points = points ?? const []; // Default to empty list

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnName: name,
      columnNote: note.isEmpty ? null : note,
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
      note: map[columnNote] as String? ?? '',
      // Convert null to empty string
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
    bool clearNote = false, // To explicitly set note to empty string
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
      note: clearNote ? '' : (note ?? this.note),
      startingPointId: clearStartingPointId
          ? null
          : (startingPointId ?? this.startingPointId),
      endingPointId: clearEndingPointId
          ? null
          : (endingPointId ?? this.endingPointId),
      azimuth: clearAzimuth ? null : (azimuth ?? this.azimuth),
      lastUpdate: clearLastUpdate ? null : (lastUpdate ?? this.lastUpdate),
      date: clearDate ? null : (date ?? this.date),
      points: points ?? this._points,
      presumedTotalLength: clearPresumedTotalLength
          ? null
          : (presumedTotalLength ?? this.presumedTotalLength),
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

  /// Calculates the total 3D distance between consecutive points in the project.
  /// Handles missing altitude data by interpolating between available altitudes.
  /// Returns 0 if no points or only one point exists.
  double get currentRopeLength {
    if (points.isEmpty || points.length == 1) {
      return 0.0;
    }

    double totalLength = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      final point1 = points[i];
      final point2 = points[i + 1];

      // Get altitudes with interpolation for missing values
      final altitude1 = _getInterpolatedAltitude(i);
      final altitude2 = _getInterpolatedAltitude(i + 1);

      // Calculate 3D distance between points
      final distance = _calculate3DDistance(
        point1.latitude,
        point1.longitude,
        altitude1,
        point2.latitude,
        point2.longitude,
        altitude2,
      );

      totalLength += distance;
    }

    return totalLength;
  }

  /// Gets the altitude for a point, interpolating if missing
  double _getInterpolatedAltitude(int pointIndex) {
    final point = points[pointIndex];

    // If the point has altitude data, use it
    if (point.altitude != null) {
      return point.altitude!;
    }

    // Try to interpolate from surrounding points
    double? prevAltitude;
    double? nextAltitude;

    // Find previous altitude
    for (int i = pointIndex - 1; i >= 0; i--) {
      if (points[i].altitude != null) {
        prevAltitude = points[i].altitude;
        break;
      }
    }

    // Find next altitude
    for (int i = pointIndex + 1; i < points.length; i++) {
      if (points[i].altitude != null) {
        nextAltitude = points[i].altitude;
        break;
      }
    }

    // If we have both previous and next altitudes, interpolate
    if (prevAltitude != null && nextAltitude != null) {
      return (prevAltitude + nextAltitude) / 2.0;
    }

    // If we only have one of them, use that
    if (prevAltitude != null) {
      return prevAltitude;
    }
    if (nextAltitude != null) {
      return nextAltitude;
    }

    // If no altitude data available anywhere, assume 0
    return 0.0;
  }

  /// Calculates 3D distance between two points using the Haversine formula for horizontal distance
  /// and Pythagorean theorem for the vertical component
  double _calculate3DDistance(
    double lat1,
    double lon1,
    double alt1,
    double lat2,
    double lon2,
    double alt2,
  ) {
    // Calculate horizontal distance using Haversine formula
    const R = 6371000.0; // Earth's radius in meters
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final deltaLat = _degreesToRadians(lat2 - lat1);
    final deltaLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final horizontalDistance = R * c;

    // Calculate vertical distance
    final verticalDistance = (alt2 - alt1).abs();

    // Calculate 3D distance using Pythagorean theorem
    return math.sqrt(
      horizontalDistance * horizontalDistance +
          verticalDistance * verticalDistance,
    );
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  /// Validates the project data
  bool get isValid {
    return id.isNotEmpty &&
        name.trim().isNotEmpty &&
        (presumedTotalLength == null || presumedTotalLength! >= 0) &&
        (azimuth == null || (azimuth! >= -360 && azimuth! < 360));
  }

  /// Returns validation errors if any
  List<String> get validationErrors {
    final errors = <String>[];

    if (id.isEmpty) errors.add('Project ID cannot be empty');
    if (name.trim().isEmpty) errors.add('Project name cannot be empty');
    if (presumedTotalLength != null && presumedTotalLength! < 0) {
      errors.add('Presumed total length must be non-negative');
    }
    if (azimuth != null && (azimuth! < -360 || azimuth! >= 360)) {
      errors.add('Azimuth must be between -360 and 360 degrees');
    }

    return errors;
  }
}
