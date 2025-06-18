class ProjectModel {
  final int? id;
  String name;
  int? startingPointId;
  int? endingPointId;
  double? azimuth;

  ProjectModel({
    this.id,
    required this.name,
    this.startingPointId,
    this.endingPointId,
    this.azimuth,
  });

  // Convert a Project into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'starting_point_id': startingPointId,
      'ending_point_id': endingPointId,
      'azimuth': azimuth,
    };
  }

  // Implement fromMap if you need to convert from a Map back to a Project
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'],
      startingPointId: map['starting_point_id'],
      endingPointId: map['ending_point_id'],
      azimuth: map['azimuth'],
    );
  }

  @override
  String toString() {
    return 'Project{id: $id, name: $name, startingPointId: $startingPointId, endingPointId: $endingPointId, azimuth: $azimuth}';
  }
}
