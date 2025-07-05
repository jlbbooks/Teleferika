// lib/point_details_page.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/image_model.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/photo_manager_widget.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:teleferika/ui/tabs/map/map_controller.dart';

class PointDetailsPage extends StatefulWidget {
  final PointModel point;

  const PointDetailsPage({super.key, required this.point});

  @override
  State<PointDetailsPage> createState() => _PointDetailsPageState();
}

class _PointDetailsPageState extends State<PointDetailsPage> with StatusMixin {
  final Logger logger = Logger('PointDetailsPage');
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

    // Parse form values
    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);
    final double? altitudeValue = _altitudeController.text.isNotEmpty
        ? double.tryParse(_altitudeController.text)
        : null;

    // Create the point to validate
    PointModel pointToSave = widget.point.copyWith(
      latitude: latitude ?? 0.0,
      // Use 0.0 as fallback for validation
      longitude: longitude ?? 0.0,
      // Use 0.0 as fallback for validation
      note: _noteController.text.trim(),
      altitude: altitudeValue,
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
        context.projectState.updatePointInEditingState(pointToSave);
      } else {
        context.projectState.addPointInEditingState(pointToSave);
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
          title: Row(
            children: [
              Icon(Icons.edit_location, size: 24),
              const SizedBox(width: 12),
              // ignore: use_build_context_synchronously
              Text(
                S.of(context)?.edit_point_title ?? 'Edit Point',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.secondaryContainer
                                .withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.point.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Coordinates Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Coordinates',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Latitude
                          TextFormField(
                            controller: _latitudeController,
                            decoration: InputDecoration(
                              labelText:
                                  S.of(context)?.latitude_label ?? 'Latitude',
                              hintText:
                                  S.of(context)?.latitude_hint ??
                                  'e.g. 45.12345',
                              prefixIcon: Icon(
                                AppConfig.latitudeIcon,
                                color: AppConfig.latitudeColor,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return S
                                        .of(context)
                                        ?.latitude_empty_validator ??
                                    'Latitude cannot be empty';
                              }
                              final n = double.tryParse(value);
                              if (n == null) {
                                return S
                                        .of(context)
                                        ?.latitude_invalid_validator ??
                                    'Invalid number format';
                              }
                              if (n < -90 || n > 90) {
                                return S
                                        .of(context)
                                        ?.latitude_range_validator ??
                                    'Latitude must be between -90 and 90';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Longitude
                          TextFormField(
                            controller: _longitudeController,
                            decoration: InputDecoration(
                              labelText:
                                  S.of(context)?.longitude_label ?? 'Longitude',
                              hintText:
                                  S.of(context)?.longitude_hint ??
                                  'e.g. -12.54321',
                              prefixIcon: Icon(
                                AppConfig.longitudeIcon,
                                color: AppConfig.longitudeColor,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return S
                                        .of(context)
                                        ?.longitude_empty_validator ??
                                    'Longitude cannot be empty';
                              }
                              final n = double.tryParse(value);
                              if (n == null) {
                                return S
                                        .of(context)
                                        ?.longitude_invalid_validator ??
                                    'Invalid number format';
                              }
                              if (n < -180 || n > 180) {
                                return S
                                        .of(context)
                                        ?.longitude_range_validator ??
                                    'Longitude must be between -180 and 180';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Additional Data Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context)?.additional_data_section_title ??
                                    'Additional Data',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Altitude
                          TextFormField(
                            controller: _altitudeController,
                            decoration: InputDecoration(
                              labelText:
                                  S.of(context)?.altitude_label ??
                                  'Altitude (m)',
                              hintText:
                                  S.of(context)?.altitude_hint ??
                                  'e.g. 1203.5 (Optional)',
                              prefixIcon: Icon(
                                AppConfig.altitudeIcon,
                                color: AppConfig.altitudeColor,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true, // Allow negative values
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null; // Altitude is optional
                              }
                              final n = double.tryParse(value);
                              if (n == null) {
                                return S
                                        .of(context)
                                        ?.altitude_invalid_validator ??
                                    'Invalid number format';
                              }
                              if (n < -1000 || n > 8849) {
                                return S
                                        .of(context)
                                        ?.altitude_range_validator ??
                                    'Altitude must be between -1000 and 8849 meters';
                              }
                              return null;
                            },
                          ),
                          // Distance from previous point
                          Builder(
                            builder: (context) {
                              final points = context.projectState.currentPoints;
                              final selected = widget.point;
                              final idx = points.indexWhere(
                                (p) => p.id == selected.id,
                              );
                              if (idx <= 0) return SizedBox.shrink();
                              final prev = points[idx - 1];
                              final dist = prev.distanceFromPoint(selected);
                              String distStr;
                              if (dist >= 1000) {
                                distStr =
                                    '${(dist / 1000).toStringAsFixed(2)} km';
                              } else {
                                distStr = '${dist.toStringAsFixed(1)} m';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.straighten,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      S
                                              .of(context)
                                              ?.distanceFromPrevious(
                                                prev.name,
                                              ) ??
                                          'Distance from ${prev.name}:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      distStr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Offset
                          Builder(
                            builder: (context) {
                              final points = context.projectState.currentPoints;
                              double? distanceToLine;
                              if (points.length >= 2) {
                                final logic = MapControllerLogic(
                                  project: context.projectState.currentProject!,
                                );
                                distanceToLine = logic
                                    .distanceFromPointToFirstLastLine(
                                      widget.point,
                                      points,
                                    );
                              }
                              String? distanceToLineStr;
                              if (distanceToLine != null) {
                                if (distanceToLine >= 1000) {
                                  distanceToLineStr =
                                      '${(distanceToLine / 1000).toStringAsFixed(2)} km';
                                } else {
                                  distanceToLineStr =
                                      '${distanceToLine.toStringAsFixed(1)} m';
                                }
                              }
                              if (distanceToLine == null ||
                                  distanceToLine <= 0.0) {
                                return SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.straighten,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      S.of(context)?.offsetLabel ?? 'Offset:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      distanceToLineStr ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Note
                          TextFormField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText:
                                  S.of(context)?.note_label ??
                                  'Note (Optional)',
                              hintText:
                                  S.of(context)?.note_hint ??
                                  'Any observations or details...',
                              prefixIcon: Icon(
                                Icons.notes_outlined,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.all(16.0),
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Photos Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.tertiaryContainer
                                .withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_library,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context)?.photos_section_title ?? 'Photos',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PhotoManagerWidget(
                            // Pass a point model that reflects the current state of _currentImages
                            // but for other fields, it uses the original widget.point data
                            // This is important because PhotoManagerWidget's _savePointWithCurrentImages
                            // will use widget.point.copyWith()
                            point: widget.point.copyWith(
                              images: _currentImages,
                            ),
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
                        ],
                      ),
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
