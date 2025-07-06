import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/l10n/app_localizations.dart';

/// A reusable widget that displays project points as markers and connects them with polylines.
/// Can be used in any FlutterMap to show project data.
///
/// This widget will:
/// 1. First try to get projects from the Provider if available
/// 2. Fall back to loading all projects from the database if no Provider is found
class ProjectPointsLayer extends StatefulWidget {
  final List<ProjectModel>? projects;
  final String? excludeProjectId;
  final double markerSize;
  final Color markerColor;
  final Color markerBorderColor;
  final double markerBorderWidth;
  final Color lineColor;
  final double lineWidth;

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

class _ProjectPointsLayerState extends State<ProjectPointsLayer> {
  final Logger _logger = Logger('ProjectPointsLayer');
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<ProjectModel> _projects = [];
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
      final projects = await _dbHelper.getAllProjects();
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
