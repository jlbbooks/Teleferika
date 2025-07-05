// points_tool_view.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/pages/point_details_page.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:teleferika/ui/tabs/map/map_controller.dart';
import 'dart:io';

class PointsToolView extends StatefulWidget {
  final ProjectModel project;
  final List<PointModel> points;

  const PointsToolView({
    super.key,
    required this.project,
    required this.points,
  });

  @override
  State<PointsToolView> createState() => PointsToolViewState();
}

class PointsToolViewState extends State<PointsToolView> with StatusMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger logger = Logger('PointsToolView');

  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedPointIds = {};
  final Set<String> _expandedPointIds = {};

  // Store previous project data for comparison
  ProjectModel? _previousProject;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize previous project data after dependencies are available
    _previousProject ??=
        context.projectStateListen.currentProject ?? widget.project;
  }

  @override
  void didUpdateWidget(PointsToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if parent project start/end points changed using global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;

    if (_previousProject?.startingPointId != currentProject.startingPointId ||
        _previousProject?.endingPointId != currentProject.endingPointId) {
      // Refresh from global state
      _loadPoints();
    }

    // Update stored project data
    _previousProject = currentProject;
  }

  // Make _loadPoints return Future<void> and update _points
  Future<void> _loadPoints() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use global state to get points
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      if (!projectState.hasUnsavedChanges) {
        await projectState.refreshPoints();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.severe("Error loading points in PointsToolView", e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorStatus('Error loading points: ${e.toString()}');
      }
    }
  }

  // Make _loadPoints public or create a new public refresh method
  void refreshPoints() {
    _loadPoints();
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedPointIds.clear();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPointIds.clear();
      }
    });
  }

  void _togglePointSelection(String pointId) {
    setState(() {
      if (_selectedPointIds.contains(pointId)) {
        _selectedPointIds.remove(pointId);
        if (_selectedPointIds.isEmpty && _isSelectionMode) {
          // Optionally exit selection mode if last item is deselected
          // _isSelectionMode = false;
        }
      } else {
        _selectedPointIds.add(pointId);
      }
    });
  }

  void _toggleExpanded(String pointId) {
    setState(() {
      if (_expandedPointIds.contains(pointId)) {
        _expandedPointIds.remove(pointId);
      } else {
        _expandedPointIds.add(pointId);
      }
    });
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    // 1. Adjust newIndex based on ReorderableListView behavior
    final int adjustedNewIndex = (newIndex > oldIndex)
        ? newIndex - 1
        : newIndex;

    // 2. Validate indices
    if (!_isValidReorder(oldIndex, adjustedNewIndex)) {
      return;
    }

    // 3. Get current points from editing state
    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    final currentPoints = projectState.currentPoints;
    final List<PointModel> reorderedPointsWithNewOrdinals =
        _getReorderedPointsWithNewOrdinals(
          currentPoints,
          oldIndex,
          adjustedNewIndex,
        );

    // 4. Update the editing state (in-memory only)
    projectState.reorderPointsInEditingState(reorderedPointsWithNewOrdinals);
  }

  /// Validates if the reorder operation is valid.
  bool _isValidReorder(int oldIndex, int newIndex) {
    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    final points = projectState.currentPoints;
    if (newIndex < 0 || newIndex >= points.length || oldIndex == newIndex) {
      return false;
    }
    return true;
  }

  /// Reorders the local `_points` list and returns a new list
  /// where each `PointModel` has its `ordinalNumber` updated to match its new position.
  List<PointModel> _getReorderedPointsWithNewOrdinals(
    List<PointModel> points,
    int oldIndex,
    int newIndex,
  ) {
    final List<PointModel> reorderedPoints = List.from(points);
    final PointModel movedPoint = reorderedPoints.removeAt(oldIndex);
    reorderedPoints.insert(newIndex, movedPoint);

    // Update ordinal numbers to match new positions
    for (int i = 0; i < reorderedPoints.length; i++) {
      reorderedPoints[i] = reorderedPoints[i].copyWith(ordinalNumber: i + 1);
    }

    return reorderedPoints;
  }

  /// Public method to access undo functionality from parent
  Future<void> undoChanges() async {
    await context.projectState.undoChanges();
  }

  /// Public method to access onProjectSaved functionality from parent
  void onProjectSaved() {
    // No backup to clear; nothing needed
  }

  // --- Action Bar for Normal and Selection Mode ---
  Widget _buildTopBar(BuildContext context) {
    if (_isSelectionMode) {
      final s = S.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: s?.buttonCancel ?? 'Cancel',
              onPressed:
                  _toggleSelectionMode, // Exits selection mode & clears selection
            ),
            Text(
              s?.selected_count(_selectedPointIds.length) ??
                  '${_selectedPointIds.length} selected',
            ),
            TextButton.icon(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                s?.buttonDelete ?? 'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: _selectedPointIds.isEmpty
                  ? null
                  : _confirmDeleteSelectedPoints,
            ),
          ],
        ),
      );
    } else {
      // Return empty container when not in selection mode
      return const SizedBox.shrink();
    }
  }

  // --- End Action Bar ---

  // --- Confirmation Dialog for Deletion ---
  Future<void> _confirmDeleteSelectedPoints() async {
    if (_selectedPointIds.isEmpty) return;

    final s = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(s?.confirm_deletion_title ?? 'Confirm Deletion'),
          content: Text(
            s?.confirm_deletion_content(_selectedPointIds.length.toString()) ??
                'Are you sure you want to delete ${_selectedPointIds.length} selected point(s)? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(s?.buttonCancel ?? 'Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(s?.buttonDelete ?? 'Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteSelectedPoints();
    }
  }

  // --- End Confirmation Dialog ---

  // --- Delete Logic ---
  Future<void> _deleteSelectedPoints() async {
    if (_selectedPointIds.isEmpty) return;

    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );

    try {
      // Delete points in editing state (in-memory only)
      for (String pointId in _selectedPointIds) {
        projectState.deletePointInEditingState(pointId);
      }

      if (mounted) {
        showSuccessStatus('${_selectedPointIds.length} point(s) deleted.');
      }
      _clearSelection();
    } catch (error, stackTrace) {
      logger.severe('Error deleting points', error, stackTrace);
      if (mounted) {
        showErrorStatus('Error deleting points: $error');
      }
    }
  }

  // --- End Delete Logic ---

  /// Builds a single point item Card for the ListView.
  Widget _buildPointItem(
    BuildContext context,
    PointModel point,
    int index,
    ProjectModel project,
  ) {
    final bool isSelectedForDelete = _selectedPointIds.contains(point.id);
    final Color baseSelectionColor = Theme.of(context).primaryColorLight;
    const double selectedOpacity = 0.3;

    final points = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    ).currentPoints;

    // Get previous point if exists
    PointModel? prevPoint;
    if (index > 0 && index < points.length) {
      prevPoint = points[index - 1];
    }

    // Calculate distance from previous point
    double? distanceFromPrev;
    if (prevPoint != null) {
      distanceFromPrev = point.distanceFromPoint(prevPoint);
    }

    // Offset from heading line
    double? offset;
    if (points.length >= 2) {
      final logic = MapControllerLogic(project: project);
      offset = logic.distanceFromPointToFirstLastLine(point, points);
    }

    final isExpanded = _expandedPointIds.contains(point.id);

    return Card(
      key: ValueKey(point.id),
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      elevation: _isSelectionMode && isSelectedForDelete ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        side: _isSelectionMode && isSelectedForDelete
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: _isSelectionMode && isSelectedForDelete
          ? baseSelectionColor.withAlpha((selectedOpacity * 255).round())
          : null,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _togglePointSelection(point.id);
          }
        },
        onLongPress: () => _handlePointLongPress(point),
        borderRadius: BorderRadius.circular(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle (only when not in selection mode)
                if (!_isSelectionMode)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                // Edit icon on the left
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                  tooltip: S.of(context)?.edit_point_title ?? 'Edit Point',
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PointDetailsPage(point: point),
                      ),
                    );
                    if (result != null && mounted) {
                      final String? action = result['action'] as String?;
                      final PointModel? updatedPoint =
                          result['point'] as PointModel?;
                      if ((action == 'updated' || action == 'created') &&
                          updatedPoint != null) {
                        // Use Provider to update global state
                        context.projectState.updatePointInEditingState(
                          updatedPoint,
                        );
                      }
                    }
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      point.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => _toggleExpanded(point.id),
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),
            // Always show basic info lines
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance
                  if (distanceFromPrev != null && prevPoint != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          size: 18,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${S.of(context)?.distanceFromPrevious(prevPoint.name) ?? 'Distance:'} ${distanceFromPrev >= 1000 ? '${(distanceFromPrev / 1000).toStringAsFixed(2)} ${S.of(context)?.unit_kilometer ?? 'km'}' : '${distanceFromPrev.toStringAsFixed(1)} ${S.of(context)?.unit_meter ?? 'm'}'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  // Offset
                  if (offset != null && offset > 0.0)
                    Row(
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 18,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ('${S.of(context)?.offsetLabel ?? 'Offset:'} ') +
                              (offset >= 1000
                                  ? '${(offset / 1000).toStringAsFixed(2)} ${S.of(context)?.unit_kilometer ?? 'km'}'
                                  : '${offset.toStringAsFixed(1)} ${S.of(context)?.unit_meter ?? 'm'}'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  // Note preview removed from basic info
                ],
              ),
            ),
            // Expanded section: full note, altitude, and images
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Latitude
                    Row(
                      children: [
                        Icon(
                          AppConfig.latitudeIcon,
                          size: 18,
                          color: AppConfig.latitudeColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${S.of(context)?.latitude_label ?? 'Lat'}: ${point.latitude.toStringAsFixed(5)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    // Longitude
                    Row(
                      children: [
                        Icon(
                          AppConfig.longitudeIcon,
                          size: 18,
                          color: AppConfig.longitudeColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ('${S.of(context)?.longitude_label ?? 'Lon:'}: ') +
                              point.longitude.toStringAsFixed(5),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    // Altitude (already here)
                    if (point.altitude != null)
                      Row(
                        children: [
                          Icon(
                            AppConfig.altitudeIcon,
                            size: 18,
                            color: AppConfig.altitudeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${S.of(context)?.altitude_label ?? 'Alt:'}: ${point.altitude!.toStringAsFixed(2)} ${S.of(context)?.unit_meter ?? 'm'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    // Full note (untruncated)
                    if (point.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, left: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes,
                              size: 18,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                point.note,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Images (miniatures)
                    if (point.images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: point.images.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, imgIdx) {
                              final img = point.images[imgIdx];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(img.imagePath),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  // --- End Widget Building Helper Methods ---

  void _handlePointLongPress(PointModel point) {
    setState(() {
      if (!_isSelectionMode) {
        // If not in selection mode, enter it and select the current item
        _isSelectionMode = true;
        _selectedPointIds.add(point.id);
      } else {
        // If already in selection mode, just toggle the selection of the current item
        _togglePointSelection(point.id);
      }
    });
  }

  // --- End Point Item Interaction Handlers ---

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        // Get current project data from global state
        final currentProject = projectState.currentProject ?? widget.project;
        final points = projectState.currentPoints;
        final hasUnsavedNewPoint = projectState.hasUnsavedNewPoint;

        return Stack(
          children: [
            Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPointsList(
                          context,
                          currentProject,
                          points,
                          hasUnsavedNewPoint,
                        ),
                ),
              ],
            ),
            Positioned(
              top: 24,
              right: 24,
              child: StatusIndicator(
                status: currentStatus,
                onDismiss: hideStatus,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsList(
    BuildContext context,
    ProjectModel project,
    List<PointModel> points,
    bool hasUnsavedNewPoint,
  ) {
    return points.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                S.of(context)?.points_list_title ?? 'Points List',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: points.length,
                  onReorder: _isSelectionMode
                      ? (int oldI, int newI) {}
                      : _handleReorder,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    return _buildPointItem(context, point, index, project);
                  },
                ),
              ),
            ],
          );
  }
}
