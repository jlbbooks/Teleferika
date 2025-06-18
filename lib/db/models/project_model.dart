// project_model.dart
class ProjectModel {
  final int? id;
  String name;
  int? startingPointId;
  int? endingPointId;
  double? azimuth;
  String? note;
  DateTime? lastUpdate;

  ProjectModel({
    this.id,
    required this.name,
    this.startingPointId,
    this.endingPointId,
    this.azimuth,
    this.note,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'starting_point_id': startingPointId,
      'ending_point_id': endingPointId,
      'azimuth': azimuth,
      'note': note,
      // Store DateTime as ISO8601 string or Unix timestamp (milliseconds)
      'last_update': lastUpdate?.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'],
      startingPointId: map['starting_point_id'],
      endingPointId: map['ending_point_id'],
      azimuth: map['azimuth'],
      note: map['note'],
      // Parse from ISO8601 string or Unix timestamp
      lastUpdate: map['last_update'] != null
          ? DateTime.tryParse(map['last_update']) // Handles if parsing fails
          : null,
    );
  }

  @override
  String toString() {
    return 'ProjectModel{id: $id, name: $name, startingPointId: $startingPointId, endingPointId: $endingPointId, azimuth: $azimuth, lastUpdate: $lastUpdate}';
  }
}
