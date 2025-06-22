// point_model.dart
import 'package:teleferika/utils/uuid_generator.dart';

import 'image_model.dart';

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

  final String? id;
  final String projectId;
  final double latitude;
  final double longitude;
  final int ordinalNumber;
  final String? note;
  final double? heading;
  final DateTime? timestamp;
  final List<ImageModel> images;

  PointModel({
    String? id, // Parameter for id
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.ordinalNumber,
    this.note,
    this.heading,
    this.timestamp,
    this.images = const [],
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
    List<ImageModel>? images,
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
      images: images ?? this.images,
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

  factory PointModel.fromMap(
    Map<String, dynamic> map, {
    List<ImageModel> images = const [],
  }) {
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
      images: images,
    );
  }

  @override
  String toString() {
    return 'PointModel{id: $id, projectId: $projectId, lat: $latitude, lon: $longitude, order: $ordinalNumber, note: $note, heading: $heading, timestamp: $timestamp, images: ${images.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // For list comparison, you might need a deep equality check if order and content matter.
    // Flutter's foundation.listEquals can be used.
    // For simplicity here, I'm checking instance equality of the list reference and length,
    // but for true value equality of lists of complex objects, more is needed.
    // However, usually for == on entities, primary fields are sufficient.
    // The list of images often changes independently and might not be part of the core equality.
    // Let's include basic list equality for now.
    // Consider if you need a more robust list comparison (e.g., listEquals from package:collection/collection.dart)

    // For a simple check, we can compare the string representations of the image lists
    // or rely on the fact that if all other fields are the same, and if images are
    // loaded and managed consistently, they *should* be the same if the point is the same.
    // A robust list equality is tricky here without external packages or more code.
    // Let's stick to comparing core fields for now, as image lists might be dynamically loaded.
    // You can add a listEquals check if it's crucial for your use case of ==.
    // Example: import 'package:collection/collection.dart'; // and then listEquals(other.images, images)
    // For now, keeping it simpler:
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
                other.timestamp!.isAtSameMomentAs(timestamp!))) &&
        // Basic check for images; for deep equality, use collection.listEquals
        other.images.length == images.length; // Simple length check for now
    // If deep equality needed: listEquals(other.images, images) (requires import)
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
      images.length,
    );
  }
}
