import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';
import 'package:teleferika/ui/tabs/map/services/map_cache_manager.dart';
import 'package:teleferika/ui/tabs/map/services/map_preferences_service.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';
import 'package:teleferika/ui/widgets/project_points_layer.dart';

class MapAreaSelector extends StatefulWidget {
  // TODO: move to licensed_features_package
  final MapType mapType;
  final Function(LatLngBounds bounds)? onAreaSelected;
  final Function()? onClearSelection;

  const MapAreaSelector({
    super.key,
    required this.mapType,
    this.onAreaSelected,
    this.onClearSelection,
  });

  @override
  State<MapAreaSelector> createState() => _MapAreaSelectorState();
}

class _MapAreaSelectorState extends State<MapAreaSelector> {
  final MapController _mapController = MapController();
  final Logger _logger = Logger('MapAreaSelector');

  LatLng _defaultCenter =
      AppConfig.defaultMapCenter; // Use config instead of hardcoded Milan
  double _defaultZoom = AppConfig.defaultMapZoom;

  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
  }

  void _updateSelectedArea() {
    if (!mounted) return;

    // Check if map controller is ready
    try {
      final mapBounds = _mapController.camera.visibleBounds;
      // The selected area is the portion of the map visible within the fixed rectangle
      // We need to calculate this based on the current map view and the fixed rectangle position
      final selectedBounds = _calculateSelectedBounds(mapBounds);
      widget.onAreaSelected?.call(selectedBounds);
    } catch (e) {
      // Map controller not ready yet, ignore
      _logger.fine('Map controller not ready yet: $e');
    }
  }

  LatLngBounds _calculateSelectedBounds(LatLngBounds mapBounds) {
    // For now, return the full map bounds
    // TODO: Calculate the actual bounds of the area visible within the fixed rectangle
    return mapBounds;
  }

  Future<void> _getCurrentLocation() async {
    if (!_hasLocationPermission) {
      _logger.warning('Location permission not granted');
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(position.latitude, position.longitude);

      // Move map to current location with closer zoom
      _mapController.move(currentLocation, 14.0);

      // Update selected area after moving
      _updateSelectedArea();
    } catch (e) {
      _logger.warning('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onPermissionsResult(Map<PermissionType, bool> permissions) {
    setState(() {
      _hasLocationPermission = permissions[PermissionType.location] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PermissionHandlerWidget(
      requiredPermissions: [PermissionType.location],
      onPermissionsResult: _onPermissionsResult,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Map widget
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: _defaultZoom,
                onMapReady: () async {
                  try {
                    final lastLocation =
                        await MapPreferencesService.loadLastLocation();
                    if (lastLocation != null) {
                      _logger.info('Using last known location: $lastLocation');
                      _mapController.move(lastLocation, _defaultZoom);
                    } else {
                      _logger.info(
                        'No last known location found, using default: ${AppConfig.defaultMapCenter}',
                      );
                      _mapController.move(_defaultCenter, _defaultZoom);
                    }
                  } catch (e) {
                    _logger.warning('Error loading last known location: $e');
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateSelectedArea();
                  });
                },
                onMapEvent: (MapEvent event) {
                  // Update selected area when map moves
                  if (event is MapEventMove) {
                    _updateSelectedArea();
                  }
                },
              ),
              children: [
                // Tile layer with caching
                TileLayer(
                  urlTemplate: widget.mapType.tileLayerUrl,
                  userAgentPackageName: 'com.jlbbooks.teleferika',
                  tileProvider: _getTileProvider(),
                ),
                // Project points and lines layer
                ProjectPointsLayer(
                  // No projects parameter - will load from database
                  // No excludeProjectId - will show all projects
                ),
              ],
            ),

            // Instructions text
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  S.of(context)?.map_area_selector_instruction ??
                      'Drag the map to position the download area',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Zoom controls and location button
            Positioned(
              right: 10,
              bottom: 10,
              child: Column(
                children: [
                  // Zoom in button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Zoom out button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                              size: 20,
                              color: Colors.white,
                            ),
                      onPressed: _isLoadingLocation
                          ? null
                          : _getCurrentLocation,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TileProvider _getTileProvider() {
    try {
      // Try to use cached tile provider first
      return MapCacheManager.getTileProviderWithFallback(widget.mapType);
    } catch (e) {
      _logger.warning(
        'Failed to create cached tile provider, using cancellable provider: $e',
      );
      // Fallback to cancellable network tile provider
      return MapCacheManager.getCancellableTileProvider();
    }
  }
}
