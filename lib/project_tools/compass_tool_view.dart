// compass_tool_view.dart
import 'dart:async';
import 'dart:math' as math; // For PI

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/logger.dart';

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
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasPermissions = false;

  // State variable for the checkbox
  bool _setAsEndPoint = false;

  @override
  void initState() {
    super.initState();
    logger.info(
      "CompassToolView initialized for project: ${widget.project.name}",
    );
    _checkPermissionsAndListen();
  }

  void _checkPermissionsAndListen() async {
    // For compass, primarily motion sensors are needed. Location can improve accuracy.
    // Let's check for location permission as it's often linked and good for future point adding.
    final motionStatus = await Permission.sensors
        .request(); // Or Permission.motion for iOS
    final locationStatus = await Permission.locationWhenInUse.request();

    if (motionStatus.isGranted && locationStatus.isGranted) {
      setState(() {
        _hasPermissions = true;
      });
      _listenToCompass();
    } else {
      logger.warning(
        "Compass permissions not granted. Motion: $motionStatus, Location: $locationStatus",
      );
      setState(() {
        _hasPermissions = false;
      });
      // TODO: Optionally, show a message to the user or guide them to settings.
    }
  }

  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        // Ensure the widget is still in the tree
        setState(() {
          _heading = event.heading; // heading: 0-360, null if not available
        });
      }
    });
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
      ); // Pass the checkbox value

      // Show immediate feedback in CompassToolView
      // Do NOT show ScaffoldMessenger here if ProjectDetailsPage will show one.
      // Or, make it clear this is just a local "signal sent" confirmation.
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       'Sending heading: ${_heading!.toStringAsFixed(1)}° to add point...',
      //     ),
      //     backgroundColor: Colors.blueAccent,
      //   ),
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add point: Compass heading not available.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildProjectAzimuthText() {
    String azimuthText;
    Color textColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.black;
    bool hasCalculatedAzimuth = widget.project.azimuth != null;

    if (hasCalculatedAzimuth) {
      azimuthText =
          'Project Azimuth: ${widget.project.azimuth!.toStringAsFixed(1)}°';
    } else {
      // Inferring message based on null azimuth.
      // The actual check for 2 points for calculation happens elsewhere (e.g. ProjectDetailsPage)
      if (widget.project.startingPointId == null ||
          widget.project.endingPointId == null) {
        azimuthText = 'Project Azimuth: (Requires at least 2 points)';
        textColor = Colors.orange.shade700;
      } else {
        // This case might mean calculation hasn't been explicitly triggered yet
        // or resulted in null for other reasons.
        azimuthText = 'Project Azimuth: Not yet calculated';
        textColor = Colors.grey.shade600;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
      ), // Add some spacing from the coordinates
      child: Text(
        azimuthText,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              const Text(
                "Permissions Required",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "This tool requires sensor and location permissions to function correctly. Please grant them in your device settings.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  openAppSettings(); // From permission_handler, opens app settings
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        ),
      );
    }

    // Determine the rotation for the project azimuth arrow
    double projectAzimuthArrowRotationDegrees = 0;
    if (widget.project.azimuth != null && _heading != null) {
      // The arrow should point to project.azimuth relative to true North.
      // The compass image is rotated by -_heading to keep its "North" marking pointing to true North.
      // So, the arrow, overlaid on this compass, needs to be rotated such that
      // its final orientation aligns with project.azimuth.
      // If the arrow image itself points "up" (0 degrees),
      // we rotate it by (project.azimuth - _heading).
      projectAzimuthArrowRotationDegrees = widget.project.azimuth! - _heading!;
    } else if (widget.project.azimuth != null && _heading == null) {
      // If heading is not yet available, but we have a project azimuth,
      // just point the arrow to project.azimuth relative to the phone's top for now.
      // This might not be perfectly aligned with the (not yet rotated) compass rose
      // but gives an initial direction.
      projectAzimuthArrowRotationDegrees = widget.project.azimuth!;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        // Added SingleChildScrollView for smaller screens
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // --- Heading Display ---
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
            const SizedBox(height: 20),

            // --- Compass Rose and Project Azimuth Arrow ---
            SizedBox(
              width: 250, // Adjust size as needed
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Compass Rose (Rotates to keep North up)
                  Transform.rotate(
                    // The compass image itself might be oriented with North (0 degrees) at the top.
                    // The phone's heading tells you where North is relative to the phone's top.
                    // So, to make the compass image point North correctly, you rotate it by -_heading.
                    angle: (_heading != null)
                        ? (-(_heading!) * (math.pi / 180))
                        : 0,
                    child: Image.asset('assets/images/compass_rose.png'),
                  ),
                  // 2. Project Azimuth Arrow (Conditionally displayed and rotated)
                  if (widget.project.azimuth != null)
                    Transform.rotate(
                      // The arrow's angle is relative to the phone's top.
                      // If compass rose image North is at its top, and project azimuth is X,
                      // and phone's top is currently facing Y (_heading),
                      // then the arrow on screen should be rotated by (X - Y)
                      angle:
                          (projectAzimuthArrowRotationDegrees *
                          (math.pi / 180)),
                      child: Image.asset(
                        'assets/images/direction_arrow.png',
                        width:
                            180, // Adjust size to be smaller than compass rose
                        height: 180,
                        color: Colors.blueGrey.withAlpha(
                          (0.7 * 255).round(),
                        ), // Optional: color the arrow
                      ),
                    ),
                ],
              ),
            ),
            // Alternative: CustomPaint for a drawn compass (more complex but flexible)
            // child: CustomPaint(
            //   size: const Size(200, 200),
            //   painter: CompassPainter(heading: _heading ?? 0),
            // ),
            const SizedBox(height: 20),
            // --- "Add as END point" Checkbox ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CheckboxListTile(
                title: const Text("Add as END point"),
                value: _setAsEndPoint,
                onChanged: (bool? value) {
                  if (mounted) {
                    setState(() {
                      _setAsEndPoint = value ?? false;
                    });
                  }
                },
                controlAffinity:
                    ListTileControlAffinity.leading, // Checkbox on the left
                dense: true,
              ),
            ),
            // --- End Checkbox ---
            const SizedBox(height: 10),

            // --- Add Point Button ---
            if (widget.isAddingPoint) // Use the passed-in loading state
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add Point with Current Heading'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: _handleAddPointPressed,
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
