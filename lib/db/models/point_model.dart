// point_model.dart
// ... other imports

import 'package:teleferika/core/utils/uuid_generator.dart';
import 'dart:math' as math;

import 'image_model.dart'; // Ensure ImageModel is imported if not already

/// Represents a geographic point within a project.
///
/// Each point has coordinates (latitude, longitude, optional altitude),
/// an ordinal number for ordering within the project, and can contain
/// multiple images and notes.
class PointModel {
  final String id;
  final String projectId;
  final double latitude;
  final double longitude;
  final double? altitude; // New optional altitude field
  final int ordinalNumber;
  String? _note;
  final DateTime? timestamp;
  final List<ImageModel> _images; // Made private and immutable
  final bool isUnsaved; // Track if this is an unsaved new point

  // Getter for images
  List<ImageModel> get images => List.unmodifiable(_images);

  // Getter for note
  String get note => _note ?? '';

  // Setter for note that automatically removes trailing blank lines
  set note(String value) {
    if (value.trim().isEmpty) {
      _note = '';
    } else {
      // Remove trailing blank lines and trim whitespace
      _note = value.trim().replaceAll(RegExp(r'\n\s*$'), '');
    }
  }

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
    String? note,
    this.timestamp,
    List<ImageModel>? images,
    this.isUnsaved = false, // Default to false for existing points
  }) : id = id ?? generateUuid(),
       _images = images ?? [] {
    // Use the setter to ensure note is cleaned up
    this.note = note ?? '';
  }

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
    bool? isUnsaved,
  }) {
    final result = PointModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: clearAltitude ? null : altitude ?? this.altitude,
      // Handle clearAltitude
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      note: null,
      // Will be set below using the setter
      timestamp: clearTimestamp ? null : timestamp ?? this.timestamp,
      images: images ?? _images,
      isUnsaved: isUnsaved ?? this.isUnsaved,
    );

    // Use the setter to ensure note is cleaned up
    if (clearNote) {
      result.note = '';
    } else if (note != null) {
      result.note = note;
    } else {
      result.note = this.note;
    }

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnProjectId: projectId,
      columnLatitude: latitude,
      columnLongitude: longitude,
      columnAltitude: altitude, // Add to toMap
      columnOrdinalNumber: ordinalNumber,
      columnNote: note.isEmpty
          ? null
          : note, // Store null in DB for empty strings
      columnTimestamp: timestamp?.toIso8601String(),
    };
  }

  factory PointModel.fromMap(
    Map<String, dynamic> map, {
    List<ImageModel>? images,
  }) {
    final result = PointModel(
      id: map[columnId] as String,
      projectId: map[columnProjectId] as String,
      latitude: map[columnLatitude] as double,
      longitude: map[columnLongitude] as double,
      altitude: map[columnAltitude] as double?,
      // Add to fromMap
      ordinalNumber: map[columnOrdinalNumber] as int,
      note: null,
      // Will be set below using the setter
      timestamp: map[columnTimestamp] != null
          ? DateTime.tryParse(map[columnTimestamp] as String)
          : null,
      images: images ?? [],
      isUnsaved: false,
    );

    // Use the setter to ensure note is cleaned up
    result.note = map[columnNote] as String? ?? '';

    return result;
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
      altitude,
      // Add to hashCode
      ordinalNumber,
      note,
      timestamp,
      images.length, // Simplified images hash for brevity
    );
  }

  /// Returns the formatted name for this point (e.g., "P1", "P2", etc.)
  /// For unsaved points, returns "NEW"
  String get name => isUnsaved ? 'NEW' : 'P$ordinalNumber';

  /// Validates the point data
  bool get isValid {
    return id.isNotEmpty &&
        projectId.isNotEmpty &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        ordinalNumber >= 0 &&
        (altitude == null ||
            altitude! >= -1000 &&
                altitude! <= 8849); // Reasonable altitude range
  }

  /// Returns validation errors if any
  List<String> get validationErrors {
    final errors = <String>[];

    if (id.isEmpty) errors.add('Point ID cannot be empty');
    if (projectId.isEmpty) errors.add('Project ID cannot be empty');
    if (latitude < -90 || latitude > 90) {
      errors.add('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      errors.add('Longitude must be between -180 and 180');
    }
    if (ordinalNumber < 0) errors.add('Ordinal number must be non-negative');
    if (altitude != null && (altitude! < -1000 || altitude! > 8849)) {
      errors.add('Altitude must be between -1000 and 8849 meters');
    }

    return errors;
  }

  /// Calculates the 3D distance to another point using the Haversine formula for horizontal distance
  /// and Pythagorean theorem for the vertical component. Optionally, altitudes can be overridden.
  double distanceFromPoint(
    PointModel other, {
    double? altitude,
    double? otherAltitude,
  }) {
    // Calculate horizontal distance using Haversine formula
    const R = 6371000.0; // Earth's radius in meters
    final lat1Rad = _degreesToRadians(latitude);
    final lat2Rad = _degreesToRadians(other.latitude);
    final deltaLat = _degreesToRadians(other.latitude - latitude);
    final deltaLon = _degreesToRadians(other.longitude - longitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final horizontalDistance = R * c;

    // Calculate vertical distance
    final alt1 = altitude ?? this.altitude ?? 0.0;
    final alt2 = otherAltitude ?? other.altitude ?? 0.0;
    final verticalDistance = (alt2 - alt1).abs();

    // Calculate 3D distance using Pythagorean theorem
    return math.sqrt(
      horizontalDistance * horizontalDistance +
          verticalDistance * verticalDistance,
    );
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
}
