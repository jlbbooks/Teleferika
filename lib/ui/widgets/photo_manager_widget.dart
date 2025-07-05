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
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// import 'package:teleferika/utils/uuid_generator.dart'; // Assuming ImageModel handles this

class PhotoManagerWidget extends StatefulWidget {
  final Function(List<ImageModel> updatedImages) onImageListChangedForUI;
  final VoidCallback?
  onPhotosSavedSuccessfully; // Callback when photos are auto-saved
  final PointModel point;

  const PhotoManagerWidget({
    super.key,
    required this.point,
    required this.onImageListChangedForUI,
    this.onPhotosSavedSuccessfully,
  });

  @override
  State<PhotoManagerWidget> createState() => _PhotoManagerWidgetState();
}

class _PhotoManagerWidgetState extends State<PhotoManagerWidget>
    with StatusMixin {
  final Logger logger = Logger('PhotoManagerWidget');
  late List<ImageModel> _images;
  final ImagePicker _picker = ImagePicker();
  bool _isSavingPhotos = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Multi-select state
  bool _selectMode = false;
  final Set<String> _selectedImageIds = {};

  @override
  void initState() {
    super.initState();
    logger.info(
      'PhotoManagerWidget initState called. Point ID: ${widget.point.id}, Initial images from point.images count: ${widget.point.images.length}',
    );
    _updateImagesFromGlobalState();
  }

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

  // This method will now handle the saving of the point with its current images
  Future<void> _savePointWithCurrentImages() async {
    if (_isSavingPhotos) return; // Prevent concurrent saves

    setState(() {
      _isSavingPhotos = true;
    });
    logger.info('Auto-saving image changes for point ID: ${widget.point.id}');

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
        'Successfully auto-saved image changes for point ID: ${widget.point.id}. Image count: ${_images.length}',
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
    final s = S.of(context);
    final controller = TextEditingController(text: image.note);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.addANote ?? 'Add a note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: s?.addANote ?? 'Add a note...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s?.buttonCancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(s?.save ?? 'Save'),
          ),
        ],
      ),
    );
    if (result != null && result != image.note) {
      setState(() {
        final idx = _images.indexWhere((img) => img.id == image.id);
        if (idx != -1) {
          _images[idx] = _images[idx].copyWith(note: result);
        }
      });
      await _savePointWithCurrentImages();
      showSuccessStatus(s?.save ?? 'Saved');
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
                    Text(
                      '${S.of(context)?.photo_manager_title ?? 'Photos'} (${_images.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _isSavingPhotos
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ),
                          )
                        : _selectMode
                        ? Row(
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
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_a_photo_outlined),
                            tooltip:
                                S
                                    .of(context)
                                    ?.photo_manager_add_photo_tooltip ??
                                'Add Photo',
                            onPressed: _showAddPhotoOptions,
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
                                        color: Colors.black.withOpacity(0.08),
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
                                                        images: _images,
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
                                            child: Image.file(
                                              File(imageModel.imagePath),
                                              fit: BoxFit.cover,
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
                                                    showErrorStatus(
                                                      S
                                                              .of(context)
                                                              ?.photo_manager_error_deleting_photo(
                                                                'File not found',
                                                              ) ??
                                                          'Photo file missing and removed.',
                                                    );
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
                                                color: Colors.black.withOpacity(
                                                  0.5,
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

// Add PhotoGalleryDialog widget for fullscreen preview
class PhotoGalleryDialog extends StatefulWidget {
  final List<ImageModel> images;
  final int initialIndex;

  const PhotoGalleryDialog({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<PhotoGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isEditingNote = false;
  late TextEditingController _noteController;
  late List<ImageModel> _localImages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _localImages = List<ImageModel>.from(widget.images);
    _noteController = TextEditingController(
      text: _localImages[_currentIndex].note,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateNoteController() {
    _noteController.text = _localImages[_currentIndex].note;
  }

  void _saveNote() {
    if (_isEditingNote) {
      final newNote = _noteController.text.trim();
      if (newNote != _localImages[_currentIndex].note) {
        // Update the image note through global state
        final updatedImage = _localImages[_currentIndex].copyWith(
          note: newNote,
        );

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
          _isEditingNote = false;
        });
      } else {
        setState(() {
          _isEditingNote = false;
        });
      }
    }
  }

  void _startEditingNote() {
    setState(() {
      _isEditingNote = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
              _updateNoteController();
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
          if (_localImages[_currentIndex].note.isNotEmpty || _isEditingNote)
            Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
                        if (_localImages[_currentIndex].note.isEmpty &&
                            !_isEditingNote) ...[
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
                        if (!_isEditingNote)
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                            onPressed: _startEditingNote,
                            tooltip: s?.edit ?? 'Edit',
                          ),
                        if (_isEditingNote) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 16,
                            ),
                            onPressed: _saveNote,
                            tooltip: s?.save ?? 'Save',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 16,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditingNote = false;
                                _updateNoteController();
                              });
                            },
                            tooltip: s?.buttonCancel ?? 'Cancel',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingNote)
                      TextField(
                        controller: _noteController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white24,
                        ),
                        maxLines: 3,
                        autofocus: true,
                        cursorColor: Colors.white,
                      )
                    else
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
          else
            // Add note button when no note exists
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton.small(
                onPressed: _startEditingNote,
                backgroundColor: Colors.black.withOpacity(0.7),
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
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                tooltip: s?.close_button ?? 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
