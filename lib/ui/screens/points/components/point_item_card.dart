import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/map/map_controller.dart';
import 'package:teleferika/map/services/geometry_service.dart';
import 'package:teleferika/ui/screens/points/point_editor_screen.dart';
import 'package:teleferika/ui/widgets/photo_gallery_dialog.dart';
import 'dart:io';

class PointItemCard extends StatelessWidget {
  final PointModel point;
  final int index;
  final ProjectModel project;
  final bool isSelectionMode;
  final bool isSelectedForDelete;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleExpanded;

  const PointItemCard({
    super.key,
    required this.point,
    required this.index,
    required this.project,
    required this.isSelectionMode,
    required this.isSelectedForDelete,
    required this.isExpanded,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final points = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    ).currentPoints;

    // Get previous point if exists
    PointModel? prevPoint;
    if (index > 0 && index < points.length) {
      prevPoint = points[index - 1];
    }

    // Calculate distance from previous point
    double? distanceFromPrev;
    if (prevPoint != null) {
      distanceFromPrev = point.distanceFromPoint(prevPoint);
    }

    // Offset from heading line
    double? offset;
    if (points.length >= 2) {
      final logic = MapControllerLogic(project: project);
      offset = logic.distanceFromPointToFirstLastLine(point, points);
    }

    final Color baseSelectionColor = Theme.of(context).primaryColorLight;
    const double selectedOpacity = 0.3;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      elevation: isSelectionMode && isSelectedForDelete ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        side: isSelectionMode && isSelectedForDelete
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: isSelectionMode && isSelectedForDelete
          ? baseSelectionColor.withAlpha((selectedOpacity * 255).round())
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8.0),
        child: Column(
          children: [
            _buildHeader(context),
            _buildBasicInfo(context, distanceFromPrev, offset, points),
            _buildExpandedSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Drag handle (only when not in selection mode)
        if (!isSelectionMode)
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(Icons.drag_handle, color: Colors.grey, size: 24),
            ),
          ),
        // Edit icon on the left
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blueGrey),
          tooltip: S.of(context)?.edit_point_title ?? 'Edit Point',
          onPressed: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => PointEditorScreen(point: point),
              ),
            );
            if (result != null && context.mounted) {
              final String? action = result['action'] as String?;
              final PointModel? updatedPoint = result['point'] as PointModel?;
              if ((action == 'updated' || action == 'created') &&
                  updatedPoint != null) {
                // Use Provider to update global state
                context.projectState.updatePointInEditingState(updatedPoint);
              }
            }
          },
        ),
        Expanded(
          child: Center(
            child: Text(
              point.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          onPressed: onToggleExpanded,
          tooltip: isExpanded ? 'Collapse' : 'Expand',
        ),
      ],
    );
  }

  Widget _buildBasicInfo(
    BuildContext context,
    double? distanceFromPrev,
    double? offset,
    List<PointModel> points,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance
          if (distanceFromPrev != null && index > 0 && index < points.length)
            Row(
              children: [
                const Icon(Icons.swap_horiz, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  '${S.of(context)?.distanceFromPrevious(points[index - 1].name) ?? 'Distance:'} ${distanceFromPrev >= 1000 ? '${(distanceFromPrev / 1000).toStringAsFixed(2)} ${S.of(context)?.unit_kilometer ?? 'km'}' : '${distanceFromPrev.toStringAsFixed(1)} ${S.of(context)?.unit_meter ?? 'm'}'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          // Offset
          if (offset != null && offset > 0.0)
            Row(
              children: [
                const Icon(
                  Icons.straighten,
                  size: 18,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  ('${S.of(context)?.offsetLabel ?? 'Offset:'} ') +
                      (offset >= 1000
                          ? '${(offset / 1000).toStringAsFixed(2)} ${S.of(context)?.unit_kilometer ?? 'km'}'
                          : '${offset.toStringAsFixed(1)} ${S.of(context)?.unit_meter ?? 'm'}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          // Angle
          Builder(
            builder: (context) {
              if (points.length < 3) return const SizedBox.shrink();

              final geometryService = GeometryService(
                project: context.projectState.currentProject!,
              );
              final angle = geometryService.calculateAngleAtPoint(
                point,
                points,
              );

              if (angle == null) return const SizedBox.shrink();

              final angleColor = geometryService.getPointColor(point, points);

              return Row(
                children: [
                  Icon(Icons.rotate_right, size: 18, color: angleColor),
                  const SizedBox(width: 6),
                  Text(
                    '${S.of(context)?.angleLabel ?? 'Angle:'} ${angle.toStringAsFixed(1)}°',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: angleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Latitude
            Row(
              children: [
                Icon(
                  AppConfig.latitudeIcon,
                  size: 18,
                  color: AppConfig.latitudeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${S.of(context)?.latitude_label ?? 'Lat'}: ${point.latitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            // Longitude
            Row(
              children: [
                Icon(
                  AppConfig.longitudeIcon,
                  size: 18,
                  color: AppConfig.longitudeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  ('${S.of(context)?.longitude_label ?? 'Lon:'}: ') +
                      point.longitude.toStringAsFixed(5),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            // Altitude
            if (point.altitude != null)
              Row(
                children: [
                  Icon(
                    AppConfig.altitudeIcon,
                    size: 18,
                    color: AppConfig.altitudeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${S.of(context)?.altitude_label ?? 'Alt:'}: ${point.altitude!.toStringAsFixed(2)} ${S.of(context)?.unit_meter ?? 'm'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            // Full note (untruncated)
            if (point.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 18, color: Colors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        point.note,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            // Images (miniatures)
            if (point.images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: point.images.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, imgIdx) {
                      final img = point.images[imgIdx];
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => PhotoGalleryDialog(
                              pointId: point.id,
                              initialIndex: imgIdx,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image(
                                image: FileImage(File(img.imagePath)),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                frameBuilder:
                                    (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      if (wasSynchronouslyLoaded ||
                                          frame != null) {
                                        return child;
                                      } else {
                                        return const Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            S.of(context)?.errorGeneric ??
                                                'Error',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ),
                              // Note icon overlay (bottom right)
                              if (img.note.isNotEmpty)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.sticky_note_2,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      crossFadeState: isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }
}
