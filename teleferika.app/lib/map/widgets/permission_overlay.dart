import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class PermissionOverlay {
  static Widget build({
    required BuildContext context,
    required bool hasLocationPermission,
    required bool hasSensorPermission,
    bool isCheckingPermissions = false,
    required VoidCallback onRetryPermissions,
  }) {
    // Don't show overlay while checking permissions or if all permissions are granted
    if (isCheckingPermissions ||
        (hasLocationPermission && hasSensorPermission)) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    return Positioned.fill(
      child: Container(
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
                    // Header icon
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

                    // Title
                    Text(
                      s?.mapPermissionsRequiredTitle ?? 'Permissions Required',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Permission details
                    if (!hasLocationPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.location_on_outlined,
                        title:
                            S.of(context)?.locationPermissionTitle ??
                            'Location Permission',
                        description:
                            s?.mapLocationPermissionInfoText ??
                            'Location permission is needed to show your current position and for some map features.',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!hasSensorPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.compass_calibration_outlined,
                        title:
                            S.of(context)?.sensorPermissionTitle ??
                            'Sensor Permission',
                        description:
                            s?.mapSensorPermissionInfoText ??
                            'Sensor (compass) permission is needed for direction-based features.',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.settings),
                            label: Text(
                              s?.mapButtonOpenAppSettings ??
                                  'Open App Settings',
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
                          onPressed: onRetryPermissions,
                          child: Text(
                            s?.mapButtonRetryPermissions ?? 'Retry Permissions',
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
      ),
    );
  }

  // Reusable permission overlay for full-screen use (like compass view)
  static Widget buildFullScreen({
    required BuildContext context,
    required bool hasLocationPermission,
    required bool hasSensorPermission,
    bool isCheckingPermissions = false,
    required VoidCallback onRetryPermissions,
  }) {
    // Don't show overlay while checking permissions or if all permissions are granted
    if (isCheckingPermissions ||
        (hasLocationPermission && hasSensorPermission)) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
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
                  // Header icon
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

                  // Title
                  Text(
                    s?.mapPermissionsRequiredTitle ?? 'Permissions Required',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Permission details
                  if (!hasLocationPermission) ...[
                    _buildPermissionItem(
                      icon: Icons.location_on_outlined,
                      title:
                          S.of(context)?.locationPermissionTitle ??
                          'Location Permission',
                      description:
                          s?.mapLocationPermissionInfoText ??
                          'Location permission is needed to show your current position and for some map features.',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!hasSensorPermission) ...[
                    _buildPermissionItem(
                      icon: Icons.compass_calibration_outlined,
                      title:
                          S.of(context)?.sensorPermissionTitle ??
                          'Sensor Permission',
                      description:
                          s?.mapSensorPermissionInfoText ??
                          'Sensor (compass) permission is needed for direction-based features.',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.settings),
                          label: Text(
                            s?.mapButtonOpenAppSettings ?? 'Open App Settings',
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
                        onPressed: onRetryPermissions,
                        child: Text(
                          s?.mapButtonRetryPermissions ?? 'Retry Permissions',
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

  static Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
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
