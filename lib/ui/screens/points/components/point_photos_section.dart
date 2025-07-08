import 'package:flutter/material.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/photo_manager_widget.dart';
import 'package:teleferika/core/project_provider.dart';

class PointPhotosSection extends StatefulWidget {
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
  State<PointPhotosSection> createState() => _PointPhotosSectionState();
}

class _PointPhotosSectionState extends State<PointPhotosSection> {
  VoidCallback? _addPhotoCallback;

  void _handleImageListChanged(List<dynamic> images) {
    widget.onImageListChangedForUI(images);
  }

  void _setAddPhotoCallback(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _addPhotoCallback = callback;
        });
      }
    });
  }

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
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final point = context.projectStateListen.getPointById(
                    widget.point.id,
                  );
                  final imageCount = point?.images.length ?? 0;
                  return Text(
                    '($imageCount)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_a_photo_outlined),
                tooltip:
                    S.of(context)?.photo_manager_add_photo_tooltip ??
                    'Add Photo',
                onPressed: _addPhotoCallback,
              ),
            ],
          ),
          const SizedBox(height: 16),
          PhotoManagerWidget(
            point: widget.point,
            onImageListChangedForUI: _handleImageListChanged,
            onPhotosSavedSuccessfully: widget.onPhotosSavedSuccessfully,
            setAddPhotoCallback: _setAddPhotoCallback,
          ),
        ],
      ),
    );
  }
}
