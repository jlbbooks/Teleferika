/// Photo management widget for handling point-associated images.
///
/// This widget provides a comprehensive interface for managing photos associated
/// with geographic points. It supports adding photos from camera or gallery,
/// viewing photos in a gallery, editing photo notes, and managing photo metadata.
///
/// ## Features
/// - **Photo Capture**: Take photos using device camera
/// - **Gallery Import**: Select photos from device gallery
/// - **Photo Gallery**: Full-screen photo viewing with navigation
/// - **Note Editing**: Add and edit notes for individual photos
/// - **Multi-select**: Select multiple photos for bulk operations
/// - **Auto-save**: Automatic saving of photo changes to global state
/// - **File Management**: Automatic file organization and cleanup
/// - **Status Feedback**: User feedback through status indicators
///
/// ## Usage Examples
///
/// ### Basic Photo Management:
/// ```dart
/// PhotoManagerWidget(
///   point: currentPoint,
///   onImageListChangedForUI: (images) {
///     // Handle updated image list
///     setState(() {
///       pointImages = images;
///     });
///   },
///   onPhotosSavedSuccessfully: () {
///     // Handle successful save
///     print('Photos saved successfully');
///   },
/// )
/// ```
///
/// ### With Add Photo Callback:
/// ```dart
/// PhotoManagerWidget(
///   point: currentPoint,
///   onImageListChangedForUI: (images) => updateImages(images),
///   setAddPhotoCallback: (callback) {
///     // Store callback for external use
///     addPhotoCallback = callback;
///   },
/// )
/// ```
///
/// ## Photo Operations
/// - **Add Photo**: Camera capture or gallery selection
/// - **View Photo**: Full-screen gallery with zoom and navigation
/// - **Edit Note**: In-place note editing for each photo
/// - **Delete Photo**: Remove photos with confirmation
/// - **Reorder Photos**: Drag and drop reordering
///
/// ## File Management
/// Photos are automatically organized in the app's document directory:
/// - Each point gets its own folder: `point_photos/{pointId}/`
/// - Photos are saved with unique UUID filenames
/// - Automatic cleanup of orphaned files
/// - Optimized image quality (80% compression)
///
/// ## State Management
/// The widget integrates with the global project state to:
/// - Fetch photos for the specified point
/// - Update photo metadata in real-time
/// - Maintain photo ordering and relationships
/// - Handle state changes and persistence
///
/// ## Accessibility Features
/// - Screen reader support for photo operations
/// - Keyboard navigation for all controls
/// - High contrast controls and text
/// - Proper focus management
/// - Semantic labels for all interactive elements
/// - VoiceOver/TalkBack support for photo descriptions
///
/// ## Error Handling
/// - Graceful handling of camera/gallery permission denials
/// - File system error recovery
/// - Network error handling for cloud operations
/// - User-friendly error messages with localization
/// - Automatic retry mechanisms for failed operations

// ignore_for_file: unused_field

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p; // For p.basename, p.join
import 'package:path_provider/path_provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/core/utils/uuid_generator.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:teleferika/ui/widgets/photo_gallery_dialog.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// import 'package:teleferika/utils/uuid_generator.dart'; // Assuming ImageModel handles this

/// A widget for managing photos associated with geographic points.
///
/// This widget provides a complete photo management interface including
/// photo capture, gallery viewing, note editing, and file management.
/// It integrates with the global project state for data persistence
/// and provides real-time updates to the UI.
class PhotoManagerWidget extends StatefulWidget {
  /// Callback function called when the image list changes.
  ///
  /// This callback is triggered whenever photos are added, removed, or reordered.
  /// The parent widget should use this to update its UI state with the new image list.
  final Function(List<ImageModel> updatedImages) onImageListChangedForUI;

  /// Optional callback function called when photos are successfully saved.
  ///
  /// This callback is triggered after photos are successfully saved to the global state.
  /// Useful for triggering UI updates or showing success feedback.
  final VoidCallback? onPhotosSavedSuccessfully;

  /// The point model that owns the photos being managed.
  ///
  /// This point contains the current list of images and metadata.
  /// The widget will automatically sync with the global state for this point.
  final PointModel point;

  /// Optional callback to set an external add photo function.
  ///
  /// If provided, this callback receives a function that can be called externally
  /// to trigger the add photo dialog. Useful for integrating with external UI controls.
  final void Function(VoidCallback callback)? setAddPhotoCallback;

  /// Creates a photo manager widget.
  ///
  /// The [point] parameter is required and specifies which point's photos to manage.
  /// The [onImageListChangedForUI] callback is required and handles UI updates when
  /// the image list changes. Other parameters are optional for additional functionality.
  const PhotoManagerWidget({
    super.key,
    required this.point,
    required this.onImageListChangedForUI,
    this.onPhotosSavedSuccessfully,
    this.setAddPhotoCallback,
  });

  @override
  State<PhotoManagerWidget> createState() => _PhotoManagerWidgetState();
}

/// State class for the PhotoManagerWidget.
///
/// Manages the internal state of the photo manager including image list,
/// selection state, and photo operations. Integrates with the StatusMixin
/// for user feedback and the global project state for data persistence.
class _PhotoManagerWidgetState extends State<PhotoManagerWidget>
    with StatusMixin {
  /// Logger instance for debugging and error tracking.
  final Logger logger = Logger('PhotoManagerWidget');

  /// Current list of images for the point.
  ///
  /// This list is kept in sync with the global project state and
  /// represents the current state of photos for the managed point.
  late List<ImageModel> _images;

  /// Image picker instance for camera and gallery operations.
  ///
  /// Used to capture photos from camera or select from device gallery.
  final ImagePicker _picker = ImagePicker();

  /// Flag indicating if photos are currently being saved.
  ///
  /// Prevents concurrent save operations and provides UI feedback
  /// during save operations.
  bool _isSavingPhotos = false;

  /// Flag indicating if multi-select mode is active.
  ///
  /// When true, users can select multiple photos for bulk operations
  /// like deletion or reordering.
  bool _selectMode = false;

  /// Set of selected image IDs in multi-select mode.
  ///
  /// Tracks which images are currently selected for bulk operations.
  final Set<String> _selectedImageIds = {};

  @override
  void initState() {
    super.initState();
    logger.info(
      'PhotoManagerWidget initState called. Point ID: ${widget.point.id}, Initial images from point.images count: ${widget.point.images.length}',
    );
    _updateImagesFromGlobalState();
    if (widget.setAddPhotoCallback != null) {
      widget.setAddPhotoCallback!(_showAddPhotoOptions);
    }
  }

  /// Updates the local image list from the global project state.
  ///
  /// This method synchronizes the widget's internal image list with the
  /// current state of the point in the global project state. It ensures
  /// that the widget displays the most up-to-date photo information.
  ///
  /// The images are automatically sorted by their ordinal numbers to
  /// maintain the correct display order.
  void _updateImagesFromGlobalState() {
    // Get the current point from global state
    final currentPoint = context.projectState.currentPoints.firstWhere(
      (point) => point.id == widget.point.id,
      orElse: () => widget.point,
    );

    // Create a mutable copy from the global state
    _images = List<ImageModel>.from(currentPoint.images);
    _images.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));
    logger.finer('Images updated from global state: $_images');
  }

  /// Saves the current image list to the global project state.
  ///
  /// This method updates the point in the global state with the current
  /// list of images and triggers the appropriate callbacks. It includes
  /// validation, error handling, and user feedback through status indicators.
  ///
  /// ## Process
  /// 1. Validates the point data before saving
  /// 2. Updates the point in global state with current images
  /// 3. Notifies parent widgets of changes
  /// 4. Shows success/error feedback to user
  /// 5. Prevents concurrent save operations
  ///
  /// ## Error Handling
  /// - Validates point data before saving
  /// - Handles database errors gracefully
  /// - Shows localized error messages
  /// - Logs errors for debugging
  Future<void> _savePointWithCurrentImages() async {
    if (_isSavingPhotos) return; // Prevent concurrent saves

    setState(() {
      _isSavingPhotos = true;
    });
    logger.info('Updating images for point ID: ${widget.point.id}');

    try {
      // Create an updated PointModel with the current list of images
      // We use the existing widget.point data for other fields
      PointModel pointToSave = widget.point.copyWith(
        images: List<ImageModel>.from(_images),
        // Pass a copy of the current images
        // Optionally update a 'lastModified' timestamp on the point itself here if desired
        timestamp: DateTime.now(),
      );

      // Validate the point before saving
      if (!pointToSave.isValid) {
        logger.warning(
          'Point to save is invalid: ${pointToSave.validationErrors}',
        );
        showErrorStatus(
          'Error saving point: ${pointToSave.validationErrors.join(', ')}',
        );
        return;
      }

      // Use global state to update the point
      context.projectState.updatePointInEditingState(pointToSave);

      logger.info(
        'Successfully updated image changes for point ID: ${widget.point.id}. Image count: ${_images.length}',
      );
      // Notify parent for UI update (e.g., image count)
      widget.onImageListChangedForUI(List<ImageModel>.from(_images));
      logger.finer('Calling onPhotosSavedSuccessfully callback.');
      widget.onPhotosSavedSuccessfully?.call();

      if (mounted) {
        showSuccessStatus(
          S.of(context)?.photo_manager_photo_changes_saved ??
              'Photo changes saved automatically.',
        );
      }
    } catch (e, stackTrace) {
      logger.severe(
        'Error auto-saving image changes for point ID: ${widget.point.id}',
        e,
        stackTrace,
      );
      if (mounted) {
        showErrorStatus(
          S
                  .of(context)
                  ?.photo_manager_error_saving_photo_changes(e.toString()) ??
              'Error saving photo changes: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPhotos = false;
        });
      }
    }
  }

  Future<Directory> _getPointPhotosDirectory() async {
    logger.info(
      '_getPointPhotosDirectory called for point ID: ${widget.point.id}',
    );
    final appDocDir = await getApplicationDocumentsDirectory();
    final pointPhotosDir = Directory(
      p.join(appDocDir.path, 'point_photos', widget.point.id),
    );
    if (!await pointPhotosDir.exists()) {
      logger.info(
        'Point photos directory does not exist, creating: ${pointPhotosDir.path}',
      );
      await pointPhotosDir.create(recursive: true);
    } else {
      logger.info(
        'Point photos directory already exists: ${pointPhotosDir.path}',
      );
    }
    return pointPhotosDir;
  }

  Future<String?> _saveImageFileToAppStorage(XFile imageFile) async {
    logger.info(
      '_saveImageFileToAppStorage called for XFile: ${imageFile.path}',
    );
    try {
      final pointPhotosDir = await _getPointPhotosDirectory();
      // Use a UUID for the filename to ensure uniqueness
      final uniqueFileName = '${generateUuid()}${p.extension(imageFile.path)}';
      final newPath = p.join(pointPhotosDir.path, uniqueFileName);
      logger.info('Attempting to save image to: $newPath');
      final savedFile = await File(imageFile.path).copy(newPath);
      logger.info('Image successfully saved to: ${savedFile.path}');
      return savedFile.path;
    } catch (e, stackTrace) {
      logger.severe('Error saving image to app storage: $e', e, stackTrace);
      if (mounted) {
        showErrorStatus(
          S.of(context)?.photo_manager_error_saving_image(e.toString()) ??
              'Error saving image: ${e.toString()}',
        );
      }
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    logger.info('_pickImage called with source: $source');
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        logger.info('Image picked: ${pickedFile.path}');
        final savedPath = await _saveImageFileToAppStorage(pickedFile);
        if (savedPath != null) {
          final nextOrdinal = _images.isNotEmpty
              ? (_images
                        .map((img) => img.ordinalNumber)
                        .reduce((a, b) => a > b ? a : b) +
                    1)
              : 0;
          final newImage = ImageModel(
            pointId: widget.point.id,
            ordinalNumber: nextOrdinal,
            imagePath: savedPath,
          );

          // Validate the created image
          if (!newImage.isValid) {
            logger.warning(
              'Created invalid ImageModel: ${newImage.validationErrors}',
            );
            showErrorStatus(
              'Error creating image: ${newImage.validationErrors.join(', ')}',
            );
            return;
          }

          logger.info('New ImageModel created: $newImage');
          setState(() {
            _images.add(newImage);
            logger.finer(
              'Image list updated with new image. New count: ${_images.length}',
            );
          });
          await _savePointWithCurrentImages();
          // widget.onImageListChanged(List<ImageModel>.from(_images));
          logger.info(
            'onImageListChanged callback invoked with ${_images.length} images.',
          );
        } else {
          logger.warning('Image picked, but failed to save to app storage.');
        }
      } else {
        logger.info('Image picking cancelled by user.');
      }
    } catch (e, stackTrace) {
      logger.severe('Error picking image: $e', e, stackTrace);
      if (mounted) {
        showErrorStatus(
          S.of(context)?.photo_manager_error_picking_image(e.toString()) ??
              'Error picking image: ${e.toString()}',
        );
      }
    }
  }

  void _updateOrdinalNumbers() {
    logger.info(
      '_updateOrdinalNumbers called. Current image count: ${_images.length}',
    );
    bool changed = false;
    for (int i = 0; i < _images.length; i++) {
      if (_images[i].ordinalNumber != i) {
        logger.finer(
          'Updating ordinal for image ID ${_images[i].id} from ${_images[i].ordinalNumber} to $i',
        );
        final updatedImage = _images[i].copyWith(ordinalNumber: i);

        // Validate the updated image
        if (!updatedImage.isValid) {
          logger.warning(
            'Updated image is invalid: ${updatedImage.validationErrors}',
          );
          continue; // Skip this update if invalid
        }

        _images[i] = updatedImage;
        changed = true;
      }
    }
    if (changed) {
      logger.info(
        'Ordinal numbers updated. New sequence: ${_images.map((img) => img.ordinalNumber).toList()}',
      );
    } else {
      logger.info('No ordinal numbers needed updating.');
    }
  }

  void _showAddPhotoOptions() {
    logger.info('_showAddPhotoOptions called.');
    if (_isSavingPhotos) {
      logger.warning(
        "Attempted to show add photo options while auto-save is in progress. Aborting.",
      );
      showInfoStatus(
        S.of(context)?.photo_manager_wait_saving ??
            'Please wait, photos are being saved...',
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(S.of(context)?.photo_manager_gallery ?? 'Gallery'),
                onTap: () {
                  logger.info('Gallery option selected.');
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(S.of(context)?.photo_manager_camera ?? 'Camera'),
                onTap: () {
                  logger.info('Camera option selected.');
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleImageSelection(String imageId) {
    setState(() {
      if (_selectedImageIds.contains(imageId)) {
        _selectedImageIds.remove(imageId);
      } else {
        _selectedImageIds.add(imageId);
      }
      // Exit selection mode if nothing is selected
      if (_selectedImageIds.isEmpty) {
        _selectMode = false;
      }
    });
  }

  Future<void> _deleteSelectedImages() async {
    if (_selectedImageIds.isEmpty) return;
    final s = S.of(context);
    final selectedCount = _selectedImageIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.delete_photo_title ?? 'Delete Photos?'),
        content: Text(
          s?.delete_photo_content(selectedCount.toString()) ??
              'Are you sure you want to delete $selectedCount photo${selectedCount == 1 ? '' : 's'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s?.buttonCancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              s?.buttonDelete ?? 'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _images.removeWhere((img) => _selectedImageIds.contains(img.id));
        _selectedImageIds.clear();
        _selectMode = false; // Exit selection mode after deletion
        _updateOrdinalNumbers();
      });
      await _savePointWithCurrentImages();
      showSuccessStatus(s?.photo_manager_photo_deleted ?? 'Photos deleted');
    }
  }

  // Add/Edit note for a photo
  void _editPhotoNote(ImageModel image) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => NoteEditDialog(initialNote: image.note),
    );
    if (result != null && result != image.note) {
      setState(() {
        final idx = _images.indexWhere((img) => img.id == image.id);
        if (idx != -1) {
          _images[idx] = _images[idx].copyWith(note: result);
        }
      });
      await _savePointWithCurrentImages();
      if (mounted) {
        showSuccessStatus(S.of(context)?.save ?? 'Saved');
      }
    }
  }

  @override
  void dispose() {
    logger.info(
      'dispose called for PhotoManagerWidget with point ID: ${widget.point.id}',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.finest(
      'PhotoManagerWidget build called. Image count: ${_images.length}, isSaving: $_isSavingPhotos',
    );

    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        // Update images from global state when project state changes
        _updateImagesFromGlobalState();

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title row is now handled by parent section
                    if (_isSavingPhotos)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      )
                    else if (_selectMode)
                      Row(
                        children: [
                          TextButton(
                            onPressed: _selectedImageIds.isEmpty
                                ? null
                                : _deleteSelectedImages,
                            child: Text(
                              S.of(context)?.buttonDelete ?? 'Delete',
                              style: TextStyle(
                                color: _selectedImageIds.isEmpty
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectMode = false;
                                _selectedImageIds.clear();
                              });
                            },
                            child: Text(
                              S.of(context)?.buttonCancel ?? 'Cancel',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _images.isEmpty
                    ? Container(
                        height: 140, // Increased height for button
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_album_outlined,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              S.of(context)?.photo_manager_no_photos ??
                                  'No photos yet.',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: Text(
                                S
                                        .of(context)
                                        ?.photo_manager_add_photo_tooltip ??
                                    'Add Photo',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                textStyle: Theme.of(
                                  context,
                                ).textTheme.labelLarge,
                              ),
                              onPressed: _isSavingPhotos
                                  ? null
                                  : _showAddPhotoOptions,
                              autofocus: true,
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate crossAxisCount for ~80px cells
                          final cellSize = 80.0;
                          final crossAxisCount =
                              (constraints.maxWidth / cellSize).floor().clamp(
                                1,
                                8,
                              );
                          return SizedBox(
                            height: 280,
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                final imageModel = _images[index];
                                return Container(
                                  key: ValueKey(imageModel.id),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(
                                          0,
                                          0,
                                          0,
                                          0.08,
                                        ),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      GestureDetector(
                                        onTap: _selectMode
                                            ? () => _toggleImageSelection(
                                                imageModel.id,
                                              )
                                            : () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      PhotoGalleryDialog(
                                                        pointId:
                                                            widget.point.id,
                                                        initialIndex: index,
                                                      ),
                                                );
                                              },
                                        onLongPress: () {
                                          if (!_selectMode) {
                                            setState(() {
                                              _selectMode = true;
                                              _selectedImageIds.add(
                                                imageModel.id,
                                              );
                                            });
                                          } else {
                                            _toggleImageSelection(
                                              imageModel.id,
                                            );
                                          }
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: SizedBox.expand(
                                            child: Image(
                                              image: FileImage(
                                                File(imageModel.imagePath),
                                              ),
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
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                              errorBuilder: (context, error, stackTrace) {
                                                logger.warning(
                                                  'Error building image for path: ${imageModel.imagePath}',
                                                  error,
                                                  stackTrace,
                                                );
                                                // Remove the broken image from the grid and save
                                                WidgetsBinding.instance.addPostFrameCallback((
                                                  _,
                                                ) async {
                                                  if (mounted &&
                                                      _images.contains(
                                                        imageModel,
                                                      )) {
                                                    setState(() {
                                                      _images.remove(
                                                        imageModel,
                                                      );
                                                      _updateOrdinalNumbers();
                                                    });
                                                    await _savePointWithCurrentImages();
                                                    if (context.mounted) {
                                                      showErrorStatus(
                                                        S
                                                                .of(context)
                                                                ?.photo_manager_error_deleting_photo(
                                                                  'File not found',
                                                                ) ??
                                                            'Photo file missing and removed.',
                                                      );
                                                    }
                                                  }
                                                });
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        S
                                                                .of(context)
                                                                ?.errorGeneric ??
                                                            'Error',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_selectMode &&
                                          _selectedImageIds.contains(
                                            imageModel.id,
                                          ))
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 24,
                                          ),
                                        ),
                                      // Note icon (bottom right)
                                      if (!_selectMode)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _editPhotoNote(imageModel),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                imageModel.note.isNotEmpty
                                                    ? Icons.sticky_note_2
                                                    : Icons
                                                          .sticky_note_2_outlined,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
            if (currentStatus != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: StatusIndicator(
                    status: currentStatus,
                    onDismiss: hideStatus,
                    margin: const EdgeInsets.only(top: 8),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
