import 'package:flutter/material.dart';
import 'package:teleferika/db/models/project_model.dart';

import 'points_tool_view.dart';

class PointsTab extends StatefulWidget {
  final ProjectModel project;
  final Function()? onPointsChanged;
  final Function(ProjectModel, {bool hasUnsavedChanges})? onProjectChanged;

  const PointsTab({
    super.key,
    required this.project,
    this.onPointsChanged,
    this.onProjectChanged,
  });

  @override
  State<PointsTab> createState() => PointsTabState();
}

class PointsTabState extends State<PointsTab> {
  // GlobalKey to access PointsToolView methods
  final GlobalKey<PointsToolViewState> _pointsToolViewKey =
      GlobalKey<PointsToolViewState>();

  @override
  Widget build(BuildContext context) {
    return PointsToolView(
      key: _pointsToolViewKey,
      project: widget.project,
      onPointsChanged: widget.onPointsChanged,
      onProjectChanged: widget.onProjectChanged,
    );
  }

  /// Public method to access PointsToolView's onProjectSaved method
  void onProjectSaved() {
    _pointsToolViewKey.currentState?.onProjectSaved();
  }

  /// Public method to refresh points in PointsToolView
  void refreshPoints() {
    _pointsToolViewKey.currentState?.refreshPoints();
  }

  /// Public method to create backup in PointsToolView
  void createBackup() {
    _pointsToolViewKey.currentState?.createBackup();
  }

  /// Public method to update local project state in PointsToolView
  void updateLocalProject(ProjectModel project) {
    _pointsToolViewKey.currentState?.updateLocalProject(project);
  }
}
