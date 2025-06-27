// lib/point_details_page.dart
import 'package:flutter/material.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/ui/widgets/photo_manager_widget.dart';

class PointDetailsPage extends StatefulWidget {
  final PointModel point;

  const PointDetailsPage({super.key, required this.point});

  @override
  State<PointDetailsPage> createState() => _PointDetailsPageState();
}

class _PointDetailsPageState extends State<PointDetailsPage> {
  final _pointFormKey = GlobalKey<FormState>();
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _noteController;
  late TextEditingController _altitudeController;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _isDeleting = false; // To handle delete loading state
  List<ImageModel> _currentImages = []; // Placeholder for photos
  bool _hasUnsavedTextChanges = false; // Tracks changes in text fields
  bool _photosChangedAndSaved =
      false; // Tracks if PhotoManagerWidget auto-saved

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
    _altitudeController = TextEditingController(
      text:
          widget.point.altitude?.toStringAsFixed(2) ??
          '', // Handle null altitude
    );
    // Initialize _currentImages from the point being edited
    _currentImages = List<ImageModel>.from(
      widget.point.images,
    ); // Make a mutable copy
    _currentImages.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));

    // Add listeners to text controllers
    _latitudeController.addListener(_markUnsavedTextChanges);
    _longitudeController.addListener(_markUnsavedTextChanges);
    _noteController.addListener(_markUnsavedTextChanges);
    _altitudeController.addListener(_markUnsavedTextChanges);

    logger.info(
      "PointDetailsPage initialized for Point ID: ${widget.point.id}, Initial image count: ${_currentImages.length}",
    );
  }

  void _markUnsavedTextChanges() {
    if (!_hasUnsavedTextChanges) {
      // Check against initial values if you want to be more precise
      // For simplicity, any change marks it.
      setState(() {
        _hasUnsavedTextChanges = true;
      });
      logger.info("Unsaved textual changes marked.");
    }
  }

  @override
  void dispose() {
    _latitudeController.removeListener(_markUnsavedTextChanges);
    _longitudeController.removeListener(_markUnsavedTextChanges);
    _noteController.removeListener(_markUnsavedTextChanges);
    _altitudeController.removeListener(_markUnsavedTextChanges);

    _latitudeController.dispose();
    _longitudeController.dispose();
    _noteController.dispose();
    _altitudeController.dispose();
    super.dispose();
  }

  Future<void> _savePointDetails({bool calledFromWillPop = false}) async {
    logger.info(
      "Attempting to save point details for point ID: ${widget.point.id}. Called from WillPop: $calledFromWillPop",
    );
    if (!_pointFormKey.currentState!.validate()) {
      logger.warning("Point details form validation failed.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct the errors in the form.'),
          ),
        );
      }
      return; // Indicate failure if called from WillPop
    }

    setState(() {
      _isLoading = true;
    });

    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);
    final double? altitudeValue = _altitudeController.text.isNotEmpty
        ? double.tryParse(_altitudeController.text)
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
    if (_altitudeController.text.isNotEmpty && altitudeValue == null) {
      if (mounted) {
        // Added mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid altitude format. Please enter a number or leave it empty.',
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

    PointModel pointToSave = widget.point.copyWith(
      latitude: latitude,
      longitude: longitude,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      altitude: altitudeValue,
      timestamp: DateTime.now(), // Or update timestamp logic
      images: _currentImages, // *** Include the current list of images ***
    );

    try {
      await _dbHelper.updatePoint(pointToSave);
      logger.info(
        "Point ID ${widget.point.id} and its images updated successfully. Image count: ${_currentImages.length}",
      );
      if (mounted) {
        setState(() {
          _hasUnsavedTextChanges = false;
          _photosChangedAndSaved = false; // Reset both flags
          // If you were editing widget.point directly, you'd update it here.
          // Since widget.point is final, this updatedPoint is what gets passed back.
        });
        if (!calledFromWillPop) {
          // Don't show SnackBar if called from WillPop save action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Point details saved!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Pop with a result to indicate success
        // This will be called by the main save button, or by the "Save & Exit" in WillPop
        if (Navigator.canPop(context)) {
          Navigator.pop(context, {'action': 'updated', 'point': pointToSave});
        }
      }
    } catch (e, stackTrace) {
      logger.severe(
        "Error saving point details for point ID ${widget.point.id}",
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving point: ${e.toString()}')),
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

  Future<bool> _onWillPop() async {
    // If there are unsaved text changes, always prompt.
    if (_hasUnsavedTextChanges) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes to point details. Save them?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Discard Text Changes'),
              onPressed: () => Navigator.of(context).pop('discard_text'),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop('cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Save All & Exit'),
              onPressed: () => Navigator.of(context).pop('save_all_and_exit'),
            ),
          ],
        ),
      );

      if (result == 'save_all_and_exit') {
        await _savePointDetails(calledFromWillPop: true);
        // _savePointDetails will pop if successful. If it's still here, save failed or page didn't pop.
        return false; // Prevent default pop; _savePointDetails handles successful pop.
      } else if (result == 'discard_text') {
        // Text changes are discarded. If photos were changed and auto-saved, pop with 'updated'.
        if (_photosChangedAndSaved) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context, {'action': 'updated'});
            return false; // We handled the pop.
          }
        }
        return true; // Allow pop, text changes discarded.
      } else {
        // 'cancel' or dialog dismissed
        return false; // Don't pop.
      }
    }
    // No unsaved text changes.
    // Check if only photos were changed and auto-saved.
    else if (_photosChangedAndSaved) {
      // Photos changed and were auto-saved. Pop with 'updated'.
      if (Navigator.canPop(context)) {
        Navigator.pop(context, {'action': 'updated'});
        return false; // We handled the pop.
      }
      // Fallback if somehow cannot pop (should not happen if page is valid)
      return true; // Or false if you want to be stricter
    }

    // No unsaved text changes, and no auto-saved photo changes to report.
    return true; // Allow normal pop.
  }

  Future<void> _deletePoint() async {
    // Show confirmation dialog (this part is UI specific and stays here)
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete point ${widget.point.name}? This action cannot be undone.',
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
          widget.point.id,
        ); // USE THE SHARED METHOD

        if (!mounted) return;

        if (count > 0) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Point ${widget.point.name} deleted successfully!',
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
                  'Error: Point ${widget.point.name} could not be found or deleted.',
                ),
                backgroundColor: Colors.red,
              ),
            );
        }
      } catch (e) {
        if (!mounted) return;
        logger.severe(
          'Failed to delete point ${widget.point.name}: $e',
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting point ${widget.point.name}: ${e.toString()}',
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Point (${widget.point.name})'),
          leading: IconButton(
            // Custom back button to ensure _onWillPop is always triggered
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                // Check if we are allowed to pop
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          actions: [
            // --- Delete Button ---
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
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Point Details',
              onPressed: _isLoading
                  ? null
                  : () => _savePointDetails(calledFromWillPop: false),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _pointFormKey,
            autovalidateMode:
                _hasUnsavedTextChanges // Or _formInteracted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ... your existing TextFormField widgets for latitude, longitude, altitude, note ...
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
                  controller: _altitudeController,
                  decoration: const InputDecoration(
                    labelText: 'altitude (m)',
                    hintText: 'e.g. 1203.5 (Optional)',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.layers), // Compass icon
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Heading is optional
                    }
                    final n = double.tryParse(value);
                    if (n == null) {
                      return 'Invalid number format';
                    }
                    if (n < 0 || n > 8849) {
                      return 'Enter a valid altitude';
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
                  // Pass a point model that reflects the current state of _currentImages
                  // but for other fields, it uses the original widget.point data
                  // This is important because PhotoManagerWidget's _savePointWithCurrentImages
                  // will use widget.point.copyWith()
                  point: widget.point.copyWith(images: _currentImages),
                  onImageListChangedForUI: (updatedImageList) {
                    if (!mounted) return;
                    setState(() {
                      _currentImages = updatedImageList;
                      // Don't mark _hasUnsavedTextChanges here, only _photosChangedAndSaved
                    });
                    logger.info(
                      "PointDetailsPage: UI updated with new image list. Count: ${updatedImageList.length}",
                    );
                  },
                  onPhotosSavedSuccessfully: () {
                    // <--- THIS IS THE CRUCIAL PART
                    if (!mounted) return;
                    setState(() {
                      _photosChangedAndSaved =
                          true; // <--- ENSURE THIS LINE IS PRESENT AND CORRECT
                    });
                    logger.info(
                      "PointDetailsPage: Notified that photos were successfully auto-saved. _photosChangedAndSaved = true",
                    );
                  },
                ),
                // ...
              ],
            ),
          ),
        ),
      ),
    );
  }
}
