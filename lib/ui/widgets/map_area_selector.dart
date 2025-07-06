import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';
import 'package:teleferika/ui/tabs/map/services/map_cache_error_handler.dart';
import 'package:teleferika/ui/tabs/map/widgets/map_type_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class MapAreaSelector extends StatefulWidget {
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

  // Fixed rectangle margins (40px from each edge)
  static const double _margin = 40.0;

  // Default center and zoom
  static const LatLng _defaultCenter = LatLng(45.4642, 9.1900); // Milan
  static const double _defaultZoom = 10.0;

  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Don't call _updateSelectedArea here - wait for map to be ready
  }

  void _updateSelectedArea() {
    if (!mounted) return;

    // Check if map controller is ready
    try {
      final mapBounds = _mapController.camera.visibleBounds;
      if (mapBounds != null) {
        // The selected area is the portion of the map visible within the fixed rectangle
        // We need to calculate this based on the current map view and the fixed rectangle position
        final selectedBounds = _calculateSelectedBounds(mapBounds);
        widget.onAreaSelected?.call(selectedBounds);
      }
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
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

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

  void _clearSelection() {
    widget.onClearSelection?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
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
              onMapReady: () {
                // Map is ready, now we can update the selected area
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
                tileProvider: FMTCTileProvider(
                  stores: {
                    widget.mapType.cacheStoreName:
                        BrowseStoreStrategy.readUpdateCreate,
                  },
                  errorHandler:
                      MapCacheErrorHandler.getTileProviderWithFallback(
                        widget.mapType,
                      ).errorHandler,
                ),
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
              child: const Text(
                'Drag the map to position the download area',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Zoom controls and location button
          Positioned(
            right: 10,
            top: 10,
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
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
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
    );
  }
}
