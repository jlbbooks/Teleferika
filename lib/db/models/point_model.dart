// point_model.dart
// ... other imports

import 'package:teleferika/core/utils/uuid_generator.dart';

import 'image_model.dart'; // Ensure ImageModel is imported if not already

class PointModel {
  String id;
  String projectId;
  double latitude;
  double longitude;
  double? altitude; // New optional altitude field
  int ordinalNumber;
  String? note;
  DateTime? timestamp;
  List<ImageModel> images;

  // Database table and column names
  static const String tableName = 'points';
  static const String columnId = 'id';
  static const String columnProjectId = 'project_id';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnAltitude = 'altitude'; // New column name
  static const String columnOrdinalNumber = 'ordinal_number';
  static const String columnNote = 'note';
  static const String columnHeading = 'heading';
  static const String columnTimestamp = 'timestamp';

  PointModel({
    String? id,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    this.altitude, // Add to constructor
    required this.ordinalNumber,
    this.note,
    this.timestamp,
    List<ImageModel>? images,
  }) : this.id = id ?? generateUuid(),
       this.images = images ?? [];

  PointModel copyWith({
    String? id,
    String? projectId,
    double? latitude,
    double? longitude,
    double? altitude, // Add to copyWith
    bool clearAltitude = false, // Option to clear altitude
    int? ordinalNumber,
    String? note,
    bool clearNote = false,
    DateTime? timestamp,
    bool clearTimestamp = false,
    List<ImageModel>? images,
  }) {
    return PointModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: clearAltitude
          ? null
          : altitude ?? this.altitude, // Handle clearAltitude
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      note: clearNote ? null : note ?? this.note,
      timestamp: clearTimestamp ? null : timestamp ?? this.timestamp,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnProjectId: projectId,
      columnLatitude: latitude,
      columnLongitude: longitude,
      columnAltitude: altitude, // Add to toMap
      columnOrdinalNumber: ordinalNumber,
      columnNote: note,
      columnTimestamp: timestamp?.toIso8601String(),
    };
  }

  factory PointModel.fromMap(
    Map<String, dynamic> map, {
    List<ImageModel>? images,
  }) {
    return PointModel(
      id: map[columnId] as String,
      projectId: map[columnProjectId] as String,
      latitude: map[columnLatitude] as double,
      longitude: map[columnLongitude] as double,
      altitude: map[columnAltitude] as double?, // Add to fromMap
      ordinalNumber: map[columnOrdinalNumber] as int,
      note: map[columnNote] as String?,
      timestamp: map[columnTimestamp] != null
          ? DateTime.tryParse(map[columnTimestamp] as String)
          : null,
      images: images ?? [],
    );
  }

  @override
  String toString() {
    return 'PointModel(id: $id, projectId: $projectId, latitude: $latitude, longitude: $longitude, altitude: $altitude, ordinalNumber: $ordinalNumber, note: $note, timestamp: $timestamp, images: ${images.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PointModel &&
        other.id == id &&
        other.projectId == projectId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude && // Add to equality check
        other.ordinalNumber == ordinalNumber &&
        other.note == note &&
        other.timestamp == timestamp &&
        images.length ==
            other.images.length; // Simplified images check for brevity
    // For deep list equality, consider using listEquals from package:collection
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      projectId,
      latitude,
      longitude,
      altitude, // Add to hashCode
      ordinalNumber,
      note,
      timestamp,
      images.length, // Simplified images hash for brevity
    );
  }

  /// Returns the formatted name for this point (e.g., "P1", "P2", etc.)
  String get name => 'P$ordinalNumber';
}
