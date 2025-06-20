// point.dart
class PointModel {
  final int? id;
  int projectId;
  double latitude;
  double longitude;
  int ordinalNumber;
  String? note;
  double? heading;
  DateTime? timestamp;

  PointModel({
    this.id,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.ordinalNumber,
    this.note, // TODO: what about the heading?????
    this.heading,
    this.timestamp,
  });

  /// Creates a new [PointModel] instance with optional new values.
  ///
  /// This method is useful for creating a modified copy of an existing
  /// [PointModel] instance without altering the original. If a parameter
  /// is not provided, its value is taken from the current instance.
  PointModel copyWith({
    int?
    id, // Usually, you don't copy `id` to a new instance unless it's for an update
    // where the ID must remain the same. If for a new object, ID should be null.
    // For "update" scenarios, it's fine. For "clone as new", omit it or pass null.
    int? projectId,
    double? latitude,
    double? longitude,
    int? ordinalNumber,
    String?
    note, // To clear a note, you'd pass an empty string or explicitly null
    double? heading,
    DateTime? timestamp,
  }) {
    return PointModel(
      id: id ?? this.id, // Keeps old id if not provided
      projectId: projectId ?? this.projectId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      note:
          note ?? this.note, // If `note` is null in copyWith, old note is kept.
      // To explicitly set note to null, you'd need a different mechanism
      // or accept that passing null to copyWith means "no change".
      // A common pattern is to use a special sentinel like Object() for "set to null".
      // However, for simplicity, this pattern is common: null means "no change".
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'latitude': latitude,
      'longitude': longitude,
      'ordinal_number': ordinalNumber,
      'note': note,
      'heading': heading, // Added
      'timestamp': timestamp?.toIso8601String(), // Store as ISO 8601 string
    };
  }

  factory PointModel.fromMap(Map<String, dynamic> map) {
    return PointModel(
      id: map['id'] as int?,
      projectId: map['project_id'] as int,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      ordinalNumber: map['ordinal_number'] as int,
      note: map['note'] as String?,
      heading: map['heading'] as double?, // Added
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null, // Parse from string
    );
  }

  @override
  String toString() {
    return 'Point{id: $id, projectId: $projectId, lat: $latitude, lon: $longitude, order: $ordinalNumber, note: $note, heading: $heading, timestamp: $timestamp}';
  }

  // --- Potentially useful: Equality and HashCode ---
  // If you plan to store PointModel in Sets or use them as Map keys,
  // or compare instances directly, overriding == and hashCode is crucial.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PointModel &&
        other.id == id &&
        other.projectId == projectId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.ordinalNumber == ordinalNumber &&
        other.note == note &&
        other.heading == heading &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        projectId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        ordinalNumber.hashCode ^
        note.hashCode ^
        heading.hashCode ^
        timestamp.hashCode;
  }
}
