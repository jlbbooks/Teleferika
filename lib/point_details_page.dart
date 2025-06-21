// lib/point_details_page.dart
import 'package:flutter/material.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/logger.dart';

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
    logger.info(
      "PointDetailsPage initialized for Point ID: ${widget.point.id}, Ordinal: ${widget.point.ordinalNumber}",
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
    if (!_pointFormKey.currentState!.validate()) {
      logger.warning("Point details form validation failed.");
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
      id: widget.point.id,
      projectId: widget.point.projectId,
      latitude: latitude,
      longitude: longitude,
      ordinalNumber: widget.point.ordinalNumber,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      heading: headingValue,
      timestamp: widget.point.timestamp ?? DateTime.now(),
    );

    try {
      await _dbHelper.updatePoint(updatedPoint);
      logger.info("Point ID ${widget.point.id} updated successfully.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Point details saved!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop with a result to indicate success and potentially pass back the updated point
        Navigator.pop(context, {'action': 'updated', 'point': updatedPoint});
      }
    } catch (e, stackTrace) {
      logger.severe(
        "Error saving point details for point ID ${widget.point.id}",
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

  // --- NEW: Method to handle point deletion ---
  Future<void> _confirmDeletePoint() async {
    if (widget.point.id == null) {
      logger.warning("Attempted to delete a point with no ID.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete unsaved point.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete point P${widget.point.ordinalNumber}? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deletePoint();
    }
  }

  Future<void> _deletePoint() async {
    if (widget.point.id == null) {
      return; // Should be caught by _confirmDeletePoint
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _dbHelper.deletePoint(widget.point.id!);
      // You might need to update project's start/end point if this point was one of them
      // This logic might be complex and could involve checking ProjectModel.startPointId/endPointId
      // For now, just deleting the point. Consider adding that logic if needed.
      logger.info("Point ID ${widget.point.id} deleted successfully.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Point P${widget.point.ordinalNumber} deleted.'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop with a result to indicate success and the action taken
        Navigator.pop(context, {
          'action': 'deleted',
          'pointId': widget.point.id,
        });
      }
    } catch (e, stackTrace) {
      logger.severe(
        "Error deleting point ID ${widget.point.id}",
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting point: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // --- END NEW ---

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
              onPressed: _isLoading || _isDeleting ? null : _confirmDeletePoint,
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

              // --- Placeholder for Photos Section ---
              const Divider(thickness: 1, height: 32),
              Text('Photos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Photo management will be here.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              ElevatedButton.icon(
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.save_alt_outlined),
                label: const Text('Save Point Details'),
                onPressed: _isLoading || _isDeleting ? null : _savePointDetails,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
