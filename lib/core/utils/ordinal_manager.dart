import 'package:teleferika/db/models/point_model.dart';

/// Pure Dart utility for managing point ordinals in-memory.
class OrdinalManager {
  /// Returns the next ordinal for a list of points.
  static int getNextOrdinal(List<PointModel> points) {
    if (points.isEmpty) return 0;
    return points.map((p) => p.ordinalNumber).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Resequences the list so ordinals are consecutive starting from 0.
  static List<PointModel> resequence(List<PointModel> points) {
    final sorted = List<PointModel>.from(points)
      ..sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));
    for (int i = 0; i < sorted.length; i++) {
      sorted[i] = sorted[i].copyWith(ordinalNumber: i);
    }
    return sorted;
  }

  /// Insert a point at a specific ordinal, shifting others.
  static List<PointModel> insertAtOrdinal(List<PointModel> points, PointModel newPoint, int ordinal) {
    final updated = List<PointModel>.from(points);
    updated.insert(ordinal, newPoint.copyWith(ordinalNumber: ordinal));
    return resequence(updated);
  }

  /// Remove a point by id and resequence.
  static List<PointModel> removeById(List<PointModel> points, String pointId) {
    final updated = List<PointModel>.from(points)..removeWhere((p) => p.id == pointId);
    return resequence(updated);
  }

  /// Move a point from oldIndex to newIndex and resequence.
  static List<PointModel> move(List<PointModel> points, int oldIndex, int newIndex) {
    final updated = List<PointModel>.from(points);
    final point = updated.removeAt(oldIndex);
    updated.insert(newIndex, point);
    return resequence(updated);
  }
} 