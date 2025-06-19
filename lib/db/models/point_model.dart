// point.dart
class PointModel {
  final int? id;
  int projectId;
  double latitude;
  double longitude;
  int ordinalNumber;
  String? note;

  PointModel({
    this.id,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.ordinalNumber,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'latitude': latitude,
      'longitude': longitude,
      'ordinal_number': ordinalNumber,
      'note': note,
    };
  }

  factory PointModel.fromMap(Map<String, dynamic> map) {
    return PointModel(
      id: map['id'] as int?, // Ensure correct type casting from map
      projectId: map['project_id'] as int,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      ordinalNumber: map['ordinal_number'] as int,
      note: map['note'] as String?,
    );
  }

  @override
  String toString() {
    return 'Point{id: $id, projectId: $projectId, lat: $latitude, lon: $longitude, order: $ordinalNumber, note: $note}';
  }
}
