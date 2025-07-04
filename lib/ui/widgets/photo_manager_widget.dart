// ignore_for_file: unused_field

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p; // For p.basename, p.join
import 'package:path_provider/path_provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/utils/uuid_generator.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

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

  @override
  void initState() {
    super.initState();
    logger.info(
      'PhotoManagerWidget initState called. Point ID: ${widget.point.id}, Initial images from point.images count: ${widget.point.images.length}',
    );
    // Create a mutable copy from widget.point.images
    _images = List<ImageModel>.from(widget.point.images);
    _images.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));
    logger.finer('Initial images sorted: $_images');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving point: ${pointToSave.validationErrors.join(', ')}',
            ),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo changes saved automatically.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.severe(
        'Error auto-saving image changes for point ID: ${widget.point.id}',
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving photo changes: ${e.toString()}'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: ${e.toString()}')),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error creating image: ${newImage.validationErrors.join(', ')}',
                ),
                backgroundColor: Colors.red,
              ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  void _deletePhoto(int index) async {
    logger.info('_deletePhoto called for index: $index');
    if (_isSavingPhotos) {
      logger.warning(
        "Attempted to delete image while auto-save is in progress. Aborting.",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, photos are being saved...')),
      );
      return;
    }
    if (index < 0 || index >= _images.length) {
      logger.warning(
        'Delete photo called with invalid index: $index. Image count: ${_images.length}',
      );
      return;
    }

    final ImageModel imageToDelete = _images[index];
    logger.info('Attempting to delete image: $imageToDelete');

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final s = S.of(dialogContext);
        return AlertDialog(
          title: Text(s?.delete_photo_title ?? 'Delete Photo?'),
          content: Text(
            s?.delete_photo_content(
                  (imageToDelete.ordinalNumber + 1).toString(),
                ) ??
                'Are you sure you want to delete photo \\${imageToDelete.ordinalNumber + 1}?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(s?.buttonCancel ?? 'Cancel'),
              onPressed: () {
                logger.info('Photo deletion cancelled by user.');
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text(
                s?.buttonDelete ?? 'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                logger.info('Photo deletion confirmed by user.');
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final fileToDelete = File(imageToDelete.imagePath);
        if (await fileToDelete.exists()) {
          logger.info(
            'Physical file exists, deleting: ${imageToDelete.imagePath}',
          );
          await fileToDelete.delete();
          logger.info('Physical file deleted.');
        } else {
          logger.warning(
            'Physical file not found for deletion: ${imageToDelete.imagePath}',
          );
        }
        setState(() {
          _images.removeAt(index);
          logger.finer(
            'Image removed from list. Current count: ${_images.length}',
          );
          _updateOrdinalNumbers();
        });
        // Instead of just widget.onImageListChanged, now call the save method
        await _savePointWithCurrentImages();
        // widget.onImageListChanged(List<ImageModel>.from(_images));
        logger.info(
          'onImageListChanged callback invoked after deletion. Image count: ${_images.length}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context)?.photo_manager_photo_deleted ?? 'Photo deleted',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        logger.severe('Error deleting photo file: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S
                        .of(context)
                        ?.photo_manager_error_deleting_photo(e.toString()) ??
                    'Error deleting photo: ${e.toString()}',
              ),
            ),
          );
        }
      }
    } else {
      logger.info('Photo deletion was not confirmed.');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, photos are being saved...')),
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
    return Column(
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
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    tooltip:
                        S.of(context)?.photo_manager_add_photo_tooltip ??
                        'Add Photo',
                    onPressed: _showAddPhotoOptions,
                  ),
          ],
        ),
        const SizedBox(height: 8),
        _images.isEmpty
            ? Container(
                height: 100, // Or some appropriate placeholder size
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
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate crossAxisCount for ~80px cells
                  final cellSize = 80.0;
                  final crossAxisCount = (constraints.maxWidth / cellSize)
                      .floor()
                      .clamp(1, 8);
                  return SizedBox(
                    height: 280,
                    child: ReorderableGridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                      onReorder: (oldIndex, newIndex) async {
                        logger.info(
                          'onReorder called. Old index: $oldIndex, New index: $newIndex',
                        );
                        setState(() {
                          final ImageModel item = _images.removeAt(oldIndex);
                          _images.insert(newIndex, item);
                          logger.finer(
                            'Image reordered. Image ID: \\${item.id}',
                          );
                          _updateOrdinalNumbers();
                        });
                        await _savePointWithCurrentImages();
                        logger.info(
                          'onImageListChanged callback invoked after reorder. Image count: \\${_images.length}',
                        );
                      },
                      children: List.generate(_images.length, (index) {
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
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => PhotoGalleryDialog(
                                      images: _images,
                                      initialIndex: index,
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox.expand(
                                    child: Image.file(
                                      File(imageModel.imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        logger.warning(
                                          'Error building image for path: \\${imageModel.imagePath}',
                                          error,
                                          stackTrace,
                                        );
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Error',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[700],
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
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(
                                      (0.6 * 255).round(),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _isSavingPhotos
                                          ? null
                                          : () => _deletePhoto(index),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

// Add PhotoGalleryDialog widget for fullscreen preview
class PhotoGalleryDialog extends StatefulWidget {
  final List<ImageModel> images;
  final int initialIndex;

  const PhotoGalleryDialog({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<PhotoGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final image = widget.images[index];
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
          Positioned(
            top: 32,
            right: 32,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              tooltip: s?.delete ?? 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 32,
            right: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Photo #${widget.images[_currentIndex].ordinalNumber + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          widget.images[_currentIndex].note.isNotEmpty
                              ? widget.images[_currentIndex].note
                              : (s?.noNote ?? 'No note'),
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
