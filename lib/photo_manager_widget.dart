import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart'; // Import the logging package
import 'package:path/path.dart' as p; // For p.basename, p.join
import 'package:path_provider/path_provider.dart';
import 'package:teleferika/utils/uuid_generator.dart';

import 'db/models/image_model.dart';

// import 'package:teleferika/utils/uuid_generator.dart'; // Assuming ImageModel handles this

// Initialize logger for this widget
final _logger = Logger('PhotoManagerWidget');

class PhotoManagerWidget extends StatefulWidget {
  final List<ImageModel> initialImages;
  final Function(List<ImageModel> updatedImages) onImageListChanged;
  final String pointId; // Crucial: This is the FK for ImageModel

  const PhotoManagerWidget({
    super.key,
    required this.initialImages,
    required this.onImageListChanged,
    required this.pointId,
  });

  @override
  State<PhotoManagerWidget> createState() => _PhotoManagerWidgetState();
}

class _PhotoManagerWidgetState extends State<PhotoManagerWidget> {
  late List<ImageModel> _images;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _logger.info(
      'initState called. Point ID: ${widget.pointId}, Initial images count: ${widget.initialImages.length}',
    );
    // Sort initial images by ordinalNumber and copy to a mutable list
    _images = List<ImageModel>.from(widget.initialImages);
    _images.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));
    _logger.finer('Initial images sorted: $_images');
  }

  Future<Directory> _getPointPhotosDirectory() async {
    _logger.info(
      '_getPointPhotosDirectory called for point ID: ${widget.pointId}',
    );
    final appDocDir = await getApplicationDocumentsDirectory();
    final pointPhotosDir = Directory(
      p.join(appDocDir.path, 'point_photos', widget.pointId),
    );
    if (!await pointPhotosDir.exists()) {
      _logger.info(
        'Point photos directory does not exist, creating: ${pointPhotosDir.path}',
      );
      await pointPhotosDir.create(recursive: true);
    } else {
      _logger.info(
        'Point photos directory already exists: ${pointPhotosDir.path}',
      );
    }
    return pointPhotosDir;
  }

  Future<String?> _saveImageFileToAppStorage(XFile imageFile) async {
    _logger.info(
      '_saveImageFileToAppStorage called for XFile: ${imageFile.path}',
    );
    try {
      final pointPhotosDir = await _getPointPhotosDirectory();
      // Use a UUID for the filename to ensure uniqueness
      final uniqueFileName = '${generateUuid()}${p.extension(imageFile.path)}';
      final newPath = p.join(pointPhotosDir.path, uniqueFileName);
      _logger.info('Attempting to save image to: $newPath');
      final savedFile = await File(imageFile.path).copy(newPath);
      _logger.info('Image successfully saved to: ${savedFile.path}');
      return savedFile.path;
    } catch (e, stackTrace) {
      _logger.severe('Error saving image to app storage: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    _logger.info('_pickImage called with source: $source');
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _logger.info('Image picked: ${pickedFile.path}');
        final savedPath = await _saveImageFileToAppStorage(pickedFile);
        if (savedPath != null) {
          final nextOrdinal = _images.isNotEmpty
              ? (_images
                        .map((img) => img.ordinalNumber)
                        .reduce((a, b) => a > b ? a : b) +
                    1)
              : 0;
          final newImage = ImageModel(
            pointId: widget.pointId,
            ordinalNumber: nextOrdinal,
            imagePath: savedPath,
          );
          _logger.info('New ImageModel created: $newImage');
          setState(() {
            _images.add(newImage);
            _logger.finer(
              'Image list updated with new image. New count: ${_images.length}',
            );
          });
          widget.onImageListChanged(List<ImageModel>.from(_images));
          _logger.info(
            'onImageListChanged callback invoked with ${_images.length} images.',
          );
        } else {
          _logger.warning('Image picked, but failed to save to app storage.');
        }
      } else {
        _logger.info('Image picking cancelled by user.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error picking image: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  void _deletePhoto(int index) async {
    _logger.info('_deletePhoto called for index: $index');
    if (index < 0 || index >= _images.length) {
      _logger.warning(
        'Delete photo called with invalid index: $index. Image count: ${_images.length}',
      );
      return;
    }

    final ImageModel imageToDelete = _images[index];
    _logger.info('Attempting to delete image: $imageToDelete');

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Photo?'),
          content: Text(
            'Are you sure you want to delete photo ${imageToDelete.ordinalNumber + 1}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _logger.info('Photo deletion cancelled by user.');
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                _logger.info('Photo deletion confirmed by user.');
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
          _logger.info(
            'Physical file exists, deleting: ${imageToDelete.imagePath}',
          );
          await fileToDelete.delete();
          _logger.info('Physical file deleted.');
        } else {
          _logger.warning(
            'Physical file not found for deletion: ${imageToDelete.imagePath}',
          );
        }
        setState(() {
          _images.removeAt(index);
          _logger.finer(
            'Image removed from list. Current count: ${_images.length}',
          );
          _updateOrdinalNumbers();
        });
        widget.onImageListChanged(List<ImageModel>.from(_images));
        _logger.info(
          'onImageListChanged callback invoked after deletion. Image count: ${_images.length}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        _logger.severe('Error deleting photo file: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting photo: ${e.toString()}')),
          );
        }
      }
    } else {
      _logger.info('Photo deletion was not confirmed.');
    }
  }

  void _updateOrdinalNumbers() {
    _logger.info(
      '_updateOrdinalNumbers called. Current image count: ${_images.length}',
    );
    bool changed = false;
    for (int i = 0; i < _images.length; i++) {
      if (_images[i].ordinalNumber != i) {
        _logger.finer(
          'Updating ordinal for image ID ${_images[i].id} from ${_images[i].ordinalNumber} to $i',
        );
        _images[i] = _images[i].copyWith(ordinalNumber: i);
        changed = true;
      }
    }
    if (changed) {
      _logger.info(
        'Ordinal numbers updated. New sequence: ${_images.map((img) => img.ordinalNumber).toList()}',
      );
    } else {
      _logger.info('No ordinal numbers needed updating.');
    }
  }

  void _showAddPhotoOptions() {
    _logger.info('_showAddPhotoOptions called.');
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _logger.info('Gallery option selected.');
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _logger.info('Camera option selected.');
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
    _logger.info(
      'dispose called for PhotoManagerWidget with point ID: ${widget.pointId}',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest('build called. Image count: ${_images.length}');
    // ... rest of your build method ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos (${_images.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: 'Add Photo',
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
                      'No photos yet.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              )
            : SizedBox(
                height: 120, // Adjust as needed
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final imageModel = _images[index];
                    _logger.finest(
                      'Building item for ReorderableListView at index $index, image ID: ${imageModel.id}',
                    );
                    return Card(
                      key: ValueKey(imageModel.id ?? imageModel.imagePath),
                      // Use unique ID from ImageModel
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              File(imageModel.imagePath),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                _logger.warning(
                                  'Error building image for path: ${imageModel.imagePath}',
                                  error,
                                  stackTrace,
                                );
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(
                                (0.6 * 255).round(),
                              ), // Using withAlpha
                              shape: BoxShape.circle,
                            ),
                            child: Material(
                              // Added Material for InkWell splash effect
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Match shape
                                onTap: () => _deletePhoto(index),
                                child: const Padding(
                                  padding: EdgeInsets.all(
                                    2.0,
                                  ), // Padding inside the circle
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16, // Adjusted for padding
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    _logger.info(
                      'onReorder called. Old index: $oldIndex, New index: $newIndex',
                    );
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final ImageModel item = _images.removeAt(oldIndex);
                      _images.insert(newIndex, item);
                      _logger.finer('Image reordered. Image ID: ${item.id}');
                      _updateOrdinalNumbers();
                    });
                    widget.onImageListChanged(List<ImageModel>.from(_images));
                    _logger.info(
                      'onImageListChanged callback invoked after reorder. Image count: ${_images.length}',
                    );
                  },
                ),
              ),
      ],
    );
  }
}
