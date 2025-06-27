// compass_tool_view.dart
import 'dart:async';
import 'dart:math' as math; // For PI

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

// Define a typedef for the callback function for clarity
typedef AddPointFromCompassCallback =
    void Function(
      BuildContext descendantContext,
      double heading, {
      bool? setAsEndPoint, // Can be null if not specified, or true/false
    });

class CompassToolView extends StatefulWidget {
  final ProjectModel project;
  final AddPointFromCompassCallback? onAddPointFromCompass;
  // You can add callbacks, e.g., for when "Add Point" is pressed
  // final Function(double heading, LatLng location)? onAddPoint;
  final bool isAddingPoint;

  const CompassToolView({
    super.key,
    required this.project,
    this.onAddPointFromCompass,
    this.isAddingPoint = false,
  });

  @override
  State<CompassToolView> createState() => _CompassToolViewState();
}

class _CompassToolViewState extends State<CompassToolView> {
  double? _heading; // Current heading from the compass
  double? _accuracy; // Compass accuracy
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasPermissions = false;
  bool _isCompassAvailable = false;
  String? _errorMessage;

  // State variable for the checkbox - persists during project session
  static bool _setAsEndPoint = true;

  @override
  void initState() {
    super.initState();
    logger.info(
      "CompassToolView initialized for project: ${widget.project.name}",
    );
    _checkPermissionsAndListen();
  }

  Future<void> _checkPermissionsAndListen() async {
    try {
      // Check if compass is available first
      final isCompassAvailable = await FlutterCompass.events?.first != null;

      if (!isCompassAvailable) {
        setState(() {
          _isCompassAvailable = false;
          _errorMessage = 'Compass sensor not available on this device.';
        });
        return;
      }

      // Request permissions
      final motionStatus = await Permission.sensors.request();
      final locationStatus = await Permission.locationWhenInUse.request();

      if (motionStatus.isGranted && locationStatus.isGranted) {
        setState(() {
          _hasPermissions = true;
          _isCompassAvailable = true;
          _errorMessage = null;
        });
        _listenToCompass();
      } else {
        logger.warning(
          "Compass permissions not granted. Motion: $motionStatus, Location: $locationStatus",
        );
        setState(() {
          _hasPermissions = false;
          _errorMessage =
              'Sensor and location permissions are required for compass functionality.';
        });
      }
    } catch (e) {
      logger.severe("Error checking compass availability", e);
      setState(() {
        _errorMessage = 'Error initializing compass: $e';
      });
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
            setState(() {
              _errorMessage = 'Compass error: $error';
            });
          }
        },
      );
    } catch (e) {
      logger.severe("Error setting up compass listener", e);
      setState(() {
        _errorMessage = 'Error setting up compass: $e';
      });
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _handleAddPointPressed() {
    if (_heading != null) {
      logger.info(
        "Add Point button tapped. Current Heading: ${_heading!.toStringAsFixed(1)}°, Set as End Point: $_setAsEndPoint. Delegating to parent.",
      );
      // Invoke the callback passed from the parent widget
      widget.onAddPointFromCompass?.call(
        context,
        _heading!,
        setAsEndPoint: _setAsEndPoint,
      );
    } else {
      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.compassHeadingNotAvailable ??
                'Cannot add point: Compass heading not available.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildProjectAzimuthText() {
    final s = S.of(context);
    String azimuthText;
    Color textColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.black;
    bool hasCalculatedAzimuth = widget.project.azimuth != null;

    if (hasCalculatedAzimuth) {
      azimuthText =
          s?.projectAzimuthLabel(widget.project.azimuth!.toStringAsFixed(1)) ??
          'Project Azimuth: ${widget.project.azimuth!.toStringAsFixed(1)}°';
    } else {
      if (widget.project.startingPointId == null ||
          widget.project.endingPointId == null) {
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

  Widget _buildErrorScreen() {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              s?.compassPermissionsRequired ?? "Permissions Required",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  (s?.compassPermissionsMessage ??
                      "This tool requires sensor and location permissions to function correctly. Please grant them in your device settings."),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
              },
              child: Text(s?.openSettingsButton ?? "Open Settings"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _checkPermissionsAndListen,
              child: Text(s?.retryButton ?? "Retry"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions || !_isCompassAvailable || _errorMessage != null) {
      return _buildErrorScreen();
    }

    final s = S.of(context);

    // Determine the rotation for the project azimuth arrow
    double projectAzimuthArrowRotationDegrees = 0;
    if (widget.project.azimuth != null && _heading != null) {
      projectAzimuthArrowRotationDegrees = widget.project.azimuth! - _heading!;
    } else if (widget.project.azimuth != null && _heading == null) {
      projectAzimuthArrowRotationDegrees = widget.project.azimuth!;
    }

    return Container(
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
                      if (widget.project.azimuth != null)
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
            if (widget.isAddingPoint)
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
                  onPressed: _handleAddPointPressed,
                ),
              ),
            _buildProjectAzimuthText(),
          ],
        ),
      ),
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
