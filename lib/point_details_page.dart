// lib/point_details_page.dart
import 'package:flutter/material.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/logger.dart';
import 'package:teleferika/photo_manager_widget.dart';

import 'db/models/image_model.dart';

class PointDetailsPage extends StatefulWidget {
  final PointModel point;

  // Optional: Pass projectId if needed for context, or if creating a new point
  // final int projectId;

  const PointDetailsPage({
    super.key,
    required this.point,
    // required this.projectId,
  });

  @override
  State<PointDetailsPage> createState() => _PointDetailsPageState();
}

class _PointDetailsPageState extends State<PointDetailsPage> {
  final _pointFormKey = GlobalKey<FormState>();
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _noteController;
  late TextEditingController _headingController;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _isDeleting = false; // To handle delete loading state
  List<ImageModel> _currentImages = []; // Placeholder for photos>

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController(
      text: widget.point.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: widget.point.longitude.toString(),
    );
    _noteController = TextEditingController(text: widget.point.note ?? '');
    _headingController = TextEditingController(
      text:
          widget.point.heading?.toStringAsFixed(2) ?? '', // Handle null heading
    );
    // Initialize _currentImages from the point being edited
    _currentImages = List<ImageModel>.from(
      widget.point.images,
    ); // Make a mutable copy
    _currentImages.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));

    logger.info(
      "PointDetailsPage initialized for Point ID: ${widget.point.id}, Ordinal: ${widget.point.ordinalNumber}, Initial image count: ${_currentImages.length}",
    );
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _noteController.dispose();
    _headingController.dispose();
    super.dispose();
  }

  Future<void> _savePointDetails() async {
    logger.info(
      "Attempting to save point details for point ID: ${widget.point.id}",
    );
    if (!_pointFormKey.currentState!.validate()) {
      logger.warning("Point details form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);
    final double? headingValue = _headingController.text.isNotEmpty
        ? double.tryParse(_headingController.text)
        : null;

    if (latitude == null || longitude == null) {
      if (mounted) {
        // Added mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid latitude or longitude format.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }
    if (_headingController.text.isNotEmpty && headingValue == null) {
      if (mounted) {
        // Added mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid heading format. Please enter a number or leave it empty.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    PointModel updatedPoint = PointModel(
      id: widget.point.id, // ID must not be null for an update
      projectId: widget.point.projectId,
      latitude: latitude,
      longitude: longitude,
      ordinalNumber: widget.point.ordinalNumber,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      heading: headingValue,
      timestamp:
          widget.point.timestamp ?? DateTime.now(), // Or update timestamp logic
      images: _currentImages, // *** Include the current list of images ***
    );
    logger.info(
      "Updated PointModel created: $updatedPoint with ${_currentImages.length} images.",
    );

    try {
      await _dbHelper.updatePoint(updatedPoint);
      logger.info(
        "Point ID ${widget.point.id} and its images updated successfully. Image count: ${_currentImages.length}",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Point details and images saved!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop with a result to indicate success and potentially pass back the updated point
        Navigator.pop(context, {'action': 'updated', 'point': updatedPoint});
      }
    } catch (e, stackTrace) {
      logger.severe(
        "Error saving point details (and images) for point ID ${widget.point.id}",
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving point: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePoint() async {
    // Show confirmation dialog (this part is UI specific and stays here)
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete point P${widget.point.ordinalNumber}? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return; // Check if widget is still in the tree
      setState(() => _isDeleting = true); // UI feedback

      try {
        final int count = await _dbHelper.deletePointById(
          widget.point.id!,
        ); // USE THE SHARED METHOD

        if (!mounted) return;

        if (count > 0) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Point P${widget.point.ordinalNumber} deleted successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          // Pop with structured result
          Navigator.pop(context, {
            'action': 'deleted',
            'pointId': widget.point.id,
            'ordinalNumber': widget.point.ordinalNumber,
          });
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Point P${widget.point.ordinalNumber} could not be found or deleted.',
                ),
                backgroundColor: Colors.red,
              ),
            );
        }
      } catch (e) {
        if (!mounted) return;
        logger.severe(
          'Failed to delete point P${widget.point.ordinalNumber}: $e',
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting point P${widget.point.ordinalNumber}: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.point.id == null
              ? 'New Point' // Should ideally not happen if coming to details page
              : 'Point P${widget.point.ordinalNumber} Details',
        ),
        actions: [
          // --- NEW: Delete Button ---
          if (widget.point.id !=
              null) // Only show delete if the point exists in DB
            IconButton(
              icon: _isDeleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(
                            context,
                          ).colorScheme.onPrimary, // Or any contrasting color
                        ),
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete Point',
              onPressed: _isLoading || _isDeleting ? null : _deletePoint,
            ),
          // --- END NEW ---
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(
                          context,
                        ).colorScheme.onPrimary, // Or any contrasting color
                      ),
                    ),
                  )
                : const Icon(Icons.save_outlined),
            tooltip: 'Save Changes',
            onPressed: _isLoading || _isDeleting ? null : _savePointDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _pointFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... your existing TextFormField widgets for latitude, longitude, heading, note ...
              // --- Latitude ---
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g. 45.12345',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.pin_drop_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Latitude cannot be empty';
                  }
                  final n = double.tryParse(value);
                  if (n == null) {
                    return 'Invalid number format';
                  }
                  if (n < -90 || n > 90) {
                    return 'Latitude must be between -90 and 90';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // --- Longitude ---
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g. -12.54321',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.pin_drop_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Longitude cannot be empty';
                  }
                  final n = double.tryParse(value);
                  if (n == null) {
                    return 'Invalid number format';
                  }
                  if (n < -180 || n > 180) {
                    return 'Longitude must be between -180 and 180';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _headingController,
                decoration: const InputDecoration(
                  labelText: 'Heading (degrees)',
                  hintText: 'e.g. 123.5 (Optional)',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.explore_outlined), // Compass icon
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Heading is optional
                  }
                  final n = double.tryParse(value);
                  if (n == null) {
                    return 'Invalid number format';
                  }
                  if (n <= -360 || n >= 360) {
                    return 'Heading must be between -359.9 and 359.9';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // --- Note ---
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Any observations or details...',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24.0),

              // --- Photos Section ---
              const Divider(thickness: 1, height: 32),
              PhotoManagerWidget(
                pointId: widget.point.id!,
                // Make sure widget.point.id is not null
                initialImages: _currentImages,
                onImageListChanged: (updatedImageList) {
                  setState(() {
                    _currentImages = updatedImageList;
                    // _hasUnsavedChanges = true; // If you have such a flag
                  });
                },
              ),
              // ...
            ],
          ),
        ),
      ),
    );
  }
}
