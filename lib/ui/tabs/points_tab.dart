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
  State<PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<PointsTab> {
  // Optionally, you could use a GlobalKey<PointsToolViewState> here if you want to call refreshPoints()
  // final GlobalKey<PointsToolViewState> _pointsToolViewKey = GlobalKey<PointsToolViewState>();

  @override
  Widget build(BuildContext context) {
    return PointsToolView(
      // key: _pointsToolViewKey, // Only if you need to call refreshPoints() from parent
      project: widget.project,
      onPointsChanged: widget.onPointsChanged,
      onProjectChanged: widget.onProjectChanged,
    );
  }
}
