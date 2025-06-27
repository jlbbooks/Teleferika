import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/tabs/map/map_controller.dart';

class MapControls {
  static Widget buildFloatingActionButtons({
    required BuildContext context,
    required bool hasLocationPermission,
    required Position? currentPosition,
    required VoidCallback onCenterOnLocation,
    required VoidCallback onAddPoint,
    required VoidCallback onCenterOnPoints,
  }) {
    final bool isLocationLoading = hasLocationPermission && currentPosition == null;
    final s = S.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Center on current location button
          _buildFloatingActionButton(
            heroTag: 'center_on_location',
            icon: Icons.my_location,
            tooltip: isLocationLoading
                ? (s?.mapAcquiringLocation ?? 'Acquiring location...')
                : (s?.mapCenterOnLocation ?? 'Center on my location'),
            onPressed: isLocationLoading ? null : onCenterOnLocation,
            isLoading: isLocationLoading,
            color: Colors.blue,
          ),

          // Add new point button
          _buildFloatingActionButton(
            heroTag: 'add_new_point',
            icon: Icons.add_location_alt_outlined,
            tooltip: isLocationLoading
                ? (s?.mapAcquiringLocation ?? 'Acquiring location...')
                : (s?.mapAddNewPoint ?? 'Add New Point'),
            onPressed: isLocationLoading ? null : onAddPoint,
            isLoading: isLocationLoading,
            color: Colors.green,
          ),

          // Center on Project points button
          _buildFloatingActionButton(
            heroTag: 'center_on_points',
            icon: Icons.center_focus_strong,
            tooltip: s?.mapCenterOnPoints ?? 'Center on points',
            onPressed: onCenterOnPoints,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  static Widget _buildFloatingActionButton({
    required String heroTag,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: color ?? Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        mini: true,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 20),
      ),
    );
  }

  static Widget buildMapTypeSelector({
    required MapType currentMapType,
    required Function(MapType) onMapTypeChanged,
    required BuildContext context,
  }) {
    final s = S.of(context);
    return Positioned(
      top: 16,
      left: 16,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        shadowColor: Colors.black12,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: PopupMenuButton<MapType>(
            onSelected: onMapTypeChanged,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _getMapTypeIcon(currentMapType),
                      size: 14,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getMapTypeDisplayName(currentMapType, s),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) => [
              _buildMapTypeMenuItem(
                MapType.openStreetMap,
                s?.mapTypeStreet ?? 'Street',
                Icons.map,
                currentMapType,
                context,
              ),
              _buildMapTypeMenuItem(
                MapType.satellite,
                s?.mapTypeSatellite ?? 'Satellite',
                Icons.satellite_alt,
                currentMapType,
                context,
              ),
              _buildMapTypeMenuItem(
                MapType.terrain,
                s?.mapTypeTerrain ?? 'Terrain',
                Icons.terrain,
                currentMapType,
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static PopupMenuItem<MapType> _buildMapTypeMenuItem(
    MapType mapType,
    String label,
    IconData icon,
    MapType currentMapType,
    BuildContext context,
  ) {
    final isSelected = currentMapType == mapType;
    return PopupMenuItem<MapType>(
      value: mapType,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  static IconData _getMapTypeIcon(MapType mapType) {
    switch (mapType) {
      case MapType.openStreetMap:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
    }
  }

  static String _getMapTypeDisplayName(MapType mapType, S? s) {
    switch (mapType) {
      case MapType.openStreetMap:
        return s?.mapTypeStreet ?? 'Street';
      case MapType.satellite:
        return s?.mapTypeSatellite ?? 'Satellite';
      case MapType.terrain:
        return s?.mapTypeTerrain ?? 'Terrain';
    }
  }

  static Widget buildPermissionOverlay({
    required BuildContext context,
    required bool hasLocationPermission,
    required bool hasSensorPermission,
    required VoidCallback onRetryPermissions,
  }) {
    if (hasLocationPermission && hasSensorPermission) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    return Positioned.fill(
      child: Container(
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
                      s?.mapPermissionsRequiredTitle ?? "Permissions Required",
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
                        title: 'Location Permission',
                        description: s?.mapLocationPermissionInfoText ??
                            "Location permission is needed to show your current position and for some map features.",
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!hasSensorPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.compass_calibration_outlined,
                        title: 'Sensor Permission',
                        description: s?.mapSensorPermissionInfoText ??
                            "Sensor (compass) permission is needed for direction-based features.",
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
                          onPressed: onRetryPermissions,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 