import 'package:flutter/material.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/map/map_controller.dart';
import 'package:teleferika/map/services/geometry_service.dart';

class PointAdditionalDataSection extends StatelessWidget {
  final TextEditingController altitudeController;
  final TextEditingController noteController;
  final PointModel point;

  const PointAdditionalDataSection({
    super.key,
    required this.altitudeController,
    required this.noteController,
    required this.point,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context)?.additional_data_section_title ??
                    'Additional Data',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Altitude
          TextFormField(
            controller: altitudeController,
            decoration: InputDecoration(
              labelText: S.of(context)?.altitude_label ?? 'Altitude (m)',
              hintText:
                  S.of(context)?.altitude_hint ?? 'e.g. 1203.5 (Optional)',
              prefixIcon: Icon(
                AppConfig.altitudeIcon,
                color: AppConfig.altitudeColor,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true, // Allow negative values
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null; // Altitude is optional
              }
              final n = double.tryParse(value);
              if (n == null) {
                return S.of(context)?.altitude_invalid_validator ??
                    'Invalid number format';
              }
              if (n < -1000 || n > 8849) {
                return S.of(context)?.altitude_range_validator ??
                    'Altitude must be between -1000 and 8849 meters';
              }
              return null;
            },
          ),
          // Distance from previous point
          Builder(
            builder: (context) {
              final points = context.projectState.currentPoints;
              final selected = point;
              final idx = points.indexWhere((p) => p.id == selected.id);
              if (idx <= 0) return SizedBox.shrink();
              final prev = points[idx - 1];
              final dist = prev.distanceFromPoint(selected);
              String distStr;
              if (dist >= 1000) {
                distStr = '${(dist / 1000).toStringAsFixed(2)} km';
              } else {
                distStr = '${dist.toStringAsFixed(1)} m';
              }
              return Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8),
                    Text(
                      S.of(context)?.distanceFromPrevious(prev.name) ??
                          'Distance from ${prev.name}:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      distStr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Offset
          Builder(
            builder: (context) {
              final points = context.projectState.currentPoints;
              double? distanceToLine;
              if (points.length >= 2) {
                final logic = MapControllerLogic(
                  project: context.projectState.currentProject!,
                  projectState: context.projectState,
                );
                distanceToLine = logic.distanceFromPointToFirstLastLine(
                  point,
                  points,
                );
              }
              String? distanceToLineStr;
              if (distanceToLine != null) {
                if (distanceToLine >= 1000) {
                  distanceToLineStr =
                      '${(distanceToLine / 1000).toStringAsFixed(2)} km';
                } else {
                  distanceToLineStr = '${distanceToLine.toStringAsFixed(1)} m';
                }
              }
              if (distanceToLine == null || distanceToLine <= 0.0) {
                return SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8),
                    Text(
                      S.of(context)?.offsetLabel ?? 'Offset:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      distanceToLineStr ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Angle
          Builder(
            builder: (context) {
              final points = context.projectState.currentPoints;
              if (points.length < 3) {
                return const SizedBox.shrink();
              }

              final geometryService = GeometryService(
                project: context.projectState.currentProject!,
              );
              final angle = geometryService.calculateAngleAtPoint(
                point,
                points,
              );

              if (angle == null) return const SizedBox.shrink();

              final angleColor = geometryService.getPointColor(point, points);

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.rotate_right, size: 18, color: angleColor),
                    SizedBox(width: 8),
                    Text(
                      S.of(context)?.angleLabel ?? 'Angle:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${angle.toStringAsFixed(1)}°',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: angleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Note
          TextFormField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: S.of(context)?.note_label ?? 'Note (Optional)',
              hintText:
                  S.of(context)?.note_hint ?? 'Any observations or details...',
              prefixIcon: Icon(
                Icons.notes_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.all(16.0),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
