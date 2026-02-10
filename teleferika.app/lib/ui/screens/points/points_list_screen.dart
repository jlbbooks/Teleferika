// points_list_screen.dart
// Screen for displaying and managing a list of project points
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'components/point_item_card.dart';
import 'components/points_top_bar.dart';
import 'package:flutter/foundation.dart';

class PointsListScreen extends StatefulWidget {
  final ProjectModel project;
  final List<PointModel> points;

  const PointsListScreen({
    super.key,
    required this.project,
    required this.points,
  });

  @override
  State<PointsListScreen> createState() => PointsListScreenState();
}

class PointsListScreenState extends State<PointsListScreen> with StatusMixin {
  final Logger logger = Logger('PointsListScreen');

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
    // In debug mode, expand all cards after first frame
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final projectState = Provider.of<ProjectStateManager>(
          context,
          listen: false,
        );
        setState(() {
          _expandedPointIds.addAll(projectState.currentPoints.map((p) => p.id));
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize previous project data after dependencies are available
    _previousProject ??=
        context.projectStateListen.currentProject ?? widget.project;
  }

  @override
  void didUpdateWidget(PointsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if parent project start/end points changed using global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;

    if (_previousProject?.id != currentProject.id) {
      // Project changed, reload points
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
      logger.severe('Error loading points in PointsListScreen', e, stackTrace);
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

  /// Public method to access onProjectSaved functionality from parent
  void onProjectSaved() {
    // No backup to clear; nothing needed
  }

  // --- Action Bar for Normal and Selection Mode ---
  Widget _buildTopBar(BuildContext context) {
    return PointsTopBar(
      isSelectionMode: _isSelectionMode,
      selectedCount: _selectedPointIds.length,
      onCancel: _toggleSelectionMode,
      onDelete: _confirmDeleteSelectedPoints,
    );
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
        final success = projectState.deletePoint(pointId);
        if (!success) {
          logger.warning('Failed to delete point $pointId');
        }
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

        return SafeArea(
          child: Stack(
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
          ),
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
                      ? (int oldIndex, int newIndex) async {}
                      : _handleReorder,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    return PointItemCard(
                      key: ValueKey(point.id),
                      point: point,
                      index: index,
                      project: project,
                      isSelectionMode: _isSelectionMode,
                      isSelectedForDelete: _selectedPointIds.contains(point.id),
                      isExpanded: _expandedPointIds.contains(point.id),
                      onTap: () {
                        if (_isSelectionMode) {
                          _togglePointSelection(point.id);
                        }
                      },
                      onLongPress: () => _handlePointLongPress(point),
                      onToggleExpanded: () => _toggleExpanded(point.id),
                    );
                  },
                ),
              ),
            ],
          );
  }
}
