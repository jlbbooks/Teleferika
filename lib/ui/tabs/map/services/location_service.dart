import 'dart:async';

import 'package:compassx/compassx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Stream subscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassXEvent>? _compassSubscription;

  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();
  }

  // Permission handling
  Future<Map<String, bool>> checkAndRequestPermissions() async {
    // Location Permission
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    // Sensor (Compass) Permission
    PermissionStatus sensorStatus = await Permission.sensors.status;
    if (sensorStatus.isDenied) {
      sensorStatus = await Permission.sensors.request();
    }

    return {
      'location':
          locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always,
      'sensor': sensorStatus.isGranted,
    };
  }

  // Check current permission status without requesting
  Future<Map<String, bool>> checkCurrentPermissions() async {
    // Location Permission
    LocationPermission locationPermission = await Geolocator.checkPermission();

    // Sensor (Compass) Permission
    PermissionStatus sensorStatus = await Permission.sensors.status;

    return {
      'location':
          locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always,
      'sensor': sensorStatus.isGranted,
    };
  }

  // Location listening
  void startListeningToLocation(
    Function(Position) onPositionUpdate,
    Function(Object, [StackTrace?]) onError,
  ) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(onPositionUpdate, onError: onError);
  }

  // Compass listening
  void startListeningToCompass(
    Function(double heading, double? accuracy, bool? shouldCalibrate)
    onCompassUpdate,
    Function(Object, [StackTrace?]) onError,
  ) {
    _compassSubscription = CompassX.events.listen((event) {
      onCompassUpdate(event.heading, event.accuracy, event.shouldCalibrate);
    }, onError: onError);
  }
}
