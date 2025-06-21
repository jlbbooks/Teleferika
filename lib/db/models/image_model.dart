// image.dart
class ImageModel {
  static const tableName = 'images';
  static const columnId = 'id';
  static const columnPointId = 'point_id';
  static const columnOrdinalNumber = 'ordinal_number';
  static const columnImagePath = 'image_path';

  // Renamed to ImageModel to avoid conflict with dart:ui Image
  final int? id;
  int pointId;
  int ordinalNumber;
  String imagePath;

  ImageModel({
    this.id,
    required this.pointId,
    required this.ordinalNumber,
    required this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'point_id': pointId,
      'ordinal_number': ordinalNumber,
      'image_path': imagePath,
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'],
      pointId: map['point_id'],
      ordinalNumber: map['ordinal_number'],
      imagePath: map['image_path'],
    );
  }

  @override
  String toString() {
    return 'ImageModel{id: $id, pointId: $pointId, order: $ordinalNumber, path: $imagePath}';
  }
}
