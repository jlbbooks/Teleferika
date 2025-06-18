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
      id: map['id'],
      projectId: map['project_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      ordinalNumber: map['ordinal_number'],
      note: map['note'],
    );
  }

  @override
  String toString() {
    return 'Point{id: $id, projectId: $projectId, lat: $latitude, lon: $longitude, order: $ordinalNumber, note: $note}';
  }
}
