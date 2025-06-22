// point_model.dart
import 'package:teleferika/utils/uuid_generator.dart';

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

  final String? id; // Changed from int? to String?
  final String projectId; // Changed from int to String (FK to ProjectModel)
  final double latitude;
  final double longitude;
  final int ordinalNumber;
  final String? note;
  final double? heading;
  final DateTime? timestamp;

  PointModel({
    String? id, // Parameter for id
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.ordinalNumber,
    this.note,
    this.heading,
    this.timestamp,
  }) : id = id ?? generateUuid(); // Generate UUID if id is null

  PointModel copyWith({
    String? id, // Changed
    String? projectId, // Changed
    double? latitude,
    double? longitude,
    int? ordinalNumber,
    String? note,
    bool clearNote = false, // Assuming you might want this pattern
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
      note: clearNote ? null : (note ?? this.note),
      heading: clearHeading ? null : (heading ?? this.heading),
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id, // String
      columnProjectId: projectId, // String
      columnLatitude: latitude,
      columnLongitude: longitude,
      columnOrdinalNumber: ordinalNumber,
      columnNote: note,
      columnHeading: heading,
      columnTimestamp: timestamp?.toIso8601String(),
    };
  }

  factory PointModel.fromMap(Map<String, dynamic> map) {
    return PointModel(
      id: map[columnId] as String?, // Cast to String
      projectId: map[columnProjectId] as String, // Cast to String
      latitude: map[columnLatitude] as double,
      longitude: map[columnLongitude] as double,
      ordinalNumber: map[columnOrdinalNumber] as int,
      note: map[columnNote] as String?,
      heading: map[columnHeading] as double?,
      timestamp: map[columnTimestamp] != null
          ? DateTime.tryParse(map[columnTimestamp] as String)
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
        other.id == id && // String comparison
        other.projectId == projectId && // String comparison
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
      id, // String
      projectId, // String
      latitude,
      longitude,
      ordinalNumber,
      note,
      heading,
      timestamp,
    );
  }
}
