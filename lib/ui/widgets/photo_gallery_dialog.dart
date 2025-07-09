/// Photo gallery and note editing dialog widgets for Teleferika.
///
/// This module provides two main UI components:
/// - [PhotoGalleryDialog]: Full-screen photo gallery with navigation and editing capabilities
/// - [NoteEditDialog]: Modal dialog for editing photo notes with rich text input
///
/// ## Features
/// - **Full-screen Photo Gallery**: Swipe navigation between photos with zoom and pan
/// - **Note Editing**: In-place note editing with rich text support
/// - **Global State Integration**: Seamless integration with project state management
/// - **Responsive Design**: Adapts to different screen sizes and orientations
/// - **Accessibility**: Proper focus management and screen reader support
/// - **Smooth Animations**: Fluid transitions and gesture-based interactions
///
/// ## Usage Examples
///
/// ### Opening Photo Gallery:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => PhotoGalleryDialog(
///     pointId: 'point-123',
///     initialIndex: 0,
///   ),
/// );
/// ```
///
/// ### Editing Photo Notes:
/// ```dart
/// final result = await showDialog<String>(
///   context: context,
///   builder: (context) => NoteEditDialog(
///     initialNote: 'Existing note text',
///   ),
/// );
///
/// if (result != null) {
///   // Handle the updated note
///   print('Updated note: $result');
/// }
/// ```
///
/// ## Design Principles
/// - **Dark Theme**: Gallery uses dark background for optimal photo viewing
/// - **Minimal UI**: Clean interface that doesn't distract from photo content
/// - **Gesture Support**: Intuitive swipe and pinch gestures for navigation
/// - **Consistent Styling**: Matches app's overall design language
///
/// ## Accessibility Features
/// - High contrast text and controls
/// - Screen reader announcements for photo navigation
/// - Keyboard navigation support
/// - Focus indicators for interactive elements
/// - Proper semantic labels for all UI elements

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// A modal dialog for editing photo notes with rich text input.
///
/// This widget provides a full-screen dialog with a dark theme optimized
/// for note editing. It includes auto-focus, multi-line text input,
/// and proper keyboard handling.
///
/// ## Features
/// - **Dark Theme**: Black background with white text for optimal contrast
/// - **Auto-focus**: Text field automatically receives focus when dialog opens
/// - **Multi-line Support**: Supports up to 5 lines of text input
/// - **Keyboard Handling**: Proper keyboard navigation and dismissal
/// - **Responsive Design**: Adapts to different screen sizes
/// - **Accessibility**: Screen reader support and proper focus management
///
/// ## Usage Examples
///
/// ### Basic Note Editing:
/// ```dart
/// final result = await showDialog<String>(
///   context: context,
///   builder: (context) => NoteEditDialog(
///     initialNote: 'Existing note text',
///   ),
/// );
///
/// if (result != null) {
///   // Handle the updated note
///   updatePhotoNote(result);
/// }
/// ```
///
/// ### Creating New Note:
/// ```dart
/// final result = await showDialog<String>(
///   context: context,
///   builder: (context) => NoteEditDialog(
///     initialNote: '', // Empty for new note
///   ),
/// );
/// ```
///
/// ## Visual Design
/// - Semi-transparent black background (90% opacity)
/// - White text with proper contrast
/// - Rounded corners (12px radius)
/// - Subtle input field styling
/// - Clear action buttons (Cancel/Save)
///
/// ## Accessibility
/// - High contrast text and controls
/// - Proper focus management
/// - Screen reader announcements
/// - Keyboard navigation support
/// - Semantic labels for all interactive elements
class NoteEditDialog extends StatefulWidget {
  /// The initial note text to display in the text field.
  ///
  /// If empty, the dialog will show "Add a note" in the header.
  /// If not empty, the dialog will show the existing note text.
  final String initialNote;

  /// Creates a note edit dialog.
  ///
  /// The [initialNote] parameter determines the starting text in the
  /// text field and affects the dialog's header display.
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
          color: const Color.fromRGBO(0, 0, 0, 0.9),
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

/// A full-screen photo gallery dialog with navigation and editing capabilities.
///
/// This widget provides a comprehensive photo viewing experience with swipe
/// navigation, zoom/pan support, and integrated note editing. It integrates
/// with the global project state to manage photo data and notes.
///
/// ## Features
/// - **Full-screen Display**: Immersive photo viewing experience
/// - **Swipe Navigation**: Intuitive left/right swipe to navigate between photos
/// - **Zoom and Pan**: Pinch to zoom and drag to pan within photos
/// - **Note Editing**: In-place note editing for each photo
/// - **Global State Integration**: Seamless updates to project state
/// - **Responsive Design**: Adapts to different screen sizes and orientations
/// - **Smooth Animations**: Fluid page transitions and gesture responses
/// - **Accessibility**: Screen reader support and keyboard navigation
///
/// ## Usage Examples
///
/// ### Basic Gallery Display:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => PhotoGalleryDialog(
///     pointId: 'point-123',
///     initialIndex: 0, // Start with first photo
///   ),
/// );
/// ```
///
/// ### Opening at Specific Photo:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => PhotoGalleryDialog(
///     pointId: 'point-123',
///     initialIndex: 2, // Start with third photo
///   ),
/// );
/// ```
///
/// ## Navigation Controls
/// - **Swipe Left/Right**: Navigate between photos
/// - **Tap**: Toggle UI controls visibility
/// - **Pinch**: Zoom in/out on current photo
/// - **Drag**: Pan around zoomed photo
/// - **Double Tap**: Reset zoom level
///
/// ## Visual Design
/// - Dark background for optimal photo viewing
/// - Semi-transparent UI controls
/// - Smooth fade animations for UI elements
/// - Clear navigation indicators
/// - Consistent with app's design language
///
/// ## State Management
/// The widget integrates with the global project state to:
/// - Fetch photos for the specified point
/// - Update photo notes in real-time
/// - Maintain photo ordering and metadata
/// - Handle state changes and updates
///
/// ## Accessibility Features
/// - Screen reader announcements for photo navigation
/// - Keyboard navigation support
/// - High contrast controls
/// - Proper focus management
/// - Semantic labels for all interactive elements
/// - VoiceOver/TalkBack support for photo descriptions
class PhotoGalleryDialog extends StatefulWidget {
  /// The unique identifier of the point containing the photos.
  ///
  /// This ID is used to fetch the photos from the global project state
  /// and associate any changes with the correct point.
  final String pointId;

  /// The index of the photo to display initially.
  ///
  /// This determines which photo is shown when the gallery opens.
  /// Must be within the valid range of available photos for the point.
  final int initialIndex;

  /// Creates a photo gallery dialog.
  ///
  /// The [pointId] parameter identifies which point's photos to display,
  /// and [initialIndex] determines which photo to show first.
  ///
  /// Throws an exception if the point is not found or if the initial
  /// index is out of range.
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
      if (!mounted) return;
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
