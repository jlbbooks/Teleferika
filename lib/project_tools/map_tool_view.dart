// map_tool_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

import '../logger.dart';

class MapToolView extends StatefulWidget {
  final ProjectModel project;

  const MapToolView({super.key, required this.project});

  @override
  State<MapToolView> createState() => _MapToolViewState();
}

class _MapToolViewState extends State<MapToolView> {
  List<PointModel> _projectPoints = [];
  bool _isLoadingPoints = true;
  final MapController _mapController = MapController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Default center if no points are available (e.g., Rome)
  final LatLng _defaultCenter = const LatLng(41.9028, 12.4964);
  final double _defaultZoom = 6.0;

  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadProjectPoints();
  }

  Future<void> _loadProjectPoints() async {
    setState(() {
      _isLoadingPoints = true;
    });

    try {
      final points = await _dbHelper.getPointsForProject(widget.project.id!);
      if (mounted) {
        setState(() {
          _projectPoints = points;
          _isLoadingPoints = false;
        });
      }
      if (_isMapReady) {
        _fitMapToPoints();
      }
    } catch (e, stackTrace) {
      logger.severe("MapToolView: Error loading points for map", e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading points for map: $e")),
        );
      }
    }
  }

  void _fitMapToPoints() {
    if (!_isMapReady || !mounted) {
      logger.info(
        "MapToolView: Attempted to fit map, but map not ready or widget unmounted.",
      );
      return;
    }
    if (_projectPoints.isEmpty || !mounted) {
      // Optionally move to a default location or the project's starting point if available
      // For now, if no points, map stays at its initial or default view
      _mapController.move(_getInitialCenter(), _getInitialZoom());
      return;
    }

    if (_projectPoints.length == 1) {
      _mapController.move(
        LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
        15.0, // Zoom in on a single point
      );
      return;
    }

    // Calculate bounds for multiple points
    final List<LatLng> pointCoords = _projectPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final bounds = LatLngBounds.fromPoints(pointCoords);

    // Add some padding to the bounds
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50.0), // Adjust padding as needed
      ),
    );
  }

  LatLng _getInitialCenter() {
    if (_projectPoints.isNotEmpty) {
      return LatLng(
        _projectPoints.first.latitude,
        _projectPoints.first.longitude,
      );
    }
    // You could also try to get a starting point from widget.project if available
    return _defaultCenter;
  }

  double _getInitialZoom() {
    return _projectPoints.isNotEmpty ? 14.0 : _defaultZoom;
  }

  @override
  void didUpdateWidget(covariant MapToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.project.id != oldWidget.project.id) {
      // Project changed, reload points
      _loadProjectPoints();
    }
    // You might also need to refresh if points list could change by other means
    // while MapToolView is active.
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPoints) {
      // Primary condition: still loading points
      return const Center(
        child: CircularProgressIndicator(
          key: ValueKey("loading_points_map_tool"),
        ),
      );
    }
    // Prepare markers from project points
    List<Marker> markers = _projectPoints.map((point) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(point.latitude, point.longitude),
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.location_pin),
              color: Colors
                  .red, // TODO: Consider making this dynamic based on point type/state
              iconSize: 30.0,
              onPressed: () {
                logger.info(
                  "Tapped on marker for point: P${point.ordinalNumber} (ID: ${point.id})",
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Point P${point.ordinalNumber}: ${point.note ?? 'No note'}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // Optionally: move map to center on this point and zoom in
                _mapController.move(
                  LatLng(point.latitude, point.longitude),
                  16.0,
                );
              },
            ),
            Container(
              // Simple label below icon
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ], // Subtle shadow
              ),
              child: Text(
                "P${point.ordinalNumber}",
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    // Create a list of LatLng for the Polyline
    // Only create if there are at least 2 points
    List<LatLng> polylinePoints = [];
    if (!_isLoadingPoints && _projectPoints.length >= 2) {
      polylinePoints = _projectPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize
                  .min, // maybe remove? Keep if parent might be scrollable
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // This Text widget might be redundant if the parent already displays project info
                // Consider if it adds value or can be removed.
                if (_projectPoints.isNotEmpty)
                  Padding(
                    // Added padding for better spacing
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Points on map: ${_projectPoints.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else if (!_isLoadingPoints) // Only show if not loading and no points
                  Padding(
                    // Added padding
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'No points in this project to display on map.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _getInitialCenter(),
                      initialZoom: _getInitialZoom(),
                      // bounds: _projectPoints.isNotEmpty
                      //     ? LatLngBounds.fromPoints(_projectPoints.map((p) => LatLng(p.latitude, p.longitude)).toList())
                      //     : null,
                      // boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
                      minZoom: 3.0, // Min zoom
                      maxZoom: 18.0, // Max zoom
                      onMapReady: () {
                        logger.info(
                          "MapToolView: Map is ready (onMapReady called).",
                        );
                        if (mounted) {
                          // Ensure widget is still mounted
                          setState(() {
                            _isMapReady = true;
                          });
                          // Now that map is ready, try to fit points (they might have loaded already)
                          _fitMapToPoints();
                        }
                      },
                      // Add other interactions if needed
                      // onTap: (tapPosition, latlng) {
                      //   // TODO: Handle map tap - e.g., add new point
                      // },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName:
                            'com.jlbbooks.teleferika', // Replace with your app's package name
                        // Recommended for OSM tile usage policy
                      ),
                      if (polylinePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              // color: Colors.blue, // Choose your line color
                              strokeWidth:
                                  4.0, // Slightly thicker for gradient visibility
                              gradientColors: [
                                // Example: From green to red
                                Colors.green,
                                Colors.yellow,
                                Colors.red,
                              ],
                              colorsStop: [
                                // Defines where each color transition happens
                                0.0, // Start with green
                                0.5, // Transition to yellow by the midpoint
                                1.0, // End with red
                              ],
                              // If colorsStop is null, the gradient is applied evenly.
                              // For more complex paths, you might want to calculate stops based on segment lengths.
                              // pattern: StrokePattern.dotted(),
                            ),
                          ],
                        ),
                      if (!_isLoadingPoints && markers.isNotEmpty)
                        MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isLoadingPoints &&
                _projectPoints.isNotEmpty) // Show FAB only if map is usable
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  onPressed: _fitMapToPoints,
                  tooltip: 'Center on points',
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),
          ],
        ),
      ),
    );
    // --- End Map Widget Replacement ---
  }
}
