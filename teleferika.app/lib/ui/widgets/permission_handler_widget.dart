// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/l10n/app_localizations.dart';

/// Permission types that can be requested by the widget.
///
/// Each type corresponds to a specific system permission that the app
/// may need to function properly.
enum PermissionType {
  /// Location permission for GPS and location services.
  location,

  /// Sensor permission for device sensors (accelerometer, gyroscope, etc.).
  sensor,

  /// Camera permission for taking photos and video.
  camera,

  /// Microphone permission for audio recording.
  microphone,

  /// Storage permission for file system access.
  storage,

  /// Bluetooth permission for BLE scanning and connection.
  bluetooth,
}

/// Permission handling widget for managing app permissions.
///
/// This widget provides a comprehensive solution for requesting and managing
/// app permissions. It handles permission requests, provides user feedback,
/// and can show overlays when permissions are missing.
///
/// ## Features
/// - **Multiple Permission Types**: Location, sensors, camera, microphone, storage
/// - **Automatic Permission Requests**: Handles permission flow automatically
/// - **User-Friendly Overlays**: Shows permission request dialogs when needed
/// - **Retry Mechanism**: Allows users to retry permission requests
/// - **Loading States**: Shows loading indicators during permission checks
/// - **Customizable UI**: Configurable loading and overlay widgets
/// - **Permission Status Tracking**: Tracks the status of all requested permissions
///
/// ## Usage Examples
///
/// ### Basic Permission Handling:
/// ```dart
/// PermissionHandlerWidget(
///   requiredPermissions: [PermissionType.location, PermissionType.camera],
///   onPermissionsResult: (permissions) {
///     print('Location: ${permissions[PermissionType.location]}');
///     print('Camera: ${permissions[PermissionType.camera]}');
///   },
///   child: MyAppContent(),
/// )
/// ```
///
/// ### With Custom Loading Widget:
/// ```dart
/// PermissionHandlerWidget(
///   requiredPermissions: [PermissionType.location],
///   loadingWidget: Center(
///     child: Column(
///       mainAxisAlignment: MainAxisAlignment.center,
///       children: [
///         CircularProgressIndicator(),
///         Text('Checking permissions...'),
///       ],
///     ),
///   ),
///   onPermissionsResult: handlePermissions,
///   child: MyAppContent(),
/// )
/// ```
///
/// ### Without Overlay (Custom UI):
/// ```dart
/// PermissionHandlerWidget(
///   requiredPermissions: [PermissionType.camera],
///   showOverlay: false,
///   onPermissionsResult: (permissions) {
///     if (!permissions[PermissionType.camera]!) {
///       showCustomPermissionDialog();
///     }
///   },
///   child: MyAppContent(),
/// )
/// ```
///
/// ## Permission Types
/// - **Location**: GPS and location services (using Geolocator)
/// - **Sensor**: Device sensors like accelerometer and gyroscope
/// - **Camera**: Photo and video capture capabilities
/// - **Microphone**: Audio recording functionality
/// - **Storage**: File system read/write access
///
/// ## Permission Flow
/// 1. **Check Current Status**: Verify if permissions are already granted
/// 2. **Request Permissions**: Show system permission dialogs if needed
/// 3. **Handle Results**: Process granted/denied permissions
/// 4. **Show Overlay**: Display custom UI for missing permissions
/// 5. **Retry Option**: Allow users to retry permission requests
///
/// ## UI States
/// - **Loading**: Shows loading widget during permission checks
/// - **All Granted**: Shows the child widget normally
/// - **Missing Permissions**: Shows overlay with permission request UI
/// - **Retry Mode**: Shows retry button for failed permissions
///
/// ## Integration
/// Designed to work with:
/// - Geolocator for location permissions
/// - Permission_handler for other permissions
/// - Flutter's permission system
/// - Custom permission request flows
///
/// ## Best Practices
/// - Request only necessary permissions
/// - Provide clear explanations for permission needs
/// - Handle permission denials gracefully
/// - Offer alternative functionality when possible
/// - Respect user privacy preferences

/// A widget that handles app permission requests and management.
///
/// This widget automatically requests the specified permissions and provides
/// appropriate UI feedback. It can show overlays when permissions are missing
/// and allows users to retry permission requests.
class PermissionHandlerWidget extends StatefulWidget {
  /// List of permissions that the app requires to function properly.
  ///
  /// The widget will request each permission in this list and track their status.
  /// Only request permissions that are actually needed by your app.
  final List<PermissionType> requiredPermissions;

  /// The widget to display when all permissions are granted.
  ///
  /// This is the main content of your app that will be shown once
  /// all required permissions have been granted.
  final Widget child;

  /// Optional custom loading widget to show during permission checks.
  ///
  /// If not provided, a default [CircularProgressIndicator] will be shown.
  /// Useful for providing branded loading experiences.
  final Widget? loadingWidget;

  /// Callback function called with the results of permission requests.
  ///
  /// This callback receives a map of permission types to their granted status.
  /// Called after all permission requests are complete.
  final Function(Map<PermissionType, bool>) onPermissionsResult;

  /// Whether to show the permission overlay when permissions are missing.
  ///
  /// If true, shows a custom overlay with permission request UI.
  /// If false, you must handle missing permissions in your own UI.
  final bool showOverlay;

  /// Creates a permission handler widget.
  ///
  /// The [requiredPermissions], [child], and [onPermissionsResult] parameters
  /// are required. The [loadingWidget] and [showOverlay] parameters are optional.
  const PermissionHandlerWidget({
    super.key,
    required this.requiredPermissions,
    required this.child,
    required this.onPermissionsResult,
    this.loadingWidget,
    this.showOverlay = true,
  });

  @override
  State<PermissionHandlerWidget> createState() =>
      _PermissionHandlerWidgetState();
}

/// State class for the PermissionHandlerWidget.
///
/// Manages the permission request flow, tracks permission status, and handles
/// the UI states for loading, success, and permission request overlays.
class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  /// Current status of all requested permissions.
  ///
  /// Maps each permission type to whether it has been granted.
  /// Updated after permission requests are completed.
  Map<PermissionType, bool> _permissionStatus = {};

  /// Flag indicating if permissions are currently being checked.
  ///
  /// Used to show loading state and prevent concurrent permission requests.
  bool _isCheckingPermissions = true;

  /// Flag indicating if a permission dialog has been shown.
  ///
  /// Used to track whether the user has seen permission request dialogs
  /// and to provide appropriate retry options.
  final bool _hasShownDialog = false;

  /// Flag indicating if the user is retrying permission requests.
  ///
  /// Used to show retry UI and handle retry logic for denied permissions.
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final permissions = await _requestPermissions();

      if (mounted) {
        setState(() {
          _permissionStatus = permissions;
          _isCheckingPermissions = false;
          _isRetrying = false;
        });

        widget.onPermissionsResult(permissions);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
          _isRetrying = false;
        });
      }
    }
  }

  Future<Map<PermissionType, bool>> _requestPermissions() async {
    final Map<PermissionType, bool> results = {};

    for (final permissionType in widget.requiredPermissions) {
      bool granted = false;

      switch (permissionType) {
        case PermissionType.location:
          granted = await _requestLocationPermission();
          break;
        case PermissionType.sensor:
          granted = await _requestSensorPermission();
          break;
        case PermissionType.camera:
          granted = await _requestCameraPermission();
          break;
        case PermissionType.microphone:
          granted = await _requestMicrophonePermission();
          break;
        case PermissionType.storage:
          granted = await _requestStoragePermission();
          break;
        case PermissionType.bluetooth:
          granted = await _requestBluetoothPermission();
          break;
      }

      results[permissionType] = granted;
    }

    return results;
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (_isRetrying || permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<bool> _requestSensorPermission() async {
    // Compass/motion sensors (magnetometer, accelerometer, gyroscope) do not require
    // runtime permissions on Android. They are always available to apps.
    // BODY_SENSORS permission is only for body sensors like heart rate monitors,
    // which is not what we need for compass functionality.
    return true;
  }

  Future<bool> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (_isRetrying || status.isDenied || status.isRestricted) {
      status = await Permission.camera.request();
    }

    return status.isGranted;
  }

  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;

    if (_isRetrying || status.isDenied || status.isRestricted) {
      status = await Permission.microphone.request();
    }

    return status.isGranted;
  }

  Future<bool> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;

    if (_isRetrying || status.isDenied || status.isRestricted) {
      status = await Permission.storage.request();
    }

    return status.isGranted;
  }

  Future<bool> _requestBluetoothPermission() async {
    // On Android 12+, we need BLUETOOTH_SCAN and BLUETOOTH_CONNECT
    // On older Android, we need location permission for BLE scanning
    // On iOS, Bluetooth permissions are handled automatically

    // Check location permission first (required for BLE scanning on Android)
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    final locationGranted =
        locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always;

    if (!locationGranted) {
      return false;
    }

    // Check Bluetooth permissions (Android 12+)
    try {
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

      if (_isRetrying ||
          bluetoothScanStatus.isDenied ||
          bluetoothConnectStatus.isDenied) {
        await Permission.bluetoothScan.request();
        await Permission.bluetoothConnect.request();

        // Check again after request
        final scanGranted = (await Permission.bluetoothScan.status).isGranted;
        final connectGranted =
            (await Permission.bluetoothConnect.status).isGranted;
        return scanGranted && connectGranted;
      }

      return bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted;
    } catch (e) {
      // If Bluetooth permissions don't exist (older Android), location is sufficient
      return locationGranted;
    }
  }

  bool get _allPermissionsGranted {
    return _permissionStatus.values.every((granted) => granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (_allPermissionsGranted) {
      return widget.child;
    }

    if (widget.showOverlay) {
      return Stack(children: [widget.child, _buildPermissionOverlay()]);
    }

    return _buildPermissionOverlay();
  }

  Widget _buildPermissionOverlay() {
    final s = S.of(context);
    final missingPermissions = _permissionStatus.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    s?.mapPermissionsRequiredTitle ?? "Permissions Required",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  ...missingPermissions
                      .map((permission) => _buildPermissionItem(permission, s))
                      .expand((widget) => [widget, const SizedBox(height: 12)]),

                  const SizedBox(height: 24),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.settings),
                          label: Text(
                            s?.mapButtonOpenAppSettings ?? "Open App Settings",
                          ),
                          onPressed: () async {
                            openAppSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isCheckingPermissions = true;
                            _isRetrying = true;
                          });
                          _checkPermissions();
                        },
                        child: Text(
                          s?.mapButtonRetryPermissions ?? "Retry Permissions",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(PermissionType permission, S? s) {
    IconData icon;
    String title;
    String description;
    Color color;

    switch (permission) {
      case PermissionType.location:
        icon = Icons.location_on_outlined;
        title = s?.locationPermissionTitle ?? 'Location Permission';
        description =
            s?.mapLocationPermissionInfoText ??
            "Location permission is needed to show your current position and for some map features.";
        color = Colors.blue;
        break;
      case PermissionType.sensor:
        icon = Icons.compass_calibration_outlined;
        title = s?.sensorPermissionTitle ?? 'Sensor Permission';
        description =
            s?.mapSensorPermissionInfoText ??
            "Sensor (compass) permission is needed for direction-based features.";
        color = Colors.green;
        break;
      case PermissionType.camera:
        icon = Icons.camera_alt_outlined;
        title = s?.camera_permission_title ?? 'Camera Permission';
        description =
            s?.camera_permission_description ??
            "Camera permission is needed to take photos.";
        color = Colors.purple;
        break;
      case PermissionType.microphone:
        icon = Icons.mic_outlined;
        title = s?.microphone_permission_title ?? 'Microphone Permission';
        description =
            s?.microphone_permission_description ??
            "Microphone permission is needed to record audio.";
        color = Colors.orange;
        break;
      case PermissionType.storage:
        icon = Icons.folder_outlined;
        title = s?.storage_permission_title ?? 'Storage Permission';
        description =
            s?.storage_permission_description ??
            "Storage permission is needed to save files.";
        color = Colors.teal;
        break;
      case PermissionType.bluetooth:
        icon = Icons.bluetooth_outlined;
        title = s?.bluetooth_permission_title ?? 'Bluetooth Permission';
        description =
            s?.bluetooth_permission_description ??
            "Bluetooth and location permissions are needed to scan and connect to BLE devices.";
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
