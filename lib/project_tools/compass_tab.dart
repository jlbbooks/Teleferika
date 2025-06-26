import 'package:flutter/material.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/project_tools/compass_tool_view.dart';

class CompassTab extends StatefulWidget {
  final ProjectModel project;
  final AddPointFromCompassCallback? onAddPointFromCompass;
  final bool isAddingPoint;

  const CompassTab({
    super.key,
    required this.project,
    this.onAddPointFromCompass,
    this.isAddingPoint = false,
  });

  @override
  State<CompassTab> createState() => _CompassTabState();
}

class _CompassTabState extends State<CompassTab> {
  @override
  Widget build(BuildContext context) {
    return CompassToolView(
      project: widget.project,
      onAddPointFromCompass: widget.onAddPointFromCompass,
      isAddingPoint: widget.isAddingPoint,
    );
  }
} 