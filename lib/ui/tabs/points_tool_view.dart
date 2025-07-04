// points_tool_view.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/pages/point_details_page.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:teleferika/ui/tabs/map/map_controller.dart';

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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
              onPressed:
                  _toggleSelectionMode, // Exits selection mode & clears selection
            ),
            Text('${_selectedPointIds.length} selected'),
            TextButton.icon(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'Delete',
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

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete ${_selectedPointIds.length} selected point(s)? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
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
    // index needed for Key
    final bool isSelectedForDelete = _selectedPointIds.contains(point.id);
    final Color baseSelectionColor = Theme.of(context).primaryColorLight;
    const double selectedOpacity = 0.3;

    return Card(
      key: ValueKey(point.id),
      // Crucial for ReorderableListView
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
      child: Stack(
        // Use Stack to overlay the "New" badge
        children: [
          ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelectedForDelete,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (bool? value) {
                      _togglePointSelection(point.id);
                    },
                  )
                : ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      // Add some padding around the handle for easier touch
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.drag_handle,
                        color: Theme.of(context).hintColor, // Subtle color
                      ),
                    ),
                  ),
            title: Text(
              '${point.name}: Alt: ${point.altitude?.toStringAsFixed(2) ?? '---'}\nLat: ${point.latitude.toStringAsFixed(5)}\nLon: ${point.longitude.toStringAsFixed(5)}',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.note.isEmpty
                      ? (S.of(context)?.noNote ?? 'No note')
                      : point.note,
                ),
                Builder(
                  builder: (context) {
                    final points = Provider.of<ProjectStateManager>(
                      context,
                      listen: false,
                    ).currentPoints;
                    double? distanceToLine;
                    if (points.length >= 2) {
                      final logic = MapControllerLogic(
                        project: Provider.of<ProjectStateManager>(
                          context,
                          listen: false,
                        ).currentProject!,
                      );
                      distanceToLine = logic.distanceFromPointToFirstLastLine(
                        point,
                        points,
                      );
                    }
                    String? distanceToLineStr;
                    if (distanceToLine != null) {
                      if (distanceToLine >= 1000) {
                        distanceToLineStr =
                            '${(distanceToLine / 1000).toStringAsFixed(2)} km';
                      } else {
                        distanceToLineStr =
                            '${distanceToLine.toStringAsFixed(1)} m';
                      }
                    }
                    if (distanceToLine == null || distanceToLine <= 0.0)
                      return SizedBox.shrink();
                    return Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 6),
                        Text(
                          S.of(context)?.offsetLabel ?? 'Offset:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          distanceToLineStr ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            trailing: !_isSelectionMode
                ? IconButton(
                    icon: const Icon(
                      Icons.edit_note_outlined,
                      color: Colors.blueGrey,
                    ),
                    tooltip: 'Edit Point',
                    onPressed: () {
                      _handlePointTap(point);
                    },
                  )
                : null,
            onTap: () => _handlePointTap(point),
            // ReorderableListView handles long press for drag if not in selection mode.
            // If you need specific long press logic, it might conflict or need careful handling.
            // For simplicity, we let ReorderableListView manage the drag on long press
            // via the ReorderableDragStartListener.
            onLongPress: _isSelectionMode
                ? () =>
                      _handlePointLongPress(
                        point,
                      ) // Allow long press toggle within selection mode
                : () {
                    // If not in selection mode, long press on ListTile body should enable it
                    // and select the item. Drag handle is separate.
                    _handlePointLongPress(point);
                  },
          ),
        ],
      ),
    );
  }

  // --- End Widget Building Helper Methods ---

  // --- Point Item Interaction Handlers ---
  Future<void> _handlePointTap(PointModel point) async {
    // Make it async
    if (_isSelectionMode) {
      _togglePointSelection(point.id);
    } else {
      // Non-selection mode tap: Navigate to detail page
      if (!mounted) return; // Guard against navigation if widget is disposed

      // Navigate to PointDetailsPage and wait for a result
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (context) => PointDetailsPage(point: point)),
      );

      if (result != null && mounted) {
        final String? action = result['action'] as String?;
        if (action == 'deleted' || action == 'updated') {
          // Do NOT reload points from DB; just let the Consumer rebuild from in-memory state
          // await _loadPoints();
        }
      }
    }
  }

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
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No points added yet.\nTap "Add Point" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add Point'),
                  onPressed: hasUnsavedNewPoint
                      ? null
                      : () => _handleAddPoint(),
                ),
              ),
            ],
          );
  }

  void _handleAddPoint() {
    // This should trigger the add point flow, e.g., open a dialog or navigate
    // For now, just show a message
    showInfoStatus('Add Point pressed');
  }
}
