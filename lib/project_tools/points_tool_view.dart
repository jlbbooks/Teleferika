// points_tool_view.dart
import 'package:flutter/material.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/logger.dart';
import 'package:teleferika/point_details_page.dart';

class PointsToolView extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback? onPointsChanged; // Callback for when points are modified
  final String? newlyAddedPointId;

  const PointsToolView({
    super.key,
    required this.project,
    this.onPointsChanged, // Add to constructor
    this.newlyAddedPointId,
  });

  @override
  State<PointsToolView> createState() => PointsToolViewState();
}

class PointsToolViewState extends State<PointsToolView> {
  // We need to manage the list of points directly in the state for ReorderableListView
  List<PointModel> _points = []; // Holds the current list of points
  Future<void>? _loadPointsFuture; // To manage the initial loading state
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- State for Selection Mode ---
  bool _isSelectionMode = false;
  final Set<String> _selectedPointIds = {};
  // --- End State for Selection Mode ---

  @override
  void initState() {
    super.initState();
    _loadPointsFuture =
        _loadPoints(); // Initialize the future for FutureBuilder
  }

  // @override
  // void didUpdateWidget(PointsToolView oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // If the project ID changes, refetch points (might not be necessary if project instance is the same
  //   // and only its internal start/end IDs change, then a simple setState in parent might be enough)
  //   if (widget.project.id != oldWidget.project.id) {
  //     _loadPoints();
  //   }
  //   // If start/end points change on the *same* project, we might need a way to just rebuild
  //   // This is often handled by the parent calling setState which causes this child to rebuild.
  // }

  // Make _loadPoints return Future<void> and update _points
  Future<void> _loadPoints() async {
    if (widget.project.id == null) {
      if (mounted) setState(() => _points = []);
      return;
    }
    try {
      final pointsFromDb = await _dbHelper.getPointsForProject(
        widget.project.id!,
      );
      if (mounted) {
        setState(() {
          _points = pointsFromDb;
          // Ensure points are sorted by ordinal for ReorderableListView
          _points.sort((a, b) => (a.ordinalNumber).compareTo(b.ordinalNumber));
        });
      }
    } catch (e, stackTrace) {
      logger.severe("Error loading points in PointsToolView", e, stackTrace);
      if (mounted) {
        setState(() => _points = []); // Set to empty on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading points: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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

  // Future<void> _handleReorder(int oldIndex, int newIndex) async {
  //   if (widget.project.id == null) return;
  //
  //   // Adjust newIndex for ReorderableListView's behavior when moving down
  //   if (newIndex > oldIndex) {
  //     newIndex -= 1;
  //   }
  //
  //   // Prevent reordering outside bounds or if indexes are the same
  //   if (newIndex < 0 || newIndex >= _points.length || oldIndex == newIndex) {
  //     logger.fine(
  //       "Reorder attempt with invalid indices or no change: old $oldIndex, new $newIndex",
  //     );
  //     return;
  //   }
  //
  //   final PointModel itemMoved = _points.removeAt(oldIndex);
  //   _points.insert(newIndex, itemMoved);
  //
  //   // Now, create a new list of points with updated ordinal numbers based on their new positions
  //   List<PointModel> reorderedPointsWithNewOrdinals = [];
  //   for (int i = 0; i < _points.length; i++) {
  //     PointModel currentPoint = _points[i];
  //     if (currentPoint.ordinalNumber != i) {
  //       reorderedPointsWithNewOrdinals.add(
  //         currentPoint.copyWith(ordinalNumber: i),
  //       );
  //     } else {
  //       // If ordinal didn't change, we can add the original instance
  //       reorderedPointsWithNewOrdinals.add(currentPoint);
  //     }
  //   }
  //
  //   // Update the state's list of points to reflect these new immutable instances
  //   // This ensures that if the DB update fails and we revert, we revert to a consistent state.
  //   // And also that the UI reflects the intended ordinals.
  //   setState(() {
  //     _points = List.from(reorderedPointsWithNewOrdinals); // Create a new list
  //   });
  //
  //   logger.info(
  //     "Reordered point ${itemMoved.id} from index $oldIndex to $newIndex. Updating ordinals.",
  //   );
  //
  //   // --- Database Update ---
  //   // Create a list of PointModels that actually need their ordinals updated in the DB
  //   List<PointModel> pointsToUpdateInDB = [];
  //   for (PointModel point in _points) {
  //     // Iterate over the newly reordered _points list
  //     // We need to compare with the DB state.
  //     // A better way might be to only update ordinals in DB for points whose ordinal *actually* changed.
  //     // The current loop below implicitly does this by preparing a list.
  //     // The crucial part is that `point.ordinalNumber` now reflects the NEW desired ordinal.
  //     pointsToUpdateInDB.add(point); // Add all points in their new order
  //   }
  //
  //   if (pointsToUpdateInDB.isEmpty && _points.isNotEmpty) {
  //     logger.fine(
  //       "No ordinal changes detected for DB update, but ensuring start/end points are current.",
  //     );
  //   }
  //   // No, even if no ordinal changes, the start/end might have changed.
  //   // The previous logic was: `if (_points[i].ordinalNumber != i)`
  //   // which meant we were comparing the *current* model's ordinal to the *new* index.
  //   // Now, `_points` contains models whose ordinals *should already reflect the new index* if we updated them correctly in memory.
  //
  //   // Let's refine the list of points whose ordinals actually need DB updates
  //   // This requires comparing the new in-memory ordinal with what *was* in the DB
  //   // or simply updating all points in the new order.
  //   // The original logic `if (_points[i].ordinalNumber != i)` in the loop
  //   // was trying to update the local model.
  //   //
  //   // The `pointsToUpdateInDB` will be the points from `_points` list,
  //   // which now have their `ordinalNumber` field set to the new correct sequence (0, 1, 2...).
  //
  //   try {
  //     // Use a transaction to update all ordinals and then project start/end points
  //     final db = await _dbHelper.database;
  //     await db.transaction((txn) async {
  //       for (PointModel pointToUpdate in _points) {
  //         // Use the _points list directly
  //         // as it contains the models with new ordinals
  //         await txn.update(
  //           PointModel.tableName,
  //           {PointModel.columnOrdinalNumber: pointToUpdate.ordinalNumber},
  //           where: '${PointModel.columnId} = ?',
  //           whereArgs: [pointToUpdate.id],
  //         );
  //       }
  //       // After updating all point ordinals, update the project's start and end points
  //       await _dbHelper.updateProjectStartEndPoints(
  //         widget.project.id!,
  //         txn: txn,
  //       );
  //     });
  //
  //     logger.info(
  //       "Successfully updated ordinals and project start/end points after reorder.",
  //     );
  //     widget.onPointsChanged?.call(); // Notify parent
  //   } catch (e, stackTrace) {
  //     logger.severe(
  //       "Error updating database after reorder for project ${widget.project.id}",
  //       e,
  //       stackTrace,
  //     );
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error saving new point order: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //     // If DB update fails, revert the list in UI to previous state (reload from DB)
  //     // This is important to keep UI consistent with DB
  //     await _loadPoints();
  //   }
  // }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (widget.project.id == null) return;

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

    // 3. Update local list and prepare points with new ordinals
    final List<PointModel> reorderedPointsWithNewOrdinals =
        _getReorderedPointsWithNewOrdinals(oldIndex, adjustedNewIndex);

    // 4. Update UI state
    setState(() {
      _points = reorderedPointsWithNewOrdinals;
    });

    logger.info(
      "Reordered point from index $oldIndex to $adjustedNewIndex. Updating ordinals.",
    );

    // 5. Persist changes to the database
    await _updatePointOrdinalsInDatabase(reorderedPointsWithNewOrdinals);
  }

  /// Validates if the reorder operation is valid.
  bool _isValidReorder(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= _points.length || oldIndex == newIndex) {
      return false;
    }
    return true;
  }

  /// Reorders the local `_points` list and returns a new list
  /// where each `PointModel` has its `ordinalNumber` updated to match its new position.
  List<PointModel> _getReorderedPointsWithNewOrdinals(
    int oldIndex,
    int newIndex,
  ) {
    // Create a mutable copy to perform reorder operations
    List<PointModel> tempList = List.from(_points);

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
    if (widget.project.id == null) {
      return; // Should already be checked, but defensive
    }

    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        for (PointModel pointToUpdate in pointsToUpdate) {
          await txn.update(
            PointModel.tableName,
            {PointModel.columnOrdinalNumber: pointToUpdate.ordinalNumber},
            where: '${PointModel.columnId} = ?',
            whereArgs: [pointToUpdate.id],
          );
        }
        // After updating all point ordinals, update the project's start and end points
        await _dbHelper.updateProjectStartEndPoints(
          widget.project.id!,
          txn: txn,
        );
      });

      logger.info(
        "Successfully updated ordinals and project start/end points after reorder.",
      );
      widget.onPointsChanged?.call(); // Notify parent
    } catch (e, stackTrace) {
      logger.severe(
        "Error updating database after reorder for project ${widget.project.id}",
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving new point order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // If DB update fails, revert the list in UI to previous state (reload from DB)
      await _loadPoints();
    }
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
    if (_selectedPointIds.isEmpty || widget.project.id == null) return;

    try {
      final count = await _dbHelper.deletePointsByIds(
        _selectedPointIds.toList(),
      );
      logger.info('Successfully deleted $count points.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count point(s) deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _clearSelection();
      await _loadPoints(); // Reload points to reflect deletions and re-sequencing
      widget.onPointsChanged?.call();
    } catch (error, stackTrace) {
      logger.severe('Error deleting points', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting points: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // --- End Delete Logic ---

  /// Builds a single point item Card for the ListView.
  Widget _buildPointItem(BuildContext context, PointModel point, int index) {
    // index needed for Key
    final bool isSelectedForDelete = _selectedPointIds.contains(point.id);
    final Color baseSelectionColor = Theme.of(context).primaryColorLight;
    const double selectedOpacity = 0.3;

    bool isNewlyAdded =
        (widget.newlyAddedPointId != null &&
        widget.newlyAddedPointId == point.id);

    // --- Determine if it's a start or end point ---
    final bool isProjectStartPoint =
        point.id != null && point.id == widget.project.startingPointId;
    final bool isProjectEndPoint =
        point.id != null && point.id == widget.project.endingPointId;
    String? specialRoleText;
    Color? specialRoleColor;
    Color cardHighlightColor = Theme.of(context).cardColor; // Default
    BorderSide cardBorder = BorderSide.none;

    if (isProjectStartPoint && isProjectEndPoint) {
      specialRoleText = "Start & End Point";
      specialRoleColor = Colors.purpleAccent.shade700;
      cardHighlightColor = Colors.purple.shade50.withAlpha(
        ((1 - selectedOpacity) * 255).round(),
      );
      cardBorder = BorderSide(color: Colors.purpleAccent.shade400, width: 2.0);
    } else if (isProjectStartPoint) {
      specialRoleText = "Start Point";
      specialRoleColor = Colors.green.shade700;
      cardHighlightColor = Colors.green.shade50.withAlpha(
        ((1 - selectedOpacity) * 255).round(),
      );
      cardBorder = BorderSide(color: Colors.green.shade400, width: 2.0);
    } else if (isProjectEndPoint) {
      specialRoleText = "End Point";
      specialRoleColor = Colors.red.shade700;
      cardHighlightColor = Colors.red.shade50.withAlpha(
        ((1 - selectedOpacity) * 255).round(),
      );
      cardBorder = BorderSide(color: Colors.red.shade400, width: 2.0);
    }
    // --- MODIFICATION END ---

    return Card(
      key: ValueKey(point.id ?? index), // Crucial for ReorderableListView
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      elevation: _isSelectionMode && isSelectedForDelete
          ? 4.0
          : (isProjectStartPoint || isProjectEndPoint ? 3.0 : 1.0),
      shape: RoundedRectangleBorder(
        side: _isSelectionMode && isSelectedForDelete
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
            : cardBorder, // Apply special border if start/end point
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: _isSelectionMode && isSelectedForDelete
          ? baseSelectionColor.withAlpha((selectedOpacity * 255).round())
          : (isProjectStartPoint || isProjectEndPoint
                ? cardHighlightColor
                : null), // Apply special background
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
              'P${point.ordinalNumber}: Alt: ${point.altitude?.toStringAsFixed(2) ?? '---'}\nLat: ${point.latitude.toStringAsFixed(5)}\nLon: ${point.longitude.toStringAsFixed(5)}',
            ),
            subtitle: Column(
              // Use Column to add special role text if present
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.note ?? 'No note'),
                if (specialRoleText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      specialRoleText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            specialRoleColor ??
                            Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
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
          if (isNewlyAdded)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green, // "New" badge color
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
        "Tapped on point ID: ${point.id} (P${point.ordinalNumber}). Navigating to details.",
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
          // Refresh the points list
          // You might have a more specific way to update if 'updated' returns the point
          // For simplicity, just refresh the whole list for now.
          // TODO: only act on the updated point
          _loadPoints();
          // Optionally, if you want to notify the overall project page too:
          widget.onPointsChanged?.call();
        }
      }
    }
  }

  void _handlePointLongPress(PointModel point) {
    if (point.id == null) return;

    setState(() {
      if (!_isSelectionMode) {
        // If not in selection mode, enter it and select the current item
        _isSelectionMode = true;
        _selectedPointIds.add(point.id!);
        logger.fine(
          "Long press initiated selection mode for point ID: ${point.id}",
        );
      } else {
        // If already in selection mode, just toggle the selection of the current item
        _togglePointSelection(point.id!);
        logger.fine(
          "Long press in selection mode, toggled point ID: ${point.id}",
        );
      }
    });
  }
  // --- End Point Item Interaction Handlers ---

  @override
  Widget build(BuildContext context) {
    logger.finest(
      "PointsToolView build method called. Selection mode: $_isSelectionMode, Points count: ${_points.length}",
    );
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(context),
        Expanded(
          child: FutureBuilder<void>(
            future: _loadPointsFuture, // Use the future for initial load
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _points.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError && _points.isEmpty) {
                // Error already logged in _loadPoints, SnackBar shown there
                return Center(
                  child: Text(
                    'Error loading points. Please try again.\n${snapshot.error.toString()}',
                  ),
                );
              }

              if (_points.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No points added to this project yet.\nTap "Add Point" to get started!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                );
              }

              // Once points are loaded (or if already loaded), display ReorderableListView
              return ReorderableListView.builder(
                // physics:
                //     const NeverScrollableScrollPhysics(), // If inside another scrollable
                itemCount: _points.length,
                itemBuilder: (context, index) {
                  final point = _points[index];
                  // Pass index for ReorderableDragStartListener and Key
                  return _buildPointItem(context, point, index);
                },
                // Disable reordering if in selection mode
                onReorder: _isSelectionMode
                    ? (int oldI, int newI) {}
                    : _handleReorder,
                // Optional: Customize drag feedback
                // TODO: proxyDecorator: (Widget child, int index, Animation<double> animation) {
                //   return Material(
                //     elevation: 4.0,
                //     color: Colors.transparent, // Or some highlight color
                //     child: child,
                //   );
                // },
              );
            },
          ),
        ),
      ],
    );
  }
}
