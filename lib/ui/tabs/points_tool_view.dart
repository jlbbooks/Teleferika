// points_tool_view.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/ui/pages/point_details_page.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

class PointsToolView extends StatefulWidget {
  final ProjectModel project;

  const PointsToolView({
    super.key,
    required this.project,
  });

  @override
  State<PointsToolView> createState() => PointsToolViewState();
}

class PointsToolViewState extends State<PointsToolView> with StatusMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger logger = Logger('PointsToolView');

  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedPointIds = {};

  // Undo functionality
  List<PointModel>? _originalPointsBackup;
  bool _hasUnsavedChanges = false;
  
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
    if (_previousProject == null) {
      _previousProject = context.projectStateListen.currentProject ?? widget.project;
    }
  }

  @override
  void didUpdateWidget(PointsToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if parent project start/end points changed using global state
    final currentProject = context.projectStateListen.currentProject ?? widget.project;
    
    if (_previousProject?.startingPointId != currentProject.startingPointId ||
        _previousProject?.endingPointId != currentProject.endingPointId) {
      logger.info(
        "Parent project start/end points changed, refreshing from global state",
      );
      logger.info(
        "Parent: start=${currentProject.startingPointId}, end=${currentProject.endingPointId}",
      );
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
      final projectState = Provider.of<ProjectStateManager>(context, listen: false);
      await projectState.refreshPoints();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Clear any existing backup when loading fresh data
        clearBackup();
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
    logger.info("PointsToolView: External refresh requested.");
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
      logger.fine(
        "Reorder attempt with invalid indices or no change: old $oldIndex, new $adjustedNewIndex (adjusted from $newIndex)",
      );
      return;
    }

    // 3. Get current project from global state and create backup before making changes
    final projectState = Provider.of<ProjectStateManager>(context, listen: false);
    final currentProject = projectState.currentProject ?? widget.project;
    
    // Create backup before making changes
    createBackup();

    // 4. Get current points from global state
    final currentPoints = projectState.currentPoints;
    final List<PointModel> reorderedPointsWithNewOrdinals =
        _getReorderedPointsWithNewOrdinals(
          currentPoints,
          oldIndex,
          adjustedNewIndex,
        );

    logger.info(
      "Reordered point from index $oldIndex to $adjustedNewIndex. Updating ordinals.",
    );

    // 5. Persist changes to the database using global state
    await _updatePointOrdinalsInDatabase(reorderedPointsWithNewOrdinals);
  }

  /// Validates if the reorder operation is valid.
  bool _isValidReorder(int oldIndex, int newIndex) {
    final projectState = Provider.of<ProjectStateManager>(context, listen: false);
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
    // Create a mutable copy to perform reorder operations
    List<PointModel> tempList = List.from(points);

    final PointModel itemMoved = tempList.removeAt(oldIndex);
    tempList.insert(newIndex, itemMoved);

    // Create the final list with updated ordinals
    List<PointModel> resultList = [];
    for (int i = 0; i < tempList.length; i++) {
      PointModel currentPoint = tempList[i];
      if (currentPoint.ordinalNumber != i) {
        resultList.add(currentPoint.copyWith(ordinalNumber: i));
      } else {
        resultList.add(currentPoint); // No change needed, use original instance
      }
    }
    return resultList;
  }

  /// Updates the ordinal numbers of the given points in the database
  /// within a transaction and also updates the project's start/end points.
  Future<void> _updatePointOrdinalsInDatabase(
    List<PointModel> pointsToUpdate,
  ) async {
    final projectState = Provider.of<ProjectStateManager>(context, listen: false);
    final currentProject = projectState.currentProject ?? widget.project;
    if (currentProject.id == null) {
      return; // Should already be checked, but defensive
    }

    try {
      final db = await _dbHelper.database;

      // Single transaction: Update ordinals based on the reordered points AND update start/end points
      await db.transaction((txn) async {
        // First: Update ordinals based on the actual reordered points
        for (int i = 0; i < pointsToUpdate.length; i++) {
          final point = pointsToUpdate[i];
          logger.info("Updating point ${point.id} to ordinal $i");
          await txn.update(
            PointModel.tableName,
            {PointModel.columnOrdinalNumber: i},
            where: '${PointModel.columnId} = ?',
            whereArgs: [point.id],
          );
        }

        // Second: Update start/end points within the SAME transaction
        // This ensures it sees the updated ordinals
        await _dbHelper.updateProjectStartEndPoints(
          currentProject.id!,
          txn: txn,
        );
      });

      logger.info(
        "Successfully updated ordinals and project start/end points after reorder.",
      );

      // Refresh global state to get updated project data with new start/end points
      await projectState.refreshPoints();
    } catch (e, stackTrace) {
      logger.severe(
        "Error updating database after reorder for project ${currentProject.id}",
        e,
        stackTrace,
      );
      if (mounted) {
        showErrorStatus('Error saving new point order: ${e.toString()}');
      }
      // If DB update fails, revert the list in UI to previous state (reload from DB)
      await _loadPoints();
    }
  }

  /// Creates a backup of the current points list for undo functionality
  void createBackup() {
    if (_originalPointsBackup == null) {
      _originalPointsBackup = List.from(context.projectState.currentPoints);
      _hasUnsavedChanges = true;
      logger.info(
        "Created backup of ${_originalPointsBackup!.length} points for undo",
      );
    }
  }

  /// Restores the original points list and clears the backup
  Future<void> undoChanges() async {
    if (_originalPointsBackup != null) {
      logger.info(
        "Undoing changes - restoring ${_originalPointsBackup!.length} points",
      );

      final projectState = Provider.of<ProjectStateManager>(context, listen: false);
      final currentProject = projectState.currentProject ?? widget.project;

      // Restore the original points in the database
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        // Clear all current points for this project
        await txn.delete(
          'points',
          where: 'project_id = ?',
          whereArgs: [currentProject.id],
        );

        // Insert the original points back
        for (int i = 0; i < _originalPointsBackup!.length; i++) {
          final point = _originalPointsBackup![i];
          await txn.insert(
            'points',
            point.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Update project start/end points
        await _dbHelper.updateProjectStartEndPoints(
          currentProject.id!,
          txn: txn,
        );
      });

      // Refresh global state
      await projectState.refreshPoints();

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Clear the backup
      _originalPointsBackup = null;

      logger.info("Changes undone successfully");
    }
  }

  /// Clears the backup when project is saved
  void clearBackup() {
    if (_originalPointsBackup != null) {
      _originalPointsBackup = null;
      _hasUnsavedChanges = false;
      logger.info("Cleared backup after project save");
    }
  }

  /// Public method to clear backup when project is saved
  void onProjectSaved() {
    clearBackup();
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
      // Normal top bar
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Points:', style: Theme.of(context).textTheme.titleLarge),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Point'),
              onPressed: null, // TODO: _addNewPoint,
            ),
          ],
        ),
      );
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

    // Get current project from global state and create backup before deletion
    final projectState = Provider.of<ProjectStateManager>(context, listen: false);
    final currentProject = projectState.currentProject ?? widget.project;
    
    // Create backup before making changes
    createBackup();

    try {
      // Delete points using global state
      for (String pointId in _selectedPointIds) {
        await projectState.deletePoint(pointId);
      }

      logger.info('Successfully deleted ${_selectedPointIds.length} points.');
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
  Widget _buildPointItem(BuildContext context, PointModel point, int index, ProjectModel project) {
    // index needed for Key
    final bool isSelectedForDelete = _selectedPointIds.contains(point.id);
    final Color baseSelectionColor = Theme.of(context).primaryColorLight;
    const double selectedOpacity = 0.3;

    return Card(
      key: ValueKey(point.id ?? index), // Crucial for ReorderableListView
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
                      if (point.id != null) _togglePointSelection(point.id!);
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
            subtitle: Text(point.note.isEmpty ? 'No note' : point.note),
            trailing: !_isSelectionMode
                ? IconButton(
                    icon: const Icon(
                      Icons.edit_note_outlined,
                      color: Colors.blueGrey,
                    ),
                    tooltip: 'Edit Point',
                    onPressed: () {
                      logger.info("Edit tapped for point ID: ${point.id}");
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
      if (point.id != null) {
        _togglePointSelection(point.id!);
      }
    } else {
      // Non-selection mode tap: Navigate to detail page
      logger.info(
        "Tapped on point ID: ${point.id} (${point.name}). Navigating to details.",
      );
      if (!mounted) return; // Guard against navigation if widget is disposed

      // Navigate to PointDetailsPage and wait for a result
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (context) => PointDetailsPage(point: point)),
      );

      if (result != null && mounted) {
        final String? action = result['action'] as String?;
        if (action == 'deleted' || action == 'updated') {
          logger.info(
            "PointDetailsPage returned action: $action. Refreshing points list.",
          );
          // Refresh both points and project data
          await _loadPoints();
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
        logger.fine(
          "Long press initiated selection mode for point ID: ${point.id}",
        );
      } else {
        // If already in selection mode, just toggle the selection of the current item
        _togglePointSelection(point.id);
        logger.fine(
          "Long press in selection mode, toggled point ID: ${point.id}",
        );
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
        
        logger.fine(
          "PointsToolView Consumer rebuild - Project start: ${currentProject.startingPointId}, end: ${currentProject.endingPointId}",
        );
        
        return Stack(
          children: [
            Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPointsList(context, currentProject),
                ),
              ],
            ),
            Positioned(
              top: 24,
              right: 24,
              child: StatusIndicator(status: currentStatus, onDismiss: hideStatus),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsList(BuildContext context, ProjectModel project) {
    // Get points from global state
    final points = context.projectStateListen.currentPoints;

    logger.finest(
      "PointsToolView build method called. Selection mode: $_isSelectionMode, Points count: ${points.length}",
    );
    return points.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No points added yet.\nTap "Add Point" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : ReorderableListView.builder(
            itemCount: points.length,
            onReorder: _isSelectionMode
                ? (int oldI, int newI) {}
                : _handleReorder,
            itemBuilder: (context, index) {
              final point = points[index];
              return _buildPointItem(context, point, index, project);
            },
          );
  }
}
