/// Geographic point model for cable crane line planning.
///
/// This class represents a geographic point within a project, containing
/// coordinates, metadata, and associated images. Points are used to define
/// the path of cable crane lines and store field measurements.
///
/// ## Features
/// - **Geographic Coordinates**: Latitude, longitude, and optional altitude
/// - **GPS Precision**: Optional GPS accuracy information
/// - **Ordering**: Ordinal numbers for sequence within projects
/// - **Metadata**: Notes, timestamps, and project association
/// - **Image Support**: Multiple images per point with ordering
/// - **Validation**: Built-in coordinate and data validation
///
/// ## Database Integration
/// The class includes database table and column name constants for
/// SQLite integration. It supports both serialization to/from maps
/// and direct database operations.
///
/// ## Usage Examples
///
/// ### Creating a new point:
/// ```dart
/// final point = PointModel(
///   projectId: 'project-123',
///   latitude: 45.12345,
///   longitude: 11.12345,
///   altitude: 1200.5,
///   ordinalNumber: 1,
///   note: 'Starting point of cable line',
/// );
/// ```
///
/// ### Calculating distance between points:
/// ```dart
/// double distance = point1.distanceFromPoint(point2);
/// ```
///
/// ### Working with images:
/// ```dart
/// List<ImageModel> images = point.images;
/// String note = point.note;
/// ```
///
/// ## Coordinate System
/// - **Latitude**: -90 to 90 degrees (WGS84)
/// - **Longitude**: -180 to 180 degrees (WGS84)
/// - **Altitude**: Optional, in meters above sea level
/// - **GPS Precision**: Optional, in meters
///
/// ## Validation
/// The class includes comprehensive validation for:
/// - Coordinate ranges
/// - Required field presence
/// - Altitude bounds (-1000 to 8849 meters)
/// - GPS precision (non-negative)
///
/// ## Immutability
/// The class is designed to be immutable. Use [PointModel.copyWith] to create
/// modified versions of points.

import 'package:teleferika/core/utils/uuid_generator.dart';
import 'dart:math' as math;

import 'image_model.dart'; // Ensure ImageModel is imported if not already

/// Represents a geographic point within a project.
///
/// Each point has coordinates (latitude, longitude, optional altitude),
/// an ordinal number for ordering within the project, and can contain
/// multiple images and notes.
class PointModel {
  /// Unique identifier for this point.
  ///
  /// Generated automatically using UUID v7 if not provided.
  /// Used for database primary key and internal references.
  final String id;

  /// Identifier of the project this point belongs to.
  ///
  /// Foreign key reference to the projects table.
  /// Required for database relationships and project organization.
  final String projectId;

  /// Latitude coordinate in decimal degrees (WGS84).
  ///
  /// Must be between -90 and 90 degrees.
  /// Positive values indicate North, negative values indicate South.
  final double latitude;

  /// Longitude coordinate in decimal degrees (WGS84).
  ///
  /// Must be between -180 and 180 degrees.
  /// Positive values indicate East, negative values indicate West.
  final double longitude;

  /// Optional altitude in meters above sea level.
  ///
  /// Can be null if altitude data is not available.
  /// When provided, should be between -1000 and 8849 meters.
  final double? altitude;

  /// Optional GPS precision/accuracy in meters.
  ///
  /// Represents the accuracy of the GPS measurement.
  /// Lower values indicate higher precision.
  /// Can be null if precision data is not available.
  final double? gpsPrecision;

  /// Sequential number for ordering points within a project.
  ///
  /// Used to maintain the order of points in cable crane lines.
  /// Points are typically numbered starting from 0 or 1.
  final int ordinalNumber;

  /// Private field for storing the point's note.
  ///
  /// Access through the public [note] getter/setter which
  /// provides automatic cleanup of trailing whitespace.
  String? _note;

  /// Optional timestamp when the point was created or last modified.
  ///
  /// Used for tracking when measurements were taken.
  /// Can be null for legacy data or when timestamp is not available.
  final DateTime? timestamp;

  /// Private list of images associated with this point.
  ///
  /// Made private to ensure immutability. Access through
  /// the public [images] getter which returns an unmodifiable list.
  final List<ImageModel> _images;

  /// Flag indicating if this point has not been saved to the database.
  ///
  /// Used to track unsaved changes and provide appropriate UI feedback.
  /// New points created in memory will have this set to true.
  final bool isUnsaved;

  /// Unmodifiable list of images associated with this point.
  ///
  /// Returns a read-only view of the internal image list.
  /// Images are ordered by their [ImageModel.ordinalNumber].
  ///
  /// To modify images, create a new [PointModel] using [PointModel.copyWith].
  List<ImageModel> get images => List.unmodifiable(_images);

  /// The point's note or description.
  ///
  /// Returns an empty string if no note is set.
  /// The note can contain observations, measurements, or other
  /// relevant information about the point.
  String get note => _note ?? '';

  /// Sets the point's note with automatic cleanup.
  ///
  /// The setter automatically:
  /// - Trims leading and trailing whitespace
  /// - Removes trailing blank lines
  /// - Converts empty strings to null for database storage
  ///
  /// This ensures consistent note formatting across the application.
  set note(String value) {
    if (value.trim().isEmpty) {
      _note = '';
    } else {
      // Remove trailing blank lines and trim whitespace
      _note = value.trim().replaceAll(RegExp(r'\n\s*$'), '');
    }
  }

  /// Database table and column name constants.
  ///
  /// These constants define the SQLite table structure for points.
  /// They are used by [DriftDatabaseHelper] for database operations.

  /// Name of the points table in the database.
  static const String tableName = 'points';

  /// Column name for the point's unique identifier.
  static const String columnId = 'id';

  /// Column name for the project foreign key reference.
  static const String columnProjectId = 'project_id';

  /// Column name for the latitude coordinate.
  static const String columnLatitude = 'latitude';

  /// Column name for the longitude coordinate.
  static const String columnLongitude = 'longitude';

  /// Column name for the altitude value.
  static const String columnAltitude = 'altitude';

  /// Column name for the GPS precision value.
  static const String columnGpsPrecision = 'gps_precision';

  /// Column name for the ordinal number.
  static const String columnOrdinalNumber = 'ordinal_number';

  /// Column name for the note text.
  static const String columnNote = 'note';

  /// Column name for the heading value (legacy, no longer used).
  ///
  /// This column was removed in database version 8 but kept for
  /// reference in case of migration issues.
  static const String columnHeading = 'heading';

  /// Column name for the timestamp.
  static const String columnTimestamp = 'timestamp';

  /// Creates a new [PointModel] instance.
  ///
  /// ## Required Parameters
  /// - [projectId]: The ID of the project this point belongs to
  /// - [latitude]: Latitude coordinate in decimal degrees (-90 to 90)
  /// - [longitude]: Longitude coordinate in decimal degrees (-180 to 180)
  /// - [ordinalNumber]: Sequential number for ordering within the project
  ///
  /// ## Optional Parameters
  /// - [id]: Unique identifier (auto-generated if not provided)
  /// - [altitude]: Altitude in meters above sea level
  /// - [gpsPrecision]: GPS accuracy in meters
  /// - [note]: Optional note or description
  /// - [timestamp]: When the point was created/modified
  /// - [images]: List of associated images
  /// - [isUnsaved]: Whether the point has been saved to database
  ///
  /// ## Validation
  /// The constructor does not perform validation. Use [isValid] to check
  /// if the point data is valid, or [validationErrors] to get specific issues.
  ///
  /// ## Examples
  /// ```dart
  /// // Create a basic point
  /// final point = PointModel(
  ///   projectId: 'project-123',
  ///   latitude: 45.12345,
  ///   longitude: 11.12345,
  ///   ordinalNumber: 1,
  /// );
  ///
  /// // Create a point with all data
  /// final point = PointModel(
  ///   projectId: 'project-123',
  ///   latitude: 45.12345,
  ///   longitude: 11.12345,
  ///   altitude: 1200.5,
  ///   gpsPrecision: 3.2,
  ///   ordinalNumber: 1,
  ///   note: 'Starting point',
  ///   timestamp: DateTime.now(),
  /// );
  /// ```
  PointModel({
    String? id,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.gpsPrecision,
    required this.ordinalNumber,
    String? note,
    this.timestamp,
    List<ImageModel>? images,
    this.isUnsaved = false,
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
    double? gpsPrecision, // Add to copyWith
    bool clearAltitude = false, // Option to clear altitude
    bool clearGpsPrecision = false, // Option to clear gpsPrecision
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
      gpsPrecision: clearGpsPrecision
          ? null
          : gpsPrecision ?? this.gpsPrecision,
      // Handle clearAltitude and clearGpsPrecision
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
      columnGpsPrecision: gpsPrecision, // Add to toMap
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
      gpsPrecision: map[columnGpsPrecision] as double?,
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
    return 'PointModel(id: $id, projectId: $projectId, latitude: $latitude, longitude: $longitude, altitude: $altitude, gpsPrecision: $gpsPrecision, ordinalNumber: $ordinalNumber, note: $note, timestamp: $timestamp, images: ${images.length})';
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
        other.gpsPrecision == gpsPrecision && // Add to equality check
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
      gpsPrecision,
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
    if (gpsPrecision != null && gpsPrecision! < 0) {
      errors.add('GPS precision must be non-negative');
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
