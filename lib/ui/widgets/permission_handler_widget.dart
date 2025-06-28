import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/l10n/app_localizations.dart';

enum PermissionType {
  location,
  sensor,
  camera,
  microphone,
  storage,
}

class PermissionHandlerWidget extends StatefulWidget {
  final List<PermissionType> requiredPermissions;
  final Widget child;
  final Widget? loadingWidget;
  final Function(Map<PermissionType, bool>) onPermissionsResult;
  final bool showOverlay;

  const PermissionHandlerWidget({
    super.key,
    required this.requiredPermissions,
    required this.child,
    required this.onPermissionsResult,
    this.loadingWidget,
    this.showOverlay = true,
  });

  @override
  State<PermissionHandlerWidget> createState() => _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  Map<PermissionType, bool> _permissionStatus = {};
  bool _isCheckingPermissions = true;
  bool _hasShownDialog = false;
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
    PermissionStatus status = await Permission.sensors.status;
    
    if (_isRetrying || status.isDenied || status.isRestricted) {
      status = await Permission.sensors.request();
    }
    
    return status.isGranted;
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

  bool get _allPermissionsGranted {
    return _permissionStatus.values.every((granted) => granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return widget.loadingWidget ?? 
        const Center(
          child: CircularProgressIndicator(),
        );
    }

    if (_allPermissionsGranted) {
      return widget.child;
    }

    if (widget.showOverlay) {
      return Stack(
        children: [
          widget.child,
          _buildPermissionOverlay(),
        ],
      );
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
      color: Colors.black.withOpacity(0.7),
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

                  ...missingPermissions.map((permission) => 
                    _buildPermissionItem(permission, s)
                  ).expand((widget) => [widget, const SizedBox(height: 12)]),

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
        title = 'Location Permission';
        description = s?.mapLocationPermissionInfoText ??
            "Location permission is needed to show your current position and for some map features.";
        color = Colors.blue;
        break;
      case PermissionType.sensor:
        icon = Icons.compass_calibration_outlined;
        title = 'Sensor Permission';
        description = s?.mapSensorPermissionInfoText ??
            "Sensor (compass) permission is needed for direction-based features.";
        color = Colors.green;
        break;
      case PermissionType.camera:
        icon = Icons.camera_alt_outlined;
        title = 'Camera Permission';
        description = "Camera permission is needed to take photos.";
        color = Colors.purple;
        break;
      case PermissionType.microphone:
        icon = Icons.mic_outlined;
        title = 'Microphone Permission';
        description = "Microphone permission is needed to record audio.";
        color = Colors.orange;
        break;
      case PermissionType.storage:
        icon = Icons.folder_outlined;
        title = 'Storage Permission';
        description = "Storage permission is needed to save files.";
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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