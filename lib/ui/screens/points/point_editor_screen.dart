// point_editor_screen.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

import 'components/point_details_section.dart';
import 'components/point_photos_section.dart';

class PointEditorScreen extends StatefulWidget {
  final PointModel point;

  const PointEditorScreen({super.key, required this.point});

  @override
  State<PointEditorScreen> createState() => _PointEditorScreenState();
}

class _PointEditorScreenState extends State<PointEditorScreen>
    with StatusMixin {
  final Logger logger = Logger('PointEditorScreen');
  final _pointFormKey = GlobalKey<FormState>();
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _noteController;
  late TextEditingController _altitudeController;
  late TextEditingController _gpsPrecisionController;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _isDeleting = false; // To handle delete loading state
  List<ImageModel> _currentImages = []; // Placeholder for photos
  bool _hasUnsavedTextChanges = false; // Tracks changes in text fields
  bool _photosChangedAndSaved =
      false; // Tracks if PhotoManagerWidget auto-saved
  bool _hasUnsavedChanges = false; // Track if there are any unsaved changes

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController(
      text: widget.point.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: widget.point.longitude.toString(),
    );
    _noteController = TextEditingController(text: widget.point.note);
    _altitudeController = TextEditingController(
      text: widget.point.altitude?.toStringAsFixed(2) ?? '',
    );
    _gpsPrecisionController = TextEditingController(
      text: widget.point.gpsPrecision?.toStringAsFixed(2) ?? '',
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
    _gpsPrecisionController.addListener(_markUnsavedTextChanges);

    logger.info(
      "PointEditorScreen initialized for Point ID: ${widget.point.id}, Initial image count: ${_currentImages.length}",
    );
  }

  void _markUnsavedTextChanges() {
    if (!_hasUnsavedTextChanges) {
      // Check against initial values if you want to be more precise
      // For simplicity, any change marks it.
      setState(() {
        _hasUnsavedTextChanges = true;
        _hasUnsavedChanges = true;
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
    _gpsPrecisionController.removeListener(_markUnsavedTextChanges);

    _latitudeController.dispose();
    _longitudeController.dispose();
    _noteController.dispose();
    _altitudeController.dispose();
    _gpsPrecisionController.dispose();
    super.dispose();
  }

  Future<void> _savePointDetails({bool calledFromWillPop = false}) async {
    logger.info(
      "Attempting to save point details for point ID: ${widget.point.id}. Called from WillPop: $calledFromWillPop",
    );

    // Parse form values
    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);
    final double? altitudeValue = _altitudeController.text.isNotEmpty
        ? double.tryParse(_altitudeController.text)
        : null;
    final double? gpsPrecisionValue = _gpsPrecisionController.text.isNotEmpty
        ? double.tryParse(_gpsPrecisionController.text)
        : null;

    // Create the point to validate
    PointModel pointToSave = widget.point.copyWith(
      latitude: latitude ?? 0.0,
      // Use 0.0 as fallback for validation
      longitude: longitude ?? 0.0,
      // Use 0.0 as fallback for validation
      note: _noteController.text.trim(),
      altitude: altitudeValue,
      gpsPrecision: gpsPrecisionValue,
      timestamp: DateTime.now(),
      images: _currentImages,
    );

    // Use model validation instead of form validation
    if (!pointToSave.isValid) {
      logger.warning(
        "Point validation failed: ${pointToSave.validationErrors}",
      );
      showErrorStatus(
        S
                .of(context)
                ?.error_saving_point(pointToSave.validationErrors.join(', ')) ??
            'Error saving point: ${pointToSave.validationErrors.join(', ')}',
      );
      return;
    }

    // Additional validation for parsing errors
    if (latitude == null || longitude == null) {
      showErrorStatus(
        S.of(context)?.invalid_latitude_or_longitude_format ??
            'Invalid latitude or longitude format.',
      );
      return;
    }

    if (_altitudeController.text.isNotEmpty && altitudeValue == null) {
      showErrorStatus(
        S.of(context)?.invalid_altitude_format ??
            'Invalid altitude format. Please enter a number or leave it empty.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final exists = context.projectState.currentPoints.any(
        (p) => p.id == pointToSave.id,
      );
      if (exists) {
        final success = await context.projectState.updatePoint(pointToSave);
        if (!success) {
          logger.warning("Failed to update point ${pointToSave.id}");
          showErrorStatus('Error updating point');
          return;
        }
      } else {
        final success = await context.projectState.createPoint(pointToSave);
        if (!success) {
          logger.warning("Failed to create point ${pointToSave.id}");
          showErrorStatus('Error creating point');
          return;
        }
      }
      logger.info(
        "Point ID ${widget.point.id} and its images updated successfully. Image count: ${_currentImages.length}",
      );
      if (mounted) {
        setState(() {
          _hasUnsavedTextChanges = false;
          _photosChangedAndSaved = false;
          _hasUnsavedChanges = false;
        });
        if (!calledFromWillPop) {
          showSuccessStatus(
            S.of(context)?.point_details_saved ?? 'Point details saved!',
          );
        }
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
      showErrorStatus(
        S.of(context)?.error_saving_point(e.toString()) ??
            'Error saving point: ${e.toString()}',
      );
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
          title: Text(
            S.of(context)?.unsaved_point_details_title ?? 'Unsaved Changes',
          ),
          content: Text(
            S.of(context)?.unsaved_point_details_content ??
                'You have unsaved changes to point details. Save them?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                S.of(context)?.discard_text_changes ?? 'Discard Text Changes',
              ),
              onPressed: () => Navigator.of(context).pop('discard_text'),
            ),
            TextButton(
              child: Text(S.of(context)?.dialog_cancel ?? 'Cancel'),
              onPressed: () => Navigator.of(context).pop('cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(
                S.of(context)?.save_all_and_exit ?? 'Save All & Exit',
              ),
              onPressed: () => Navigator.of(context).pop('save_all_and_exit'),
            ),
          ],
        ),
      );

      if (!mounted) return false;
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
      builder: (BuildContext dialogContext) {
        final s = S.of(dialogContext);
        return AlertDialog(
          title: Text(s?.confirm_deletion_title ?? 'Confirm Deletion'),
          content: Text(
            s?.confirm_deletion_content(widget.point.name) ??
                'Are you sure you want to delete point ${widget.point.name}? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(s?.dialog_cancel ?? 'Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(
                s?.buttonDelete ?? 'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return; // Check if widget is still in the tree
      setState(() => _isDeleting = true); // UI feedback

      try {
        // Use global state to delete the point
        context.projectState.deletePointInEditingState(widget.point.id);

        if (!mounted) return;

        showSuccessStatus(
          S.of(context)?.point_deleted_success(widget.point.name) ??
              'Point ${widget.point.name} deleted successfully!',
        );
        // Pop with structured result
        Navigator.pop(context, {
          'action': 'deleted',
          'pointId': widget.point.id,
          'ordinalNumber': widget.point.ordinalNumber,
        });
      } catch (e) {
        if (!mounted) return;
        logger.severe('Failed to delete point ${widget.point.name}: $e');
        showErrorStatus(
          S
                  .of(context)
                  ?.error_deleting_point(widget.point.name, e.toString()) ??
              'Error deleting point ${widget.point.name}: ${e.toString()}',
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted && Navigator.canPop(this.context)) {
            Navigator.of(this.context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.point.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            // Custom back button to ensure _onWillPop is always triggered
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (!context.mounted) return;
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
              tooltip: S.of(context)?.delete_project_tooltip ?? 'Delete Point',
              onPressed: _isLoading || _isDeleting ? null : _deletePoint,
            ),
            IconButton(
              icon: Icon(
                Icons.save,
                color: _hasUnsavedChanges ? Colors.green : null,
              ),
              tooltip:
                  S.of(context)?.save_project_tooltip ?? 'Save Point Details',
              onPressed: _isLoading
                  ? null
                  : () => _savePointDetails(calledFromWillPop: false),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _pointFormKey,
                autovalidateMode:
                    _hasUnsavedTextChanges // Or _formInteracted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Point Details Section (coordinates, altitude, note)
                    PointDetailsSection(
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      altitudeController: _altitudeController,
                      noteController: _noteController,
                      gpsPrecisionController: _gpsPrecisionController,
                    ),
                    const SizedBox(height: 20),

                    // Photos Section
                    PointPhotosSection(
                      point: widget.point.copyWith(images: _currentImages),
                      onImageListChangedForUI: (updatedImageList) {
                        if (!mounted) return;
                        setState(() {
                          _currentImages = updatedImageList.cast<ImageModel>();
                          // Don't mark _hasUnsavedTextChanges here, only _photosChangedAndSaved
                        });
                        logger.info(
                          "PointEditorScreen: UI updated with new image list. Count: ${updatedImageList.length}",
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
                          "PointEditorScreen: Notified that photos were successfully auto-saved. _photosChangedAndSaved = true",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: StatusIndicator(
                status: currentStatus,
                onDismiss: hideStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
