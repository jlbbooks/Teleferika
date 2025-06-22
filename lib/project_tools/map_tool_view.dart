// map_tool_view.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

import '../logger.dart';
import '../point_details_page.dart';

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
  bool _isMovePointMode = false; // For activating point move mode
  bool _isMovingPointLoading =
      false; // Optional: For loading state during DB update

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

  Future<void> _relocatePoint(
    PointModel pointToMove,
    LatLng newPosition,
  ) async {
    if (_isMovingPointLoading) return;

    setState(() {
      _isMovingPointLoading = true;
      // Optional: Provide immediate visual feedback by updating local list first
      // This can make the UI feel snappier, but handle potential DB errors.
      // final index = _projectPoints.indexWhere((p) => p.id == pointToMove.id);
      // if (index != -1) {
      //   _projectPoints[index] = pointToMove.copyWith(
      //     latitude: newPosition.latitude,
      //     longitude: newPosition.longitude,
      //     // lastUpdated: DateTime.now(), // Consider if your PointModel tracks this
      //   );
      // }
    });

    try {
      // Create the updated point model for the database
      final updatedPoint = pointToMove.copyWith(
        latitude: newPosition.latitude,
        longitude: newPosition.longitude,
        // lastUpdated: DateTime.now(), // If your model has this
      );

      // Assuming you have a method in DatabaseHelper like:
      // Future<int> updatePoint(PointModel point)
      // Or more specific: updatePointCoordinates(String id, double lat, double lon)
      int result = await _dbHelper.updatePoint(
        updatedPoint,
      ); // Or your specific update method

      if (!mounted) return;

      if (result > 0) {
        // Successfully updated in DB, now update the main list for sure
        setState(() {
          final index = _projectPoints.indexWhere(
            (p) => p.id == updatedPoint.id,
          );
          if (index != -1) {
            _projectPoints[index] = updatedPoint;
          }
          _isMovePointMode = false; // Exit move mode
          // _selectedPointId remains the same, panel will update with new coords if shown
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Point P${updatedPoint.ordinalNumber} moved successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Error: Could not move point P${pointToMove.ordinalNumber}. Point not found or not updated.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        // Optional: Revert optimistic UI update if you did one
      }
    } catch (e) {
      logger.severe('Failed to move point P${pointToMove.ordinalNumber}: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Error moving point P${pointToMove.ordinalNumber}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      // Optional: Revert optimistic UI update
    } finally {
      if (mounted) {
        setState(() {
          _isMovingPointLoading = false;
        });
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

  // Method to handle deletion triggered from the side panel
  Future<void> _handleDeletePointFromPanel(PointModel pointToDelete) async {
    // Show confirmation dialog (UI specific, can be a shared dialog widget too)
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete point P${pointToDelete.ordinalNumber}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // You might want a loading indicator for the panel
      // setState(() { _isDeletingFromPanel = true; }); // If you have such a flag

      try {
        final int count = await _dbHelper.deletePointById(
          pointToDelete.id!,
        ); // USE THE SHARED METHOD

        if (!mounted) return;

        if (count > 0) {
          setState(() {
            _projectPoints.removeWhere((p) => p.id == pointToDelete.id);
            logger.info(
              "Point P${pointToDelete.ordinalNumber} (ID: ${pointToDelete.id}) removed from MapToolView after panel delete.",
            );
            if (_selectedPointId == pointToDelete.id) {
              _selectedPointId = null; // Deselect and hide panel
            }
          });
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Point P${pointToDelete.ordinalNumber} deleted.'),
                backgroundColor: Colors.green,
              ),
            );
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Point P${pointToDelete.ordinalNumber} could not be found or deleted from map view.',
                ),
                backgroundColor: Colors.red,
              ),
            );
        }
      } catch (e) {
        if (!mounted) return;
        logger.severe(
          'Failed to delete point P${pointToDelete.ordinalNumber} from panel: $e',
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting point P${pointToDelete.ordinalNumber}: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
      } finally {
        // if (mounted) {
        //   setState(() { _isDeletingFromPanel = false; });
        // }
      }
    }
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
    PointModel? selectedPointInstance;
    if (_selectedPointId != null) {
      try {
        selectedPointInstance = _projectPoints.firstWhere(
          (p) => p.id == _selectedPointId,
        );
      } catch (e) {
        // Point might have been deleted or list changed, deselect
        Future.microtask(() => setState(() => _selectedPointId = null));
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
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
              onTap: (tapPosition, latlng) {
                if (_isMovePointMode && _selectedPointId != null) {
                  PointModel? pointToMove;
                  try {
                    pointToMove = _projectPoints.firstWhere(
                      (p) => p.id == _selectedPointId,
                    );
                  } catch (e) {
                    // Point not found, should not happen if selectedPointId is valid
                    logger.warning(
                      "Selected point for move not found in _projectPoints.",
                    );
                    setState(() {
                      _isMovePointMode = false; // Exit move mode
                    });
                    return;
                  }
                  // Call the relocate method
                  _relocatePoint(pointToMove, latlng);
                } else if (!_isMovePointMode && _selectedPointId != null) {
                  // Default behavior: Deselect if a point was selected and not in move mode
                  setState(() {
                    _selectedPointId = null;
                  });
                }
                // If _isMovePointMode is true but _selectedPointId is null (shouldn't happen if UI is right),
                // you might want to reset _isMovePointMode or handle it.
                // TODO: check this
                // if (_selectedPointId != null) {
                //   setState(() {
                //     _selectedPointId = null; // Deselect if a point was selected
                //   });
                // }
                // else { handle other map tap actions if needed }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName:
                    'com.jlbbooks.teleferika', // Replace with your app's package name
                // Recommended for OSM tile usage policy
              ),
              if (!_isLoadingPoints && polylinePoints.isNotEmpty)
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
          // Layer 2: Side Panel for Actions (only when a point is selected)
          if (selectedPointInstance != null)
            Positioned(
              top:
                  10, // Adjust as needed (e.g., MediaQuery.of(context).padding.top + 10)
              right: 10,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: P${selectedPointInstance.ordinalNumber}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        // const SizedBox(height: 4.0),
                        if (selectedPointInstance.note?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 250, // Adjust as needed
                              ),
                              child: Text(
                                selectedPointInstance.note!,
                                // "test",
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        Padding(
                          // Coordinates
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'Lat: ${selectedPointInstance.latitude.toStringAsFixed(6)}, Lon: ${selectedPointInstance.longitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        if (_isMovePointMode &&
                            selectedPointInstance.id == _selectedPointId)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Tap on the map to set new location.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const Divider(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize
                              .min, // Crucial for this Row to report its minimum required width
                          // This width is what IntrinsicWidth will likely use if it's the dominant one.
                          mainAxisAlignment: MainAxisAlignment
                              .start, // Use this with SizedBox for defined spacing
                          // Or MainAxisAlignment.spaceBetween if you want them to spread within the min width
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              label: const Text('Edit'),
                              onPressed: _isMovePointMode
                                  ? null // Disable if in move mode
                                  : () async {
                                      if (selectedPointInstance == null)
                                        return; // Guard against null

                                      logger.info(
                                        "Navigating to edit point P${selectedPointInstance!.ordinalNumber}",
                                      );
                                      // Navigate to PointDetailsPage and wait for a result
                                      final result =
                                          await Navigator.push<
                                            Map<String, dynamic>
                                          >(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PointDetailsPage(
                                                    point:
                                                        selectedPointInstance!,
                                                  ),
                                            ),
                                          );
                                      // Process the result when PointDetailsPage is popped
                                      if (result != null) {
                                        final String? action =
                                            result['action'] as String?;
                                        logger.info(
                                          "Returned from PointDetailsPage with action: $action",
                                        );

                                        if (action == 'updated') {
                                          final PointModel? updatedPoint =
                                              result['point'] as PointModel?;
                                          if (updatedPoint != null) {
                                            setState(() {
                                              final index = _projectPoints
                                                  .indexWhere(
                                                    (p) =>
                                                        p.id == updatedPoint.id,
                                                  );
                                              if (index != -1) {
                                                _projectPoints[index] =
                                                    updatedPoint;
                                                logger.info(
                                                  "Point P${updatedPoint.ordinalNumber} updated in MapToolView.",
                                                );
                                                // If the updated point was the selected one, the side panel
                                                // will automatically reflect changes in the next build because
                                                // selectedPointInstance is re-derived from _projectPoints.
                                              }
                                            });
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Point P${updatedPoint.ordinalNumber} details updated!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                          }
                                        } else if (action == 'deleted') {
                                          final String? deletedPointId =
                                              result['pointId'] as String?;
                                          // final int? ordinalNumber = result['ordinalNumber'] as int?; // For messages
                                          if (deletedPointId != null) {
                                            setState(() {
                                              _projectPoints.removeWhere(
                                                (p) => p.id == deletedPointId,
                                              );
                                              logger.info(
                                                "Point ID $deletedPointId removed from MapToolView.",
                                              );
                                              // If the deleted point was selected, deselect it
                                              if (_selectedPointId ==
                                                  deletedPointId) {
                                                _selectedPointId = null;
                                              }
                                            });
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                const SnackBar(
                                                  // You can use ordinalNumber here if you pass it back
                                                  content: Text(
                                                    'Point deleted.',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange, // Or green
                                                ),
                                              );
                                          }
                                        }
                                      } else {
                                        logger.info(
                                          "PointDetailsPage popped without a result (e.g., back button pressed).",
                                        );
                                      }
                                      // Optionally, you might want to always deselect or refresh the selectedPointInstance
                                      // if the side panel relies on a copy that isn't directly from _projectPoints.
                                      // However, your current structure of deriving selectedPointInstance at the start
                                      // of the build method from _projectPoints should handle this.
                                    },
                            ),
                            TextButton.icon(
                              icon: Icon(
                                _isMovePointMode &&
                                        selectedPointInstance.id ==
                                            _selectedPointId
                                    ? Icons
                                          .cancel_outlined // Show cancel if this point is being moved
                                    : Icons.open_with, // Standard move icon
                                color:
                                    _isMovePointMode &&
                                        selectedPointInstance.id ==
                                            _selectedPointId
                                    ? Colors.orangeAccent
                                    : Colors.teal,
                              ),
                              label: Text(
                                _isMovePointMode &&
                                        selectedPointInstance.id ==
                                            _selectedPointId
                                    ? 'Cancel'
                                    : 'Move',
                              ),
                              onPressed: _isMovingPointLoading
                                  ? null
                                  : () {
                                      // Disable if a move is processing
                                      if (_isMovePointMode &&
                                          selectedPointInstance?.id ==
                                              _selectedPointId) {
                                        // Cancel move mode
                                        setState(() {
                                          _isMovePointMode = false;
                                        });
                                      } else if (!_isMovePointMode) {
                                        // Activate move mode for this point
                                        setState(() {
                                          _isMovePointMode = true;
                                          // _selectedPointId is already set for the panel to show
                                        });
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Move mode activated. Tap map to relocate point.',
                                              ),
                                              backgroundColor: Colors.blueGrey,
                                            ),
                                          );
                                      }
                                    },
                            ),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              label: const Text('Delete'),
                              onPressed:
                                  (_isMovePointMode || _isMovingPointLoading)
                                  ? null
                                  : () {
                                      logger.info(
                                        "Delete tapped for point P${selectedPointInstance!.ordinalNumber}",
                                      );
                                      _handleDeletePointFromPanel(
                                        selectedPointInstance,
                                      );
                                    },
                            ),
                          ],
                        ),
                        if (_isMovingPointLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Center(child: LinearProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
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
