/// Project points layer widget for displaying geographic projects on maps.
///
/// This widget provides a comprehensive map layer that displays all projects
/// and their associated points as interactive markers and polylines. It can
/// be used in any FlutterMap to visualize project data with customizable styling.
///
/// ## Features
/// - **Point Markers**: Displays each project point as a customizable marker
/// - **Project Polylines**: Connects points within each project with lines
/// - **Project Labels**: Shows project names at strategic locations
/// - **Dynamic Loading**: Loads projects from Provider or database
/// - **Exclusion Support**: Can exclude specific projects from display
/// - **Customizable Styling**: Configurable colors, sizes, and appearance
/// - **Performance Optimized**: Efficient rendering for large datasets
///
/// ## Usage Examples
///
/// ### Basic Usage:
/// ```dart
/// FlutterMap(
///   children: [
///     TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
///     ProjectPointsLayer(),
///   ],
/// )
/// ```
///
/// ### With Custom Styling:
/// ```dart
/// ProjectPointsLayer(
///   markerSize: 12.0,
///   markerColor: Colors.red,
///   lineColor: Colors.blue,
///   lineWidth: 2.0,
/// )
/// ```
///
/// ### Excluding Current Project:
/// ```dart
/// ProjectPointsLayer(
///   excludeProjectId: currentProject.id,
///   markerColor: Colors.grey,
/// )
/// ```
///
/// ### With Pre-loaded Projects:
/// ```dart
/// ProjectPointsLayer(
///   projects: myProjects,
///   markerColor: Colors.green,
/// )
/// ```
///
/// ## Data Sources
/// The widget automatically determines the best data source:
/// 1. **Direct Projects**: If [ProjectPointsLayer.projects] parameter is provided
/// 2. **Provider State**: If available in the widget tree
/// 3. **Database Fallback**: Loads all projects from database
///
/// ## Visual Elements
/// - **Point Markers**: Circular markers at each geographic point
/// - **Project Lines**: Polylines connecting points in sequence
/// - **Project Labels**: Text labels showing project names
/// - **Exclusion Handling**: Gracefully skips excluded projects
///
/// ## Performance Considerations
/// - Efficient marker and polyline generation
/// - Minimal rebuilds during data updates
/// - Optimized for large numbers of projects
/// - Memory-conscious data loading
///
/// ## Customization Options
/// - **Marker Size**: Diameter of point markers
/// - **Marker Colors**: Fill and border colors for markers
/// - **Line Styling**: Color and width of project polylines
/// - **Border Styling**: Marker border color and width
///
/// ## Integration
/// Designed to work seamlessly with:
/// - FlutterMap for map display
/// - Project state management
/// - Database operations
/// - Provider pattern for state access

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/l10n/app_localizations.dart';

/// A reusable widget that displays project points as markers and connects them with polylines.
///
/// This widget provides a comprehensive map layer for visualizing geographic projects.
/// It automatically loads project data and renders points, polylines, and labels with
/// customizable styling options.
///
/// ## Data Loading Strategy
/// 1. **Direct Projects**: Use provided [ProjectPointsLayer.projects] list if available
/// 2. **Provider State**: Access projects through global state if available
/// 3. **Database Fallback**: Load all projects from database as last resort
class ProjectPointsLayer extends StatefulWidget {
  /// Optional list of projects to display.
  ///
  /// If provided, these projects will be used directly instead of loading
  /// from the database or Provider. Useful for performance optimization
  /// when projects are already available in memory.
  final List<ProjectModel>? projects;

  /// Optional project ID to exclude from display.
  ///
  /// If provided, the specified project will not be shown on the map.
  /// Useful for hiding the current project when showing other projects.
  final String? excludeProjectId;

  /// Size of the point markers in logical pixels.
  ///
  /// Defaults to 8.0 pixels. Larger values create more prominent markers.
  final double markerSize;

  /// Color of the point markers.
  ///
  /// Defaults to blue. This is the fill color of the circular markers.
  final Color markerColor;

  /// Color of the marker border.
  ///
  /// Defaults to white. Creates a border around each marker for better visibility.
  final Color markerBorderColor;

  /// Width of the marker border in logical pixels.
  ///
  /// Defaults to 1.0 pixel. Thicker borders provide better contrast.
  final double markerBorderWidth;

  /// Color of the project polylines.
  ///
  /// Defaults to black. This is the color of the lines connecting project points.
  final Color lineColor;

  /// Width of the project polylines in logical pixels.
  ///
  /// Defaults to 1.0 pixel. Thicker lines are more visible but may overlap.
  final double lineWidth;

  /// Creates a project points layer widget.
  ///
  /// All styling parameters are optional and have sensible defaults.
  /// The widget will automatically load projects if none are provided.
  const ProjectPointsLayer({
    super.key,
    this.projects,
    this.excludeProjectId,
    this.markerSize = 8.0,
    this.markerColor = Colors.blue,
    this.markerBorderColor = Colors.white,
    this.markerBorderWidth = 1.0,
    this.lineColor = Colors.black,
    this.lineWidth = 1.0,
  });

  @override
  State<ProjectPointsLayer> createState() => _ProjectPointsLayerState();
}

/// State class for the ProjectPointsLayer widget.
///
/// Manages the loading and display of project data, including automatic
/// data source selection and efficient rendering of map elements.
class _ProjectPointsLayerState extends State<ProjectPointsLayer> {
  /// Logger instance for debugging and error tracking.
  final Logger _logger = Logger('ProjectPointsLayer');

  /// Current list of projects to display on the map.
  ///
  /// This list is populated from the selected data source and used
  /// to generate markers, polylines, and labels.
  List<ProjectModel> _projects = [];

  /// Flag indicating if projects are currently being loaded.
  ///
  /// Used to prevent concurrent loading operations and provide
  /// appropriate UI feedback during data loading.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Don't access Provider here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    // If projects are provided directly, use them
    if (widget.projects != null) {
      setState(() {
        _projects = widget.projects!;
      });
      return;
    }

    // Try to get projects from Provider first
    try {
      final projectState = context.projectStateListen;
      if (projectState.hasProject) {
        // If we have a Provider with project data, we need to get all projects
        // For now, fall back to database loading
        _loadProjectsFromDatabase();
      } else {
        _loadProjectsFromDatabase();
      }
    } catch (e) {
      // Provider not available, load from database
      _logger.fine('Provider not available, loading from database: $e');
      _loadProjectsFromDatabase();
    }
  }

  Future<void> _loadProjectsFromDatabase() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await context.projectState.getAllProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.warning('Error loading projects from database: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Don't show anything while loading
    }

    return Stack(
      children: [
        // Project polylines layer
        PolylineLayer(polylines: _buildProjectPolylines()),
        // Point markers layer
        MarkerLayer(markers: _buildPointMarkers()),
        // Project name labels layer
        MarkerLayer(markers: _buildProjectNameMarkers()),
      ],
    );
  }

  List<Marker> _buildPointMarkers() {
    final markers = <Marker>[];

    for (final project in _projects) {
      // Skip the excluded project
      if (widget.excludeProjectId != null &&
          project.id == widget.excludeProjectId) {
        continue;
      }

      for (final point in project.points) {
        markers.add(
          Marker(
            point: LatLng(point.latitude, point.longitude),
            width: widget.markerSize,
            height: widget.markerSize,
            child: Container(
              decoration: BoxDecoration(
                color: widget.markerColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.markerBorderColor,
                  width: widget.markerBorderWidth,
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Polyline> _buildProjectPolylines() {
    final polylines = <Polyline>[];

    for (final project in _projects) {
      // Skip the excluded project
      if (widget.excludeProjectId != null &&
          project.id == widget.excludeProjectId) {
        continue;
      }

      final points = project.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      if (points.length > 1) {
        polylines.add(
          Polyline(
            points: points,
            color: widget.lineColor,
            strokeWidth: widget.lineWidth,
          ),
        );
      }
    }

    return polylines;
  }

  List<Marker> _buildProjectNameMarkers() {
    final markers = <Marker>[];

    for (final project in _projects) {
      // Skip the excluded project
      if (widget.excludeProjectId != null &&
          project.id == widget.excludeProjectId) {
        continue;
      }

      // Only show label if project has points
      final validPoints = project.points.toList();

      if (validPoints.isEmpty) continue;

      // Calculate center point of the project
      final centerLat =
          validPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
          validPoints.length;
      final centerLng =
          validPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
          validPoints.length;
      final centerPoint = LatLng(centerLat, centerLng);

      // Calculate font size based on marker size
      final fontSize = (widget.markerSize * 1.0).clamp(10.0, 18.0);

      final projectName = project.name.isNotEmpty ? project.name : 'Untitled';
      final fullText =
          '${S.of(context)?.project_label_prefix ?? 'Project: '}$projectName';

      markers.add(
        Marker(
          point: centerPoint,
          width: (fontSize * fullText.length * 0.6).clamp(
            120.0,
            300.0,
          ), // Adaptive width based on text length
          height: fontSize * 3.0, // Increased height to prevent text cutoff
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: widget.markerColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.markerColor, width: 1.0),
            ),
            child: Center(
              child: Text(
                fullText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }
}
