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

  Widget _buildStandardMarkerView(BuildContext context, PointModel point) {
    // This is your current marker + label widget from the file.
    // Example structure (ADAPT TO YOUR ACTUAL CURRENT STANDARD MARKER):
    return GestureDetector(
      onTap: () {
        setState(() {
          // Tapped on the label
          _selectedPointId = point.id;
        });
      },
      child: Column(
        // Assuming label is above icon, and icon is last
        // mainAxisSize: MainAxisSize.min,
        // mainAxisAlignment: MainAxisAlignment.end,
        // Push content to bottom for bottomCenter anchor
        children: [
          IconButton(
            icon: const Icon(Icons.location_pin),
            color: Colors.red,
            iconSize: 30.0,
            onPressed: () {
              // Tapped on the icon
              logger.info(
                "Tapped on marker for point: P${point.ordinalNumber} (ID: ${point.id})",
              );
              setState(() {
                _selectedPointId = point.id;
              });
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(3),
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
  }

  Widget _buildSelectedMarkerView(
    BuildContext context,
    PointModel point, {
    required double flyoutWidth,
    required double flyoutHeight,
    required double pinIconSize,
    required double spaceBetweenPinAndFlyout,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. The Flyout Card (Positioned at the top)
        Positioned(
          top: 0,
          child: Material(
            // Use Material for elevation and shape if Card isn't enough
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: flyoutWidth,
              // height: flyoutHeight, // Or let it be intrinsic based on content
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
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
                        tooltip: 'Edit Point',
                        onPressed: () {
                          logger.info(
                            "Edit tapped for point P${point.ordinalNumber} (ID: ${point.id})",
                          );
                          // TODO: Implement navigation or dialog for editing
                          // Example: Navigator.push(...EditPointPage(point: point)...);
                          setState(() => _selectedPointId = null); // Deselect
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        iconSize: 20,
                        tooltip: 'Delete Point',
                        onPressed: () {
                          // TODO: Implement delete confirmation and logic
                          // _confirmDeletePoint(point); // From previous examples
                          logger.info(
                            "Delete tapped for point P${point.ordinalNumber} (ID: ${point.id})",
                          );
                          // Ensure _selectedPointId is nulled after action or in confirmation dialog
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Optional: Visual Connector (Line/Stem)
        // This line connects the bottom-center of the flyout to the top-center of the pin.
        Positioned(
          top: flyoutHeight - 2,
          // Start slightly before the bottom of the flyout card
          bottom: pinIconSize + (spaceBetweenPinAndFlyout - flyoutHeight) + 2,
          // End slightly before the top of pin
          // This calculation is a bit tricky, adjust as needed
          // Or more simply:
          // top: flyoutHeight, // Start at bottom of card
          // height: spaceBetweenPinAndFlyout - flyoutHeight - pinIconSize, (this needs to be positive)

          // Simpler line positioning:
          // top: flyoutHeight, // Start drawing from the bottom edge of the flyout
          // height: spaceBetweenPinAndFlyout - (flyoutHeight / 2) - (pinIconSize / 2), // Approximate height for the line
          child: CustomPaint(
            painter: _FlyoutStemPainter(), // Simple vertical line painter
            size: Size(
              2,
              spaceBetweenPinAndFlyout - flyoutHeight * 0.5 - pinIconSize * 0.5,
            ), // Adjust line height
          ),
        ),

        // 3. The Pin Icon (Positioned at the bottom of the Stack)
        Positioned(
          bottom: 0,
          child: Icon(Icons.location_pin, color: Colors.red, size: pinIconSize),
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

      // --- Define Dimensions ---
      // Standard (non-selected) marker dimensions
      const double standardMarkerWidth =
          80.0; // Or whatever your current standard marker needs
      const double standardMarkerHeight = 80.0;

      // Selected marker dimensions (needs to be larger to hold the flyout)
      const double flyoutWidth = 120.0;
      const double flyoutHeight = 60.0; // Approximate height of the flyout card
      const double pinIconSize = 30.0;
      const double spaceBetweenPinAndFlyout = 40.0; // The "distance" you want

      const double selectedMarkerWidth =
          flyoutWidth; // Marker width is flyout width
      const double selectedMarkerHeight =
          flyoutHeight + spaceBetweenPinAndFlyout + pinIconSize;

      return Marker(
        width: isSelected ? selectedMarkerWidth : standardMarkerWidth,
        height: isSelected ? selectedMarkerHeight : standardMarkerHeight,
        point: LatLng(point.latitude, point.longitude),
        // alignment: Alignment
        //     .bottomCenter, // <<< CRUCIAL for consistent anchor at pin tip
        child: isSelected
            ? _buildSelectedMarkerView(
                context,
                point,
                flyoutWidth: flyoutWidth,
                flyoutHeight: flyoutHeight,
                pinIconSize: pinIconSize,
                spaceBetweenPinAndFlyout: spaceBetweenPinAndFlyout,
              )
            : _buildStandardMarkerView(
                context,
                point,
              ), // Your current marker + label widget
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

// Painter for the stem (simple vertical line)
class _FlyoutStemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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
