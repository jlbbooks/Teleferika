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
    // _mapController = MapController();
    _loadProjectPoints();
  }

  Future<void> _loadProjectPoints() async {
    setState(() {
      _isLoadingPoints = true;
    });
    if (widget.project.id == null) {
      logger.info("MapToolView: Project ID is null, cannot load points.");
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
          _projectPoints = [];
        });
      }
      return;
    }
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
      }
      if (mounted) {
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
  void dispose() {
    // _mapController.dispose(); // MapController is not a ChangeNotifier, no dispose needed from user side
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPoints) {
      // Primary condition: still loading points
      return const Center(
        child: CircularProgressIndicator(key: ValueKey("loading_points")),
      );
    }
    // Prepare markers from project points
    List<Marker> markers = _projectPoints.map((point) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(point.latitude, point.longitude),
        child: Column(
          // Using child for custom marker
          children: [
            IconButton(
              icon: const Icon(Icons.location_pin),
              color: Colors.red,
              iconSize: 30.0,
              onPressed: () {
                logger.info(
                  "Tapped on marker for point: P${point.ordinalNumber}",
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
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(3),
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
        // anchorPos: AnchorPos.align(AnchorAlign.top), // If icon's visual center is not its geometric center
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center, // TODO: maybe remove
        mainAxisSize: MainAxisSize
            .min, // maybe remove? Keep if parent might be scrollable
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              if (_projectPoints.isNotEmpty)
                Text(
                  'Points: ${_projectPoints.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else if (!_isLoadingPoints) // Only show if not loading and no points
                Text(
                  'No points in this project to display on map.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
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
                  logger.info("MapToolView: Map is ready (onMapReady called).");
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
                //   // Handle map tap - e.g., add new point
                // },
              ),
              children: [
                // Use children instead of layers for flutter_map 6.x+
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        color: Colors.blue, // Choose your line color
                        strokeWidth: 3.0, // Choose your line width
                        pattern: StrokePattern.dotted(),
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
    );
    // --- End Map Widget Replacement ---
  }
}
