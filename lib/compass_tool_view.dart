// compass_tool_view.dart
import 'dart:async';
import 'dart:math' as math; // For PI

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/logger.dart';

class CompassToolView extends StatefulWidget {
  final ProjectModel project;
  // You can add callbacks, e.g., for when "Add Point" is pressed
  // final Function(double heading, LatLng location)? onAddPoint;

  const CompassToolView({
    super.key,
    required this.project,
    // this.onAddPoint,
  });

  @override
  State<CompassToolView> createState() => _CompassToolViewState();
}

class _CompassToolViewState extends State<CompassToolView> {
  double? _heading; // Current heading from the compass
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasPermissions = false;
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
      // Optionally, show a message to the user or guide them to settings.
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

  void _handleAddPoint() {
    if (_heading != null) {
      logger.info(
        "Add Point button tapped. Current Heading: ${_heading!.toStringAsFixed(1)}°",
      );
      // Here you would typically get the current location (e.g., using geolocator plugin)
      // and then call a method to save this point, potentially using a callback:
      // widget.onAddPoint?.call(_heading!, currentLocation);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Point added (simulated) at heading: ${_heading!.toStringAsFixed(1)}°',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add point: Compass heading not available.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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

          // --- Compass Rose ---
          SizedBox(
            width: 250, // Adjust size as needed
            height: 250,
            child: Transform.rotate(
              // The compass image itself might be oriented with North (0 degrees) at the top.
              // The phone's heading tells you where North is relative to the phone's top.
              // So, to make the compass image point North correctly, you rotate it by -_heading.
              angle: (_heading != null) ? (-(_heading!) * (math.pi / 180)) : 0,
              child: Image.asset(
                'assets/images/compass-rose.png',
              ), // Ensure you have this image
            ),
          ),

          // Alternative: CustomPaint for a drawn compass (more complex but flexible)
          // child: CustomPaint(
          //   size: const Size(200, 200),
          //   painter: CompassPainter(heading: _heading ?? 0),
          // ),
          const SizedBox(height: 30),

          // --- Add Point Button ---
          ElevatedButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add Point'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: _handleAddPoint,
          ),
          const SizedBox(height: 10),
          Text(
            'Project: ${widget.project.name}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
