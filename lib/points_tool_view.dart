// points_tool_view.dart
import 'package:flutter/material.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/logger.dart';

class PointsToolView extends StatefulWidget {
  final ProjectModel project;

  const PointsToolView({super.key, required this.project});

  @override
  State<PointsToolView> createState() => _PointsToolViewState();
}

class _PointsToolViewState extends State<PointsToolView> {
  late Future<List<PointModel>> _pointsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- State for Selection Mode ---
  bool _isSelectionMode = false;
  final Set<int> _selectedPointIds = {};
  // --- End State for Selection Mode ---

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  void _loadPoints() {
    if (widget.project.id == null) {
      logger.warning("PointsToolView: Project ID is null, cannot load points.");
      // TODO: Handle the case where project ID might be null (e.g., if it's a new, unsaved project)
      // For now, assign an empty list future.
      setState(() {
        _pointsFuture = Future.value([]);
      });
      return;
    }
    logger.info(
      "PointsToolView: Loading points for project ID: ${widget.project.id}",
    );
    // When reloading, ensure selection mode is reset if it doesn't make sense to keep it
    if (_isSelectionMode) {
      // Only clear if currently in selection mode
      _clearSelection();
    }
    setState(() {
      _pointsFuture = _dbHelper.getPointsForProject(widget.project.id!);
    });
  }

  void _clearSelection() {
    if (_isSelectionMode || _selectedPointIds.isNotEmpty) {
      // Check if there's anything to clear
      setState(() {
        _isSelectionMode = false;
        _selectedPointIds.clear();
      });
      logger.fine("Selection mode cleared.");
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        // _selectedPointIds.clear(); // Already handled by _clearSelection if called from close button
        _clearSelection(); // Use the helper here for consistency
      }
    });
  }

  void _togglePointSelection(int pointId) {
    setState(() {
      if (_selectedPointIds.contains(pointId)) {
        _selectedPointIds.remove(pointId);
        // If selection mode is active and becomes empty, optionally exit selection mode
        if (_isSelectionMode && _selectedPointIds.isEmpty) {
          // You could choose to automatically exit selection mode here:
          // _clearSelection();
          // Or leave it active until the user explicitly cancels.
          // For now, let's keep it active.
        }
      } else {
        _selectedPointIds.add(pointId);
        // If not in selection mode and an item is selected by some other means (e.g. programmatic)
        // ensure selection mode is activated. This is mostly handled by onLongPress.
        // if (!_isSelectionMode) {
        //   _isSelectionMode = true;
        // }
      }
    });
  }

  // Placeholder for adding a new point - we'll implement this later
  void _addNewPoint() {
    logger.info(
      "Add new point button tapped for project: ${widget.project.name}",
    );
    // TODO: Implement point creation dialog/logic
    // For now, let's simulate adding a point and refresh
    if (widget.project.id != null) {
      final newPoint = PointModel(
        projectId: widget.project.id!,
        // Replace with actual data later (e.g., from GPS or form)
        latitude: 45.0 + (DateTime.now().second / 100.0), // Dummy data
        longitude: 14.0 + (DateTime.now().minute / 100.0), // Dummy data
        ordinalNumber: 0, // This will need logic to determine the next ordinal
        note: "Test Point ${DateTime.now().toIso8601String()}",
      );
      _dbHelper
          .insertPoint(newPoint)
          .then((id) {
            logger.info("Simulated point added with ID: $id. Refreshing list.");
            _loadPoints(); // Refresh the list
          })
          .catchError((error, stackTrace) {
            logger.severe("Error inserting simulated point", error, stackTrace);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error adding point: $error"),
                backgroundColor: Colors.red,
              ),
            );
          });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Save the project first to add points."),
          backgroundColor: Colors.orange,
        ),
      );
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
            Text(
              'Points for: ${widget.project.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Point'),
              onPressed: _addNewPoint,
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
    try {
      final count = await _dbHelper.deletePointsByIds(
        _selectedPointIds.toList(),
      );
      logger.info('Successfully deleted $count points.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count point(s) deleted.'),
          backgroundColor: Colors.green,
        ),
      );
      // No need to call setState here for _isSelectionMode and _selectedPointIds
      // because _loadPoints() will be called, which now calls _clearSelection().
      // However, if _loadPoints wasn't guaranteed to clear it, you would do:
      // _clearSelection(); // Clear selection state
      _loadPoints(); // Refresh the list (this will also call _clearSelection)
    } catch (error, stackTrace) {
      logger.severe('Error deleting points', error, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting points: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // --- End Delete Logic ---

  @override
  Widget build(BuildContext context) {
    return Column(
      // Make this Column take only the space its children need
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // To make Cards fill width
      children: [
        _buildTopBar(context), // Use the dynamic top bar
        FutureBuilder<List<PointModel>>(
          future: _pointsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              logger.severe(
                "Error loading points: ${snapshot.error}",
                snapshot.error,
                snapshot.stackTrace,
              );
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No points added to this project yet.\nTap "Add Point" to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              );
            }

            final points = snapshot.data!;
            return ListView.builder(
              shrinkWrap:
                  true, // Important: Allows ListView to size itself to its content
              physics:
                  const NeverScrollableScrollPhysics(), // Important: Disables internal scrolling
              itemCount: points.length,
              itemBuilder: (context, index) {
                final point = points[index];
                final bool isSelected = _selectedPointIds.contains(point.id);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  color: isSelected
                      ? Theme.of(context).primaryColorLight.withOpacity(0.3)
                      : null, // Highlight selected
                  child: ListTile(
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              if (point.id != null) {
                                _togglePointSelection(point.id!);
                              }
                            },
                          )
                        : CircleAvatar(child: Text('${point.ordinalNumber}')),
                    title: Text(
                      'Lat: ${point.latitude.toStringAsFixed(5)}, Lon: ${point.longitude.toStringAsFixed(5)}',
                    ),
                    subtitle: Text(point.note ?? 'No note'),
                    trailing: !_isSelectionMode
                        ? IconButton(
                            icon: const Icon(
                              Icons.edit_note_outlined,
                              color: Colors.blueGrey,
                            ),
                            tooltip: 'Edit Point',
                            onPressed: () {
                              logger.info(
                                "Edit tapped for point ID: ${point.id}",
                              );
                              // TODO: Implement point editing
                            },
                          )
                        : null, // No trailing icon in selection mode, or maybe a different one
                    onTap: () {
                      if (_isSelectionMode) {
                        if (point.id != null) {
                          _togglePointSelection(point.id!);
                        }
                      } else {
                        // TODO: Implement point details view or selection
                        logger.info("Tapped on point ID: ${point.id}");
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          if (point.id != null) {
                            _selectedPointIds.add(point.id!);
                          }
                        });
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
