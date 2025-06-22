// map_tool_view.dart

import 'dart:ui' as ui;

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
  String? _selectedPointId;

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

  Widget _buildStandardMarkerView(
    BuildContext context,
    PointModel point, {
    required bool isSelected,
  }) {
    // Your current perfect standard marker widget
    // (icon above label, pin tip is the anchor)
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedPointId == point.id) {
            _selectedPointId = null; // Tap again to deselect
          } else {
            _selectedPointId = point.id; // Select this point
          }
        });
      },
      child: Column(
        children: [
          Icon(
            Icons.location_pin,
            color: isSelected
                ? Colors.blueAccent
                : Colors.red, // Change icon color
            size: isSelected ? 30.0 : 30.0, // Optionally change size
          ), // ICON
          const SizedBox(height: 4),
          Container(
            // LABEL
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.8)
                  : Colors.white.withAlpha(220), // Change label background
              borderRadius: BorderRadius.circular(3),
              border: isSelected
                  ? Border.all(color: Colors.blueAccent, width: 1.5)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              "P${point.ordinalNumber}",
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white
                    : Colors.black, // Change label text color
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMarkerView(
    BuildContext context,
    PointModel point, {
    required Widget Function() standardMarkerBuilder,
    required double flyoutCardWidth,
    required double flyoutCardHeight,
    required double
    flyoutOffsetY, // Vertical distance from *top of standard marker* to *bottom of flyout*
    required double connectorLineHeight,
    required double totalWidth, // Total width of the marker for centering
  }) {
    // Constants for standard marker height used in _buildSelectedMarkerView
    const double standardMarkerActualHeight =
        60.0; // MUST MATCH what standard marker occupies

    return Stack(
      alignment: Alignment.bottomCenter,
      // Aligns children towards the bottom center of the Stack
      children: [
        // Layer 1: The standard marker (pin and label)
        // This will be at the bottom of the Stack due to alignment.
        standardMarkerBuilder(),

        // Layer 2: The Flyout Card and Connector, positioned above the standard marker
        // We need to position these from the top of the *Stack's allocated space*.
        // The Stack's height is selectedMarkerTotalHeight.
        // The standard marker takes up standardMarkerActualHeight at the bottom.
        // The space above the standard marker is where the flyout and connector go.

        // Connector Line
        Positioned(
          // Position it to span the vertical gap (flyoutOffsetY)
          // It should be centered horizontally over the standard marker.
          // The bottom of the line should be just above the (conceptual) top of the standard marker.
          // The top of the line should be just below the (conceptual) bottom of the flyout.
          bottom:
              standardMarkerActualHeight +
              (flyoutOffsetY - connectorLineHeight) / 2 -
              2,
          // Centering the line in the offset space
          height: connectorLineHeight,
          left: (totalWidth - 2) / 2,
          // Center the line horizontally
          width: 2,
          child: CustomPaint(painter: _FlyoutStemPainter()),
        ),

        // Flyout Card
        Positioned(
          // The card's bottom should be 'flyoutOffsetY' above the standard marker's top.
          // Since Stack positions from top, calculate 'top' position.
          // top: 0, // This would put it at the very top of the (tall) marker widget.
          // Let's position its *bottom* relative to the standard marker's *top*.
          // The standard marker is at the bottom of the Stack.
          // Its height is standardMarkerActualHeight.
          // So its top is at StackHeight - standardMarkerActualHeight from the Stack's top.
          // The flyout's bottom should be flyoutOffsetY above this.
          bottom: standardMarkerActualHeight + flyoutOffsetY,
          // Center the card horizontally within the totalWidth
          left: (totalWidth - flyoutCardWidth) / 2,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: flyoutCardWidth,
              // height: flyoutCardHeight, // Can be intrinsic
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                /* ... flyout content as before ... */
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Point P${point.ordinalNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (point.note?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                      child: Text(
                        point.note!,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Divider(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        iconSize: 20,
                        onPressed: () {
                          /* Edit */
                          setState(() => _selectedPointId = null);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        iconSize: 20,
                        onPressed: () {
                          /* Delete */ /* setState(() => _selectedPointId = null);*/
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
      final bool isSelected = point.id == _selectedPointId;

      return Marker(
        // The Marker's bounding box changes, but the content alignment should keep the pin fixed.
        width: 60,
        height: 60,
        point: LatLng(point.latitude, point.longitude),

        // CRUCIAL: This alignment refers to the anchor point within the *overall marker dimensions*.
        // If your _buildStandardMarkerView's pin tip is at its bottom-center,
        // and _buildSelectedMarkerView also positions its standard marker part at the bottom-center
        // of the enlarged space, this should work.
        // alignment: Alignment.bottomCenter,
        child: _buildStandardMarkerView(context, point, isSelected: isSelected),
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
                      onTap: (tapPosition, latlng) {
                        if (_selectedPointId != null) {
                          setState(() {
                            _selectedPointId =
                                null; // Deselect if a point was selected
                          });
                        }
                        // else { handle other map tap actions if needed }
                      },
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

// _FlyoutStemPainter remains the same
class _FlyoutStemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
