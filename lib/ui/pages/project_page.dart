// project_details_page.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/licensing/licensed_features_loader.dart';
import 'package:teleferika/ui/tabs/compass_tool_view.dart';
import 'package:teleferika/ui/tabs/map_tool_view.dart';
import 'package:teleferika/ui/tabs/points_tab.dart';
import 'package:teleferika/ui/tabs/points_tool_view.dart';
import 'package:teleferika/ui/tabs/project_details_tab.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

enum ProjectPageTab {
  details, // 0
  points, // 1
  compass, // 2
  map, // 3
  // Add more tabs here if needed
}

// Helper function to convert degrees to radians
double _degreesToRadians(double degrees) {
  return degrees * math.pi / 180.0;
}

// Helper function to convert radians to degrees
double _radiansToDegrees(double radians) {
  return radians * 180.0 / math.pi;
}

/// Calculates the initial bearing (azimuth) from a start point to an end point.
/// Returns the bearing in degrees (0-360).
double calculateBearingFromPoints(PointModel startPoint, PointModel endPoint) {
  final double lat1Rad = _degreesToRadians(startPoint.latitude);
  final double lon1Rad = _degreesToRadians(startPoint.longitude);
  final double lat2Rad = _degreesToRadians(endPoint.latitude);
  final double lon2Rad = _degreesToRadians(endPoint.longitude);

  final double dLon = lon2Rad - lon1Rad;

  final double y = math.sin(dLon) * math.cos(lat2Rad);
  final double x =
      math.cos(lat1Rad) * math.sin(lat2Rad) -
      math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

  double bearingRad = math.atan2(y, x);
  double bearingDeg = _radiansToDegrees(bearingRad);

  // Normalize to 0-360 degrees
  return (bearingDeg + 360) % 360;
}

class ProjectPage extends StatefulWidget {
  final ProjectModel project;
  final bool isNew;

  const ProjectPage({super.key, required this.project, required this.isNew});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage>
    with TickerProviderStateMixin, StatusMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;

  bool _isLoading = false;
  bool _isEffectivelyNew = true;

  final GlobalKey<PointsToolViewState> _pointsToolViewKey =
      GlobalKey<PointsToolViewState>();

  bool _projectWasSuccessfullySaved = false;

  final LicenceService _licenceService =
      LicenceService.instance; // Get instance

  // Add a GlobalKey to access the ProjectDetailsTab state
  final GlobalKey<ProjectDetailsTabState> _detailsTabKey =
      GlobalKey<ProjectDetailsTabState>();

  // Add a GlobalKey to access the PointsTab state
  final GlobalKey<PointsTabState> _pointsTabKey = GlobalKey<PointsTabState>();

  // GlobalKey to access MapToolView methods
  final GlobalKey<MapToolViewState> _mapTabKey = GlobalKey<MapToolViewState>();

  // Store reference to ProjectStateManager for safe disposal
  ProjectStateManager? _projectStateManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to ProjectStateManager for safe disposal
    _projectStateManager = context.projectState;
  }

  @override
  void initState() {
    super.initState();
    _isEffectivelyNew = widget.isNew;
    _projectDate =
        widget.project.date ?? (widget.isNew ? DateTime.now() : null);
    _lastUpdateTime = widget.project.lastUpdate;

    _tabController = TabController(
      length: ProjectPageTab.values.length,
      vsync: this,
    );

    // Add listener to detect tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Tab is about to change
      } else if (_tabController.index != _tabController.previousIndex) {
        // Tab has changed
        // Dismiss keyboard when switching tabs
        FocusScope.of(context).unfocus();
        // Trigger rebuild to show/hide save button based on current tab
        setState(() {});
      }
    });

    // Defer global state loading until after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isNew) {
        _insertNewProjectToDb();
      } else {
        _loadProjectIntoGlobalState();
      }
    });
  }

  Future<void> _insertNewProjectToDb() async {
    // Insert the new project into the DB so points can be added
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.insertProject(widget.project);
    // Optionally reload from DB to get any DB-generated fields
    final dbProject = await dbHelper.getProjectById(widget.project.id);
    if (dbProject != null && mounted) {
      setState(() {
        _isEffectivelyNew = true;
      });
      // Load into global state after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadProjectIntoGlobalState();
        }
      });
    }
  }

  Future<void> _loadProjectIntoGlobalState() async {
    setState(() => _isLoading = true);
    try {
      await context.projectState.loadProject(widget.project.id);
      if (mounted) {
        setState(() {
          _projectDate = context.projectState.currentProject?.date;
          _lastUpdateTime = context.projectState.currentProject?.lastUpdate;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProjectFromDb() async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.deleteProject(widget.project.id);
  }

  @override
  void dispose() {
    // Don't clear global state here - it will be automatically updated
    // when the next project is loaded, and clearing during dispose causes
    // widget tree lock issues
    super.dispose();
  }

  Future<bool?> _saveProject() async {
    if (_isLoading) return null;
    
    // Check if we're on the details tab and validate the form
    if (_tabController.index == ProjectPageTab.details.index) {
      final detailsTabState = _detailsTabKey.currentState;
      if (detailsTabState != null && !detailsTabState.validateForm()) {
        showErrorStatus('Please correct the errors in the form before saving.');
        return false;
      }
      // Dismiss keyboard when saving from details tab
      detailsTabState?.dismissKeyboard();
    }
    
    setState(() => _isLoading = true);
    try {
      final saved = await context.projectState.saveProject();

      if (saved) {
        setState(() {
          _isEffectivelyNew = false;
          _projectWasSuccessfullySaved = true;
          _lastUpdateTime = context.projectState.currentProject?.lastUpdate;
        });

        showSuccessStatus('Project saved successfully');
        return true;
      } else {
        showErrorStatus('Error saving project');
        return false;
      }
    } catch (e) {
      if (mounted) {
        showErrorStatus('Error saving project: $e');
      }
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Undo changes by reloading the project and points from the DB
  Future<void> _undoChanges() async {
    await context.projectState.undoChanges();
  }

  void _handleOnPopInvokedWithResult(bool didPop, Object? result) async {
    if (didPop) return;
    if (_isEffectivelyNew && !_projectWasSuccessfullySaved) {
      // Delete the project from DB if it was never saved
      await _deleteProjectFromDb();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (context.projectState.hasUnsavedChanges) {
      final s = S.of(context);
      final bool? shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s?.unsaved_changes_title ?? 'Unsaved Changes'),
          content: Text(
            s?.unsaved_changes_discard_message ??
                'You have unsaved changes. Do you want to discard them and leave?',
          ),
          actions: [
            TextButton(
              child: Text(s?.dialog_cancel ?? 'Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(s?.discard_button_label ?? 'Discard'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (shouldPop == true) {
        if (mounted) {
          if (_projectWasSuccessfullySaved) {
            Navigator.of(
              context,
            ).pop({'action': 'saved', 'id': widget.project.id});
          } else {
            Navigator.of(context).pop();
          }
        }
      }
    } else {
      // Pop with 'saved' if project was ever saved, otherwise 'navigated_back'
      if (mounted && _projectWasSuccessfullySaved) {
        Navigator.of(context).pop({'action': 'saved', 'id': widget.project.id});
      } else if (mounted && !_isEffectivelyNew) {
        Navigator.of(
          context,
        ).pop({'action': 'navigated_back', 'id': widget.project.id});
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _confirmDeleteProject() async {
    final s = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(s?.delete_project_tooltip ?? 'Delete Project'),
          content: Text(
            s?.confirm_delete_project_content(widget.project.name) ??
                'Are you sure you want to delete the project "${widget.project.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(s?.buttonCancel ?? 'Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                s?.buttonDelete ?? 'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _deleteProjectFromDb();
        if (mounted) {
          showSuccessStatus(
            s?.project_deleted_successfully ?? 'Project deleted',
          );
          Navigator.of(
            context,
          ).pop({'action': 'deleted', 'id': widget.project.id});
        }
      } catch (e) {
        if (mounted) {
          showErrorStatus(
            s?.error_deleting_project(e.toString()) ??
                'Error deleting project: $e',
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleExport() async {
    final s = S.of(context);
    final currentProject = context.projectState.currentProject;
    final currentPoints = context.projectState.currentPoints;

    // Check if export feature is available
    if (!LicensedFeaturesLoader.hasLicensedFeature('export_widget')) {
      // Show upgrade dialog for opensource version
      LicensedFeaturesLoader.showExportUpgradeDialog(context);
      return;
    }

    // Check if licence is valid
    final licenceStatus = await _licenceService.getLicenceStatus();
    if (!licenceStatus['isValid']) {
      showErrorStatus(
        s?.exportRequiresValidLicence ?? 'Valid licence required for export',
      );
      return;
    }

    // Check if project has points to export
    if (currentPoints.isEmpty) {
      showErrorStatus(s?.errorExportNoPoints ?? 'No points to export');
      return;
    }

    try {
      showLoadingStatus(s?.infoExporting ?? 'Exporting...');

      final success = await LicensedFeaturesLoader.showExportDialog(
        context,
        currentProject ?? widget.project,
        currentPoints,
        onExportComplete: (bool success) {
          if (success) {
            showSuccessStatus(
              s?.exportSuccess ?? 'Project exported successfully',
            );
          } else {
            showErrorStatus(s?.exportError ?? 'Export error');
          }
        },
      );

      if (!success) {
        hideStatus();
      }
    } catch (e) {
      hideStatus();
      showErrorStatus(
        s?.exportErrorWithDetails(e.toString()) ?? 'Export error: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final orientation = MediaQuery.of(context).orientation;
    final saveButtonColor = context.projectState.hasUnsavedChanges
        ? Colors.green
        : null;

    // Use global state for project data
    final currentProject = context.projectStateListen.currentProject;
    final currentPoints = context.projectStateListen.currentPoints;

    // Calculate real total length directly from global state
    final currentRealTotalLength = _calculateRealTotalLength(currentPoints);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabIconColor = isDark ? Colors.teal[900] : Colors.blue[900];
    final tabTextColor = isDark ? Colors.teal[900] : Colors.blue[900];

    Widget tabBarViewWidget = TabBarView(
      controller: _tabController,
      children: [
        ProjectDetailsTab(
          key: _detailsTabKey,
          project: currentProject ?? widget.project,
          isNew: _isEffectivelyNew,
          pointsCount: currentPoints.length,
        ),
        PointsTab(
          key: _pointsTabKey,
          project: currentProject ?? widget.project,
        ),
        CompassToolView(),
        MapToolView(key: _mapTabKey, project: currentProject ?? widget.project),
      ],
    );
    List<Widget> tabWidgets = [
      Tab(
        icon: Icon(Icons.info_outline, color: tabIconColor),
        child: Text(
          s?.details_tab_label ?? "Details",
          style: TextStyle(color: tabTextColor),
        ),
      ),
      Tab(
        icon: Icon(Icons.list_alt_outlined, color: tabIconColor),
        child: Text(
          s?.points_tab_label ?? "Points",
          style: TextStyle(color: tabTextColor),
        ),
      ),
      Tab(
        icon: Icon(Icons.explore_outlined, color: tabIconColor),
        child: Text(
          s?.compass_tab_label ?? "Compass",
          style: TextStyle(color: tabTextColor),
        ),
      ),
      Tab(
        icon: Icon(Icons.map_outlined, color: tabIconColor),
        child: Text(
          s?.map_tab_label ?? "Map",
          style: TextStyle(color: tabTextColor),
        ),
      ),
    ];
    List<Widget> tabBarActions = [
      if (!_isEffectivelyNew)
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: _isLoading ? null : _confirmDeleteProject,
          tooltip: s?.delete_project_tooltip ?? 'Delete Project',
        ),
      if (!_isEffectivelyNew && currentPoints.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.file_download, color: Colors.blue),
          onPressed: _isLoading ? null : _handleExport,
          tooltip: s?.export_project_tooltip ?? 'Export Project',
        ),
      if (context.projectState.hasUnsavedChanges)
        IconButton(
          icon: const Icon(Icons.undo, color: Colors.orange),
          onPressed: _isLoading ? null : _undoChanges,
          tooltip: 'Undo Changes',
        ),
      if (context.projectState.hasUnsavedChanges)
        IconButton(
          icon: Icon(Icons.save, color: saveButtonColor),
          onPressed: _isLoading
              ? null
              : () async {
                  await _saveProject();
                },
          tooltip: s?.save_project_tooltip ?? 'Save Project',
        ),
    ];
    if (orientation == Orientation.portrait) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  currentProject?.name ?? widget.project.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: tabBarActions,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: tabWidgets,
          ),
        ),
        body: Stack(
          children: [
            PopScope(
              canPop: false,
              onPopInvokedWithResult: _handleOnPopInvokedWithResult,
              child: tabBarViewWidget,
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
    } else {
      // Horizontal layout (similar logic)
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  currentProject?.name ?? widget.project.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: tabBarActions,
        ),
        body: Stack(
          children: [
            PopScope(
              canPop: false,
              onPopInvokedWithResult: _handleOnPopInvokedWithResult,
              child: Row(
                children: <Widget>[
                  Material(
                    elevation: 4.0,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        indicatorWeight: 2.0,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: EdgeInsets.fromLTRB(0.0, 8, 0, 8),
                        tabs: tabWidgets
                            .map(
                              (tab) => RotatedBox(quarterTurns: 1, child: tab),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Expanded(child: tabBarViewWidget),
                ],
              ),
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
    }
  }

  double _calculateRealTotalLength(List<PointModel> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += _distanceBetween(points[i - 1], points[i]);
    }
    return total;
  }

  double _distanceBetween(PointModel a, PointModel b) {
    const double R = 6371000;
    final double lat1 = _degreesToRadians(a.latitude);
    final double lon1 = _degreesToRadians(a.longitude);
    final double lat2 = _degreesToRadians(b.latitude);
    final double lon2 = _degreesToRadians(b.longitude);
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    final double h =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(lat1) *
            math.cos(lat2) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return R * c;
  }
}
