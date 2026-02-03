import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teleferika/core/fix_quality_colors.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class FloatingActionButtons {
  static Widget build({
    required BuildContext context,
    required bool hasLocationPermission,
    required Position? currentPosition,
    required VoidCallback onCenterOnLocation,
    required VoidCallback onAddPoint,
    required VoidCallback onCenterOnPoints,
    bool isAddingNewPoint = false,
    bool isBleConnected = false,
    VoidCallback? onBleInfoPressed,
    int bleFixQuality = 0,
  }) {
    final bool isLocationLoading =
        hasLocationPermission && currentPosition == null;
    final s = S.of(context);

    // Determine BLE button color based on fix quality
    final bleButtonColor = FixQualityColors.getColor(bleFixQuality);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GPS Info button (shown when setting is enabled)
          if (onBleInfoPressed != null)
            _buildFloatingActionButton(
              heroTag: 'gps_info',
              icon: Icons.satellite,
              tooltip: 'GPS Information',
              onPressed: onBleInfoPressed,
              color: isBleConnected && bleFixQuality > 0
                  ? bleButtonColor
                  : Colors.blue,
            ),

          // Add new point button
          _buildFloatingActionButton(
            heroTag: 'add_new_point',
            icon: Icons.add_location_alt_outlined,
            tooltip: isLocationLoading || isAddingNewPoint
                ? (s?.mapAcquiringLocation ?? 'Acquiring location...')
                : (s?.mapAddNewPoint ?? 'Add New Point'),
            onPressed: (isLocationLoading || isAddingNewPoint)
                ? null
                : onAddPoint,
            isLoading: isLocationLoading || isAddingNewPoint,
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
}
