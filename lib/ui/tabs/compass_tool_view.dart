// compass_tool_view.dart
import 'dart:async';
import 'dart:math' as math; // For PI

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
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
import 'package:teleferika/core/utils/ordinal_manager.dart';
import 'package:uuid/uuid.dart';

class CompassToolView extends StatefulWidget {
  const CompassToolView({
    super.key,
  });

  @override
  State<CompassToolView> createState() => _CompassToolViewState();
}

class _CompassToolViewState extends State<CompassToolView> with StatusMixin {
  final Logger logger = Logger('CompassToolView');
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
    // Check if compass is available
    _checkCompassAvailability();
  }

  Future<void> _checkCompassAvailability() async {
    try {
      // Check if FlutterCompass.events is not null (this indicates compass is available)
      final isCompassAvailable = FlutterCompass.events != null;
      
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
        setState(() {
          _isCompassAvailable = false;
        });
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

    // Cancel any existing subscription before setting up a new one
    _compassSubscription?.cancel();

    if (hasSensor && _isCompassAvailable) {
      _listenToCompass();
    } else if (!hasSensor) {
      showInfoStatus('Sensor permission denied. Compass features will be unavailable.');
    } else if (!_isCompassAvailable) {
      showInfoStatus('Compass sensor not available on this device.');
    }

    if (!hasLocation) {
      showInfoStatus('Location permission denied. Location features will be limited.');
    }
  }

  void _listenToCompass() {
    try {
      if (FlutterCompass.events == null) {
        logger.warning("FlutterCompass.events is null, cannot listen to compass");
        showErrorStatus('Compass events stream is not available');
        return;
      }

      _compassSubscription = FlutterCompass.events!.listen(
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

  // Manual retry method for compass setup
  void _retryCompassSetup() {
    _compassSubscription?.cancel();
    
    if (_hasSensorPermission && _isCompassAvailable) {
      _listenToCompass();
    } else {
      showInfoStatus('Cannot retry: Sensor permission or compass not available');
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _handleAddPointPressed(BuildContext context, ProjectStateManager projectState) {
    if (_heading != null) {
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
    
    setState(() {
      _isAddingPoint = true;
    });
    
    final s = S.of(context);
    showLoadingStatus(s?.infoFetchingLocation ?? 'Fetching location...');

    try {
      final location = await _getCurrentLocation();
      if (location == null) {
        showErrorStatus(s?.errorLocationUnavailable ?? 'Location unavailable');
        setState(() {
          _isAddingPoint = false;
        });
        return;
      }

      // Get the current in-memory points
      final points = List<PointModel>.from(projectState.currentPoints);
      final newPointId = const Uuid().v4();
      final newPoint = PointModel(
        id: newPointId,
        projectId: currentProject.id,
        latitude: location.latitude,
        longitude: location.longitude,
        altitude: location.altitude,
        ordinalNumber: 0, // will be set by OrdinalManager
        note: s?.pointFromCompassDefaultNote(heading.toStringAsFixed(1)) ?? 'Point from compass at ${heading.toStringAsFixed(1)}°',
      );

      int insertIndex = points.length;
      String? newEndingPointId = currentProject.endingPointId;
      if (!addAsEndPoint && currentProject.endingPointId != null) {
        // Insert just before the current end point
        insertIndex = points.indexWhere((p) => p.id == currentProject.endingPointId);
        if (insertIndex == -1) {
          insertIndex = points.length; // fallback: append
        }
      } else if (addAsEndPoint) {
        // Set as new end point
        newEndingPointId = newPointId;
        insertIndex = points.length;
      }

      // Insert the new point at the correct index
      final updatedPoints = OrdinalManager.insertAtOrdinal(points, newPoint, insertIndex);

      // Update the in-memory project (endingPointId if needed)
      final updatedProject = currentProject.copyWith(
        endingPointId: newEndingPointId,
        points: updatedPoints,
      );
      projectState.updateEditingProject(updatedProject);
      showInfoStatus(s?.infoPointAddedPendingSave ?? 'Point added (pending save)');
    } catch (e, st) {
      logger.severe('Error adding point from compass', e, st);
      showErrorStatus('${s?.errorGeneric ?? 'Error'}: $e');
    } finally {
      setState(() {
        _isAddingPoint = false;
      });
    }
  }

  Future<Position?> _getCurrentLocation() async {
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
        final hasUnsavedNewPoint = projectState.hasUnsavedNewPoint;
        
        if (currentProject == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return PermissionHandlerWidget(
          requiredPermissions: [PermissionType.location, PermissionType.sensor],
          onPermissionsResult: _handlePermissionResults,
          showOverlay: true, // Use overlay instead of full screen
          child: _buildCompassContent(currentProject, projectState, hasUnsavedNewPoint),
        );
      },
    );
  }

  Widget _buildCompassContent(ProjectModel currentProject, ProjectStateManager projectState, bool hasUnsavedNewPoint) {
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
                const SizedBox(height: 16),
                if (_hasLocationPermission && _hasSensorPermission && _isCompassAvailable)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Compass'),
                    onPressed: _retryCompassSetup,
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
                    // Add retry button if heading is null but permissions are granted
                    if (_heading == null && _hasSensorPermission && _isCompassAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry Compass', style: TextStyle(fontSize: 12)),
                          onPressed: _retryCompassSetup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
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
                      onPressed: hasUnsavedNewPoint ? null : () => _handleAddPointPressed(context, projectState),
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
