// compass_tool_view.dart
import 'dart:async';
import 'dart:math' as math; // For PI

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

class CompassToolView extends StatefulWidget {
  const CompassToolView({
    super.key,
  });

  @override
  State<CompassToolView> createState() => _CompassToolViewState();
}

class _CompassToolViewState extends State<CompassToolView> with StatusMixin {
  double? _heading; // Current heading from the compass
  double? _accuracy; // Compass accuracy
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasLocationPermission = false;
  bool _hasSensorPermission = false;
  bool _isCompassAvailable = false;
  bool _isAddingPoint = false; // Internal loading state

  // State variable for the checkbox - persists during project session
  static bool _setAsEndPoint = true;

  @override
  void initState() {
    super.initState();
    logger.info("CompassToolView initialized");
    // Check if compass is available
    _checkCompassAvailability();
  }

  Future<void> _checkCompassAvailability() async {
    try {
      final isCompassAvailable = await FlutterCompass.events?.first != null;
      
      if (mounted) {
        setState(() {
          _isCompassAvailable = isCompassAvailable;
        });
      }

      if (!isCompassAvailable) {
        showErrorStatus('Compass sensor not available on this device.');
      }
    } catch (e) {
      logger.severe("Error checking compass availability", e);
      if (mounted) {
        showErrorStatus('Error checking compass availability: $e');
      }
    }
  }

  // Handle permission results from the PermissionHandlerWidget
  void _handlePermissionResults(Map<PermissionType, bool> permissions) {
    final hasLocation = permissions[PermissionType.location] ?? false;
    final hasSensor = permissions[PermissionType.sensor] ?? false;

    setState(() {
      _hasLocationPermission = hasLocation;
      _hasSensorPermission = hasSensor;
    });

    if (hasSensor && _isCompassAvailable) {
      _listenToCompass();
    } else if (!hasSensor) {
      showInfoStatus('Sensor permission denied. Compass features will be unavailable.');
    }

    if (!hasLocation) {
      showInfoStatus('Location permission denied. Location features will be limited.');
    }
  }

  void _listenToCompass() {
    try {
      _compassSubscription = FlutterCompass.events?.listen(
        (CompassEvent event) {
          if (mounted) {
            setState(() {
              _heading = event.heading;
              _accuracy = event.accuracy;
            });
          }
        },
        onError: (error) {
          logger.warning("Compass error: $error");
          if (mounted) {
            showErrorStatus('Compass error: $error');
          }
        },
      );
    } catch (e) {
      logger.severe("Error setting up compass listener", e);
      showErrorStatus('Error setting up compass: $e');
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _handleAddPointPressed(BuildContext context, ProjectStateManager projectState) {
    if (_heading != null) {
      logger.info(
        "Add Point button tapped. Current Heading: ${_heading!.toStringAsFixed(1)}°, Set as End Point: $_setAsEndPoint. Using global state.",
      );
      // Use global state to add point directly
      _addPointFromCompass(context, projectState, _heading!, setAsEndPoint: _setAsEndPoint);
    } else {
      final s = S.of(context);
      showErrorStatus(
        s?.compassHeadingNotAvailable ??
            'Cannot add point: Compass heading not available.',
      );
    }
  }

  Future<void> _addPointFromCompass(
    BuildContext context,
    ProjectStateManager projectState,
    double heading, {
    bool? setAsEndPoint,
  }) async {
    final bool addAsEndPoint = setAsEndPoint ?? false;
    final currentProject = projectState.currentProject;
    
    if (currentProject == null) {
      showErrorStatus('No project loaded');
      return;
    }
    
    logger.info(
      "Adding point from compass. Heading: $heading, Project ID: ${currentProject.id}, Set as End Point: $addAsEndPoint",
    );
    
    setState(() {
      _isAddingPoint = true;
    });
    
    showLoadingStatus(S.of(context)!.infoFetchingLocation);

    try {
      final position = await _determinePosition();
      final pointFromCompass = PointModel(
        projectId: currentProject.id,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        ordinalNumber: 0, // Will be set by OrdinalManager
        note: S
            .of(context)!
            .pointFromCompassDefaultNote(heading.toStringAsFixed(1)),
      );

      String newPointIdFromCompass;
      final dbHelper = DatabaseHelper.instance;

      // Use OrdinalManager to handle the complex ordinal logic
      if (!addAsEndPoint && currentProject.endingPointId != null) {
        // Insert before end point
        await dbHelper.ordinalManager.insertPointBeforeEndPoint(
          pointFromCompass,
          currentProject.endingPointId!,
        );
        // Get the inserted point ID (we need to query for it)
        final points = await dbHelper.getPointsForProject(currentProject.id);
        final insertedPoint = points.firstWhere(
          (p) =>
              p.latitude == position.latitude &&
              p.longitude == position.longitude &&
              p.note == pointFromCompass.note,
          orElse: () => throw Exception('Inserted point not found'),
        );
        newPointIdFromCompass = insertedPoint.id;
      } else {
        // Append to end
        await dbHelper.ordinalManager.insertPointAtOrdinal(
          pointFromCompass,
          null,
        );
        // Get the inserted point ID
        final points = await dbHelper.getPointsForProject(currentProject.id);
        final insertedPoint = points.firstWhere(
          (p) =>
              p.latitude == position.latitude &&
              p.longitude == position.longitude &&
              p.note == pointFromCompass.note,
          orElse: () => throw Exception('Inserted point not found'),
        );
        newPointIdFromCompass = insertedPoint.id;
      }

      logger.info(
        'Point added via Compass: ID $newPointIdFromCompass, Lat: ${position.latitude}, Lon: ${position.longitude}, Heading used for note: $heading',
      );

      if (addAsEndPoint) {
        ProjectModel projectToUpdate = currentProject
            .copyWith(endingPointId: newPointIdFromCompass);
        await projectState.updateProject(projectToUpdate);
        logger.info(
          "New point ID $newPointIdFromCompass set as the END point for project ${currentProject.id}.",
        );
      }

      await dbHelper.updateProjectStartEndPoints(currentProject.id);
      // Refresh global state
      await projectState.refreshPoints();

      if (mounted) {
        hideStatus();
        // Get the final point to get the correct ordinal
        final finalPoint = await dbHelper.getPointById(newPointIdFromCompass);
        String baseMessage = S
            .of(context)!
            .pointAddedSnackbar(finalPoint?.ordinalNumber.toString() ?? '?');
        String suffix = "";
        if (addAsEndPoint == true) {
          suffix = " ${S.of(context)!.pointAddedSetAsEndSnackbarSuffix}";
        } else if (currentProject.endingPointId != null) {
          suffix =
              " ${S.of(context)!.pointAddedInsertedBeforeEndSnackbarSuffix}";
        }
        showSuccessStatus(baseMessage + suffix);
      }
    } catch (e, stackTrace) {
      logger.severe("Error adding point from compass", e, stackTrace);
      if (mounted) {
        hideStatus();
        showErrorStatus(S.of(context)!.errorAddingPoint(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingPoint = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Widget _buildProjectAzimuthText(ProjectModel project) {
    final s = S.of(context);
    String azimuthText;
    Color textColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.black;
    bool hasCalculatedAzimuth = project.azimuth != null;

    if (hasCalculatedAzimuth) {
      azimuthText =
          s?.projectAzimuthLabel(project.azimuth!.toStringAsFixed(1)) ??
          'Project Azimuth: ${project.azimuth!.toStringAsFixed(1)}°';
    } else {
      if (project.startingPointId == null ||
          project.endingPointId == null) {
        azimuthText =
            s?.projectAzimuthRequiresPoints ??
            'Project Azimuth: (Requires at least 2 points)';
        textColor = Colors.orange.shade700;
      } else {
        azimuthText =
            s?.projectAzimuthNotCalculated ??
            'Project Azimuth: Not yet calculated';
        textColor = Colors.grey.shade600;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        azimuthText,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAccuracyIndicator() {
    if (_accuracy == null) return const SizedBox.shrink();

    final s = S.of(context);
    Color accuracyColor;
    String accuracyText;

    if (_accuracy! < 5) {
      accuracyColor = Colors.green;
      accuracyText = s?.compassAccuracyHigh ?? 'High Accuracy';
    } else if (_accuracy! < 15) {
      accuracyColor = Colors.orange;
      accuracyText = s?.compassAccuracyMedium ?? 'Medium Accuracy';
    } else {
      accuracyColor = Colors.red;
      accuracyText = s?.compassAccuracyLow ?? 'Low Accuracy';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radio_button_checked, color: accuracyColor, size: 12),
          const SizedBox(width: 4),
          Text(
            accuracyText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: accuracyColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        // Get current project from global state
        final currentProject = projectState.currentProject;
        
        if (currentProject == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return PermissionHandlerWidget(
          requiredPermissions: [PermissionType.location, PermissionType.sensor],
          onPermissionsResult: _handlePermissionResults,
          showOverlay: false, // Full screen for compass
          child: _buildCompassContent(currentProject, projectState),
        );
      },
    );
  }

  Widget _buildCompassContent(ProjectModel currentProject, ProjectStateManager projectState) {
    // Show basic compass background when permissions are missing or compass unavailable
    if (!_hasLocationPermission || !_hasSensorPermission || !_isCompassAvailable) {
      return Stack(
        children: [
          // Show a basic compass background when permissions are missing
          Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.compass_calibration_outlined,
                  size: 100,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Compass Tool',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          Positioned(
            top: 24,
            right: 24,
            child: StatusIndicator(
              status: currentStatus,
              onDismiss: hideStatus,
            ),
          ),
        ],
      );
    }

    final s = S.of(context);

    // Determine the rotation for the project azimuth arrow
    double projectAzimuthArrowRotationDegrees = 0;
    if (currentProject.azimuth != null && _heading != null) {
      projectAzimuthArrowRotationDegrees = currentProject.azimuth! - _heading!;
    } else if (currentProject.azimuth != null && _heading == null) {
      projectAzimuthArrowRotationDegrees = currentProject.azimuth!;
    }

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // --- Heading Display ---
                Column(
                  children: [
                    Text(
                      _heading == null
                          ? '---°'
                          : '${_heading!.toStringAsFixed(1)}° ${getDirectionLetter(_heading!)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    _buildAccuracyIndicator(),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Compass Rose and Project Azimuth Arrow ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compassSize = math.min(constraints.maxWidth - 32, 250.0);
                    return SizedBox(
                      width: compassSize,
                      height: compassSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Compass Rose (Rotates to keep North up)
                          Transform.rotate(
                            angle: (_heading != null)
                                ? (-(_heading!) * (math.pi / 180))
                                : 0,
                            child: Image.asset('assets/images/compass_rose.png'),
                          ),
                          // 2. Project Azimuth Arrow (Conditionally displayed and rotated)
                          if (currentProject.azimuth != null)
                            Transform.rotate(
                              angle:
                                  (projectAzimuthArrowRotationDegrees *
                                  (math.pi / 180)),
                              child: Image.asset(
                                'assets/images/direction_arrow.png',
                                width: compassSize * 0.72, // 180/250 = 0.72
                                height: compassSize * 0.72,
                                color: Colors.blueGrey.withAlpha(
                                  (0.7 * 255).round(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- "Add as END point" Checkbox ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CheckboxListTile(
                    title: Text(
                      s?.compassAddAsEndPointButton ?? "Add as END point",
                    ),
                    value: _setAsEndPoint,
                    onChanged: (bool? value) {
                      if (mounted) {
                        setState(() {
                          _setAsEndPoint = value ?? false;
                        });
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // --- Add Point Button ---
                if (_isAddingPoint)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  SizedBox(
                    width: 200, // Fixed width for consistency
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(s?.compassAddPointButton ?? 'Add Point'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () => _handleAddPointPressed(context, projectState),
                    ),
                  ),
                _buildProjectAzimuthText(currentProject),
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
    );
  }

  // Helper to get cardinal/intercardinal direction letter
  String getDirectionLetter(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return '';
  }
}
