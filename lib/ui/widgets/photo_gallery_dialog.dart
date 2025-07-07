import 'dart:io';

import 'package:flutter/material.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// Shared note edit dialog widget
class NoteEditDialog extends StatefulWidget {
  final String initialNote;

  const NoteEditDialog({super.key, required this.initialNote});

  @override
  State<NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<NoteEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and conditional title
            Row(
              children: [
                Icon(Icons.sticky_note_2, color: Colors.white, size: 24),
                if (widget.initialNote.isEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s?.addANote ?? 'Add a note',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text field
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
              ),
              maxLines: 5,
              autofocus: true,
              cursorColor: Colors.white,
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    s?.buttonCancel ?? 'Cancel',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(s?.save ?? 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// PhotoGalleryDialog widget for fullscreen preview
class PhotoGalleryDialog extends StatefulWidget {
  final String pointId;
  final int initialIndex;

  const PhotoGalleryDialog({
    super.key,
    required this.pointId,
    required this.initialIndex,
  });

  @override
  State<PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<PhotoGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late List<ImageModel> _localImages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _updateImagesFromGlobalState();
  }

  void _updateImagesFromGlobalState() {
    // Get the current point from global state
    final point = context.projectState.currentPoints.firstWhere(
      (point) => point.id == widget.pointId,
      orElse: () =>
          throw Exception('Point not found for ID: ${widget.pointId}'),
    );

    // Create a mutable copy from the global state
    _localImages = List<ImageModel>.from(point.images);
    _localImages.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _editNoteInFullScreen() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          NoteEditDialog(initialNote: _localImages[_currentIndex].note),
    );
    if (result != null && result != _localImages[_currentIndex].note) {
      // Update the image note through global state
      final updatedImage = _localImages[_currentIndex].copyWith(note: result);

      // Find the point that contains this image and update it through global state
      final currentImage = _localImages[_currentIndex];
      final point = context.projectState.currentPoints.firstWhere(
        (point) => point.images.any((img) => img.id == currentImage.id),
        orElse: () =>
            throw Exception('Point not found for image ${currentImage.id}'),
      );

      // Create updated point with the modified image
      final updatedImages = point.images.map((img) {
        if (img.id == currentImage.id) {
          return updatedImage;
        }
        return img;
      }).toList();

      final updatedPoint = point.copyWith(images: updatedImages);

      // Update through global state
      context.projectState.updatePointInEditingState(updatedPoint);

      // Update the local images list to reflect the change immediately
      setState(() {
        _localImages[_currentIndex] = updatedImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        // Update images from global state when project state changes
        _updateImagesFromGlobalState();

        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _localImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final image = _localImages[index];
                  return Center(
                    child: InteractiveViewer(
                      child: Image.file(
                        File(image.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                                size: 60,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s?.errorGeneric ?? 'Error',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Note display (bottom center)
              if (_localImages.isNotEmpty &&
                  _localImages[_currentIndex].note.isNotEmpty)
                Positioned(
                  bottom: 32,
                  left: 32,
                  right: 32,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sticky_note_2,
                              color: Colors.white,
                              size: 20,
                            ),
                            if (_localImages[_currentIndex].note.isEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s?.addANote ?? 'Note',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ] else
                              const Expanded(child: SizedBox()),

                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                              onPressed: () => _editNoteInFullScreen(),
                              tooltip: s?.edit ?? 'Edit',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _localImages[_currentIndex].note,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_localImages.isNotEmpty)
                // Add note button when no note exists
                Positioned(
                  bottom: 32,
                  right: 32,
                  child: FloatingActionButton.small(
                    onPressed: () => _editNoteInFullScreen(),
                    backgroundColor: Colors.black.withValues(alpha: 0.7),
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add_comment, size: 20),
                  ),
                ),

              // Close button (top right)
              Positioned(
                top: 32,
                right: 32,
                child: Tooltip(
                  message: s?.close_button ?? 'Close',
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 32,
                    ),
                    tooltip: s?.close_button ?? 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
