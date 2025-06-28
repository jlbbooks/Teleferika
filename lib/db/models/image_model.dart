// image_model.dart

import 'package:teleferika/core/utils/uuid_generator.dart';

/// Represents an image associated with a geographic point.
/// 
/// Each image has a path to the file, an ordinal number for ordering
/// within the point, and can contain notes. Images are linked to
/// points via the pointId foreign key.
class ImageModel {
  static const tableName = 'images';
  static const columnId = 'id';
  static const columnPointId = 'point_id'; // FK to PointModel
  static const columnOrdinalNumber = 'ordinal_number';
  static const columnImagePath = 'image_path';
  static const columnNote = 'note'; // New note column

  final String id; // Changed to non-nullable String
  final String pointId; // FK to PointModel.id
  final int ordinalNumber; // Keep as int, represents order within a point
  final String imagePath;
  String? _note; // Private field for note

  // Getter for note
  String get note => _note ?? '';

  // Setter for note that automatically removes trailing blank lines
  set note(String value) {
    if (value.trim().isEmpty) {
      _note = '';
    } else {
      // Remove trailing blank lines and trim whitespace
      _note = value.trim().replaceAll(RegExp(r'\n\s*$'), '');
    }
  }

  // Renamed to ImageModel to avoid conflict with dart:ui Image
  ImageModel({
    String? id, // Parameter for id
    required this.pointId,
    required this.ordinalNumber,
    required this.imagePath,
    String? note,
  }) : id = id ?? generateUuid(), // Generate UUID if id is null
       _note = null { // Will be set below using the setter
    // Use the setter to ensure note is cleaned up
    this.note = note ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id, // String
      columnPointId: pointId, // String
      columnOrdinalNumber: ordinalNumber,
      columnImagePath: imagePath,
      columnNote: note.isEmpty ? null : note, // Store null in DB for empty strings
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    final result = ImageModel(
      id: map[columnId] as String, // Cast to non-nullable String
      pointId: map[columnPointId] as String, // Cast to String
      ordinalNumber: map[columnOrdinalNumber] as int,
      imagePath: map[columnImagePath] as String,
      note: null, // Will be set below using the setter
    );
    
    // Use the setter to ensure note is cleaned up
    result.note = map[columnNote] as String? ?? '';
    
    return result;
  }

  ImageModel copyWith({
    String? id, // Changed
    String? pointId, // Changed
    int? ordinalNumber,
    String? imagePath,
    String? note,
    bool clearNote = false,
  }) {
    final result = ImageModel(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      ordinalNumber: ordinalNumber ?? this.ordinalNumber,
      imagePath: imagePath ?? this.imagePath,
      note: null, // Will be set below using the setter
    );
    
    // Use the setter to ensure note is cleaned up
    if (clearNote) {
      result.note = '';
    } else if (note != null) {
      result.note = note;
    } else {
      result.note = this.note;
    }
    
    return result;
  }

  @override
  String toString() {
    return 'ImageModel{id: $id, pointId: $pointId, order: $ordinalNumber, path: $imagePath, note: $note}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageModel &&
        other.id == id && // String comparison
        other.pointId == pointId && // String comparison
        other.ordinalNumber == ordinalNumber &&
        other.imagePath == imagePath &&
        other.note == note; // Add note comparison
  }

  @override
  int get hashCode => Object.hash(
    id, // String
    pointId, // String
    ordinalNumber,
    imagePath,
    note, // Add note to hashCode
  );

  /// Validates the image data
  bool get isValid {
    return id.isNotEmpty &&
           pointId.isNotEmpty &&
           ordinalNumber >= 0 &&
           imagePath.isNotEmpty;
  }

  /// Returns validation errors if any
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('Image ID cannot be empty');
    if (pointId.isEmpty) errors.add('Point ID cannot be empty');
    if (ordinalNumber < 0) errors.add('Ordinal number must be non-negative');
    if (imagePath.isEmpty) errors.add('Image path cannot be empty');
    
    return errors;
  }
}
