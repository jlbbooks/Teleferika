import 'package:flutter/material.dart';
import 'package:teleferika/db/models/project_model.dart';

import 'points_tool_view.dart';

class PointsTab extends StatefulWidget {
  final ProjectModel project;

  const PointsTab({
    super.key,
    required this.project,
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

  /// Public method to undo changes in PointsToolView
  Future<void> undoChanges() async {
    await _pointsToolViewKey.currentState?.undoChanges();
  }

  /// Public method to clear backup in PointsToolView
  void clearBackup() {
    _pointsToolViewKey.currentState?.clearBackup();
  }
}
