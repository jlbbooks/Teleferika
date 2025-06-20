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

  void updateFromModel(ProjectModel other) {
    // Note: 'id' is final and set by the constructor.
    // This method is for updating the *mutable* fields of an existing instance
    // to match another instance (typically one fetched from the database).
    // If you need to change the ID, you should create a new ProjectModel instance
    // (e.g., using a copyWith method if you had one, or by direct instantiation).

    name = other.name;
    note = other.note;
    startingPointId = other.startingPointId;
    endingPointId = other.endingPointId;
    azimuth = other.azimuth;
    lastUpdate = other.lastUpdate; // Very important to update this
    date = other.date;
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
  ProjectModel copyWith({
    int? id, // Allow id to be explicitly part of copyWith if needed
    String? name,
    String? note,
    bool clearNote = false, // To explicitly set note to null
    int? startingPointId,
    bool clearStartingPointId = false,
    int? endingPointId,
    bool clearEndingPointId = false,
    double? azimuth,
    bool clearAzimuth = false,
    DateTime? lastUpdate,
    bool clearLastUpdate = false,
    DateTime? date,
    bool clearDate = false,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      note: clearNote ? null : (note ?? this.note),
      startingPointId: clearStartingPointId
          ? null
          : (startingPointId ?? this.startingPointId),
      endingPointId: clearEndingPointId
          ? null
          : (endingPointId ?? this.endingPointId),
      azimuth: clearAzimuth ? null : (azimuth ?? this.azimuth),
      lastUpdate: clearLastUpdate ? null : (lastUpdate ?? this.lastUpdate),
      date: clearDate ? null : (date ?? this.date),
    );
  }

  @override
  String toString() {
    return 'ProjectModel{id: $id, name: $name, note: $note, ..., date: $date, lastUpdate: $lastUpdate}';
  }

  // In ProjectModel class, corrected == operator for DateTime:
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProjectModel &&
        other.id == id &&
        other.name == name &&
        other.note == note &&
        other.startingPointId == startingPointId &&
        other.endingPointId == endingPointId &&
        other.azimuth == azimuth &&
        ((other.lastUpdate == null && lastUpdate == null) ||
            (other.lastUpdate != null &&
                lastUpdate != null &&
                other.lastUpdate!.isAtSameMomentAs(lastUpdate!))) &&
        ((other.date == null && date == null) ||
            (other.date != null &&
                date != null &&
                other.date!.isAtSameMomentAs(date!)));
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        note.hashCode ^
        startingPointId.hashCode ^
        endingPointId.hashCode ^
        azimuth.hashCode ^
        lastUpdate.hashCode ^
        date.hashCode;
  }
}
