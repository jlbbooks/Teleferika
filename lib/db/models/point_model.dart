// point_model.dart
class PointModel {
  static const tableName = 'points';
  static const columnId = 'id';
  static const columnProjectId = 'project_id';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnOrdinalNumber = 'ordinal_number';
  static const columnNote = 'note';
  static const columnHeading = 'heading';
  static const columnTimestamp = 'timestamp';

  final int? id;
  final int projectId; // Make final
  final double latitude; // Make final
  final double longitude; // Make final
  final int ordinalNumber; // Make final
  final String? note; // Make final
  final double? heading; // Make final
  final DateTime? timestamp; // Make final

  PointModel({
    this.id,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.ordinalNumber,
    this.note,
    this.heading,
    this.timestamp,
  });

  /// Creates a new [PointModel] instance with optional new values.
  ///
  /// This method is useful for creating a modified copy of an existing
  /// [PointModel] instance without altering the original. If a parameter
  /// is not provided, its value is taken from the current instance.
  PointModel copyWith({
    int? id,
    int? projectId,
    double? latitude,
    double? longitude,
    int? ordinalNumber,
    String? note,
    // Add clear flags if explicit nullification is needed often, e.g.:
    bool clearNote = false,
    double? heading,
    bool clearHeading = false,
    DateTime? timestamp,
    bool clearTimestamp = false,
  }) {
    return PointModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      note: clearNote ? null : (note ?? this.note), // Example with clear flag
      // note: note ?? this.note, // Current behavior: null in copyWith means "no change"
      heading: clearHeading ? null : (heading ?? this.heading),
      // heading: heading ?? this.heading,
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      // timestamp: timestamp ?? this.timestamp,
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
      'heading': heading,
      'timestamp': timestamp?.toIso8601String(),
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
      heading: map['heading'] as double?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'PointModel{id: $id, projectId: $projectId, lat: $latitude, lon: $longitude, order: $ordinalNumber, note: $note, heading: $heading, timestamp: $timestamp}';
  }

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
        ((other.timestamp == null && timestamp == null) ||
            (other.timestamp != null &&
                timestamp != null &&
                other.timestamp!.isAtSameMomentAs(timestamp!)));
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      projectId,
      latitude,
      longitude,
      ordinalNumber,
      note,
      heading,
      timestamp,
    );
  }
}
