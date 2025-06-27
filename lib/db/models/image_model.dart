// image_model.dart

import 'package:teleferika/core/utils/uuid_generator.dart';

class ImageModel {
  static const tableName = 'images';
  static const columnId = 'id';
  static const columnPointId = 'point_id'; // FK to PointModel
  static const columnOrdinalNumber = 'ordinal_number';
  static const columnImagePath = 'image_path';

  final String? id; // Changed from int? to String?
  final String pointId; // Changed from int to String (FK to PointModel.id)
  final int ordinalNumber; // Keep as int, represents order within a point
  final String imagePath;

  // Renamed to ImageModel to avoid conflict with dart:ui Image
  ImageModel({
    String? id, // Parameter for id
    required this.pointId,
    required this.ordinalNumber,
    required this.imagePath,
  }) : id = id ?? generateUuid(); // Generate UUID if id is null

  Map<String, dynamic> toMap() {
    return {
      columnId: id, // String
      columnPointId: pointId, // String
      columnOrdinalNumber: ordinalNumber,
      columnImagePath: imagePath,
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map[columnId] as String?, // Cast to String
      pointId: map[columnPointId] as String, // Cast to String
      ordinalNumber: map[columnOrdinalNumber] as int,
      imagePath: map[columnImagePath] as String,
    );
  }

  ImageModel copyWith({
    String? id, // Changed
    String? pointId, // Changed
    int? ordinalNumber,
    String? imagePath,
  }) {
    return ImageModel(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'ImageModel{id: $id, pointId: $pointId, order: $ordinalNumber, path: $imagePath}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageModel &&
        other.id == id && // String comparison
        other.pointId == pointId && // String comparison
        other.ordinalNumber == ordinalNumber &&
        other.imagePath == imagePath;
  }

  @override
  int get hashCode => Object.hash(
    id, // String
    pointId, // String
    ordinalNumber,
    imagePath,
  );
}
