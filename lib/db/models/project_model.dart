// db/models/project_model.dart
class ProjectModel {
  final int? id;
  String name;
  String? note;
  int? startingPointId;
  int? endingPointId;
  double? azimuth;
  DateTime? lastUpdate; // Tracks when the record was last modified in DB
  DateTime? date; // User-settable date for the project

  ProjectModel({
    this.id,
    required this.name,
    this.note,
    this.startingPointId,
    this.endingPointId,
    this.azimuth,
    this.lastUpdate,
    this.date, // Add to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'starting_point_id': startingPointId,
      'ending_point_id': endingPointId,
      'azimuth': azimuth,
      'last_update': lastUpdate?.toIso8601String(),
      'date': date?.toIso8601String(),
      // Store as ISO8601 string (date part only if desired, but full DateTime is fine)
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'],
      note: map['note'],
      startingPointId: map['starting_point_id'],
      endingPointId: map['ending_point_id'],
      azimuth: map['azimuth'],
      lastUpdate: map['last_update'] != null
          ? DateTime.tryParse(map['last_update'])
          : null,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) // Parse from ISO8601 string
          : null,
    );
  }

  @override
  String toString() {
    return 'ProjectModel{id: $id, name: $name, note: $note, ..., date: $date, lastUpdate: $lastUpdate}';
  }
}
