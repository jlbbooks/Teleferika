import 'package:flutter/material.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/project_tools/map_tool_view.dart';

class MapTab extends StatefulWidget {
  final ProjectModel project;
  final String? selectedPointId;
  final VoidCallback? onNavigateToCompassTab;
  final Function(BuildContext, double, {bool? setAsEndPoint})? onAddPointFromCompass;

  const MapTab({
    super.key,
    required this.project,
    this.selectedPointId,
    this.onNavigateToCompassTab,
    this.onAddPointFromCompass,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  @override
  Widget build(BuildContext context) {
    return MapToolView(
      project: widget.project,
      selectedPointId: widget.selectedPointId,
      onNavigateToCompassTab: widget.onNavigateToCompassTab,
      onAddPointFromCompass: widget.onAddPointFromCompass,
    );
  }
} 