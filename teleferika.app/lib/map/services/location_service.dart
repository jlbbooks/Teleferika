import 'dart:async';

import 'package:compassx/compassx.dart';
import 'package:geolocator/geolocator.dart';

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
    // Compass/motion sensors (magnetometer, accelerometer, gyroscope) do not require
    // runtime permissions on Android. They are always available to apps.
    // BODY_SENSORS permission is only for body sensors like heart rate monitors,
    // which is not what we need for compass functionality.
    return {
      'location':
          locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always,
      'sensor': true, // Sensors are always available, no permission needed
    };
  }

  // Check current permission status without requesting
  Future<Map<String, bool>> checkCurrentPermissions() async {
    // Location Permission
    LocationPermission locationPermission = await Geolocator.checkPermission();

    // Sensor (Compass) Permission
    // Compass/motion sensors (magnetometer, accelerometer, gyroscope) do not require
    // runtime permissions on Android. They are always available to apps.
    return {
      'location':
          locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always,
      'sensor': true, // Sensors are always available, no permission needed
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
