// drift_converters.dart
//
// Converter classes that map between Drift table rows/companions and app
// model classes. Reduces boilerplate and centralizes conversion logic
// (CODE_REVIEW_RECOMMENDATIONS.md point 8).

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import 'package:teleferika/db/database.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

/// Shared helpers for optional Drift [Value] fields to reduce repetition.
abstract class _ValueHelpers {
  static Value<String?> optionalNote(String note) =>
      Value(note.isEmpty ? null : note);

  static Value<String?> optionalIsoDate(DateTime? d) =>
      Value(d?.toIso8601String());

  static DateTime? parseDateTime(String? s) =>
      s != null ? DateTime.tryParse(s) : null;
}

/// Base contract for converting between a model and its Drift companion.
/// Entity-specific converters implement [toCompanion]; [fromDrift] signatures
/// vary (e.g. Project needs points, Point needs images).
abstract class DriftConverter<TModel, TCompanion> {
  TCompanion toCompanion(TModel model);
}

/// Converts between [Project] / [ProjectCompanion] and [ProjectModel].
class ProjectConverter implements DriftConverter<ProjectModel, ProjectCompanion> {
  ProjectConverter({Logger? logger}) : _logger = logger ?? Logger('ProjectConverter');

  final Logger _logger;

  ProjectModel fromDrift(Project project, List<PointModel> points) {
    _logger.fine('Converting Drift Project to ProjectModel: ${project.name}');
    return ProjectModel(
      id: project.id,
      name: project.name,
      note: project.note ?? '',
      azimuth: project.azimuth,
      lastUpdate: _ValueHelpers.parseDateTime(project.lastUpdate),
      date: _ValueHelpers.parseDateTime(project.date),
      points: points,
      presumedTotalLength: project.presumedTotalLength,
      cableEquipmentTypeId: project.cableEquipmentTypeId,
      profileChartHeight: project.profileChartHeight,
      planProfileChartHeight: project.planProfileChartHeight,
    );
  }

  @override
  ProjectCompanion toCompanion(ProjectModel project) {
    _logger.fine(
      'Converting ProjectModel to ProjectCompanion: ${project.name}',
    );
    return ProjectCompanion(
      id: Value(project.id),
      name: Value(project.name),
      note: _ValueHelpers.optionalNote(project.note),
      azimuth: Value(project.azimuth),
      lastUpdate: _ValueHelpers.optionalIsoDate(project.lastUpdate),
      date: _ValueHelpers.optionalIsoDate(project.date),
      presumedTotalLength: Value(project.presumedTotalLength),
      cableEquipmentTypeId: Value(project.cableEquipmentTypeId),
      profileChartHeight: Value(project.profileChartHeight),
      planProfileChartHeight: Value(project.planProfileChartHeight),
    );
  }
}

/// Converts between [Point] / [PointCompanion] and [PointModel].
/// Depends on [ImageConverter] for point images.
class PointConverter implements DriftConverter<PointModel, PointCompanion> {
  PointConverter({
    Logger? logger,
    ImageConverter? imageConverter,
  })  : _logger = logger ?? Logger('PointConverter'),
        _imageConverter = imageConverter ?? ImageConverter(logger: logger);

  final Logger _logger;
  final ImageConverter _imageConverter;

  PointModel fromDrift(Point point, List<Image> images) {
    _logger.fine('Converting Drift Point to PointModel: ${point.id}');
    return PointModel(
      id: point.id,
      projectId: point.projectId,
      latitude: point.latitude,
      longitude: point.longitude,
      altitude: point.altitude,
      gpsPrecision: point.gpsPrecision,
      ordinalNumber: point.ordinalNumber,
      note: point.note ?? '',
      timestamp: _ValueHelpers.parseDateTime(point.timestamp),
      images: images.map(_imageConverter.fromDrift).toList(),
    );
  }

  @override
  PointCompanion toCompanion(PointModel point) {
    _logger.fine('Converting PointModel to PointCompanion: ${point.id}');
    return PointCompanion(
      id: Value(point.id),
      projectId: Value(point.projectId),
      latitude: Value(point.latitude),
      longitude: Value(point.longitude),
      altitude: Value(point.altitude),
      gpsPrecision: Value(point.gpsPrecision),
      ordinalNumber: Value(point.ordinalNumber),
      note: _ValueHelpers.optionalNote(point.note),
      timestamp: _ValueHelpers.optionalIsoDate(point.timestamp),
    );
  }
}

/// Converts between [Image] / [ImageCompanion] and [ImageModel].
class ImageConverter implements DriftConverter<ImageModel, ImageCompanion> {
  ImageConverter({Logger? logger}) : _logger = logger ?? Logger('ImageConverter');

  final Logger _logger;

  ImageModel fromDrift(Image image) {
    _logger.fine('Converting Drift Image to ImageModel: ${image.id}');
    return ImageModel(
      id: image.id,
      pointId: image.pointId,
      ordinalNumber: image.ordinalNumber,
      imagePath: image.imagePath,
      note: image.note ?? '',
    );
  }

  @override
  ImageCompanion toCompanion(ImageModel image) {
    _logger.fine('Converting ImageModel to ImageCompanion: ${image.id}');
    return ImageCompanion(
      id: Value(image.id),
      pointId: Value(image.pointId),
      ordinalNumber: Value(image.ordinalNumber),
      imagePath: Value(image.imagePath),
      note: _ValueHelpers.optionalNote(image.note),
    );
  }
}
