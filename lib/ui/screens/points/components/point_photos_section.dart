import 'package:flutter/material.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/photo_manager_widget.dart';

class PointPhotosSection extends StatelessWidget {
  final PointModel point;
  final Function(List<dynamic>) onImageListChangedForUI;
  final VoidCallback onPhotosSavedSuccessfully;

  const PointPhotosSection({
    super.key,
    required this.point,
    required this.onImageListChangedForUI,
    required this.onPhotosSavedSuccessfully,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                Icons.photo_library,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context)?.photos_section_title ?? 'Photos',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PhotoManagerWidget(
            // Pass a point model that reflects the current state of _currentImages
            // but for other fields, it uses the original widget.point data
            // This is important because PhotoManagerWidget's _savePointWithCurrentImages
            // will use widget.point.copyWith()
            point: point,
            onImageListChangedForUI: onImageListChangedForUI,
            onPhotosSavedSuccessfully: onPhotosSavedSuccessfully,
          ),
        ],
      ),
    );
  }
}
