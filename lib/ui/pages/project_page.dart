// project_details_page.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:teleferika/core/logger.dart';
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
import 'package:teleferika/ui/test/project_state_test_widget.dart';
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
    with SingleTickerProviderStateMixin, StatusMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;

  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isEffectivelyNew = true;

  // Undo functionality
  List<PointModel>? _originalPointsBackup;
  bool _hasPointsChanges = false;

  final GlobalKey<PointsToolViewState> _pointsToolViewKey =
      GlobalKey<PointsToolViewState>();

  bool _isAddingPointFromCompassInProgress = false;
  bool _projectWasSuccessfullySaved = false;

  final LicenceService _licenceService =
      LicenceService.instance; // Get instance

  double? realTotalLength;
  bool _pendingDeleteOnPop = false;

  // Store the updated project data from ProjectDetailsTab
  ProjectModel? _updatedProjectData;

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
    realTotalLength = _calculateRealTotalLength(widget.project.points);

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
          realTotalLength = _calculateRealTotalLength(
            context.projectState.currentPoints,
          );
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

  Future<bool?> _saveProject(ProjectModel updated) async {
    if (_isLoading) return null;
    setState(() => _isLoading = true);
    try {
      final projectToSave = updated.copyWith(
        date: _projectDate,
        lastUpdate: DateTime.now(),
      );

      // Use global state to update the project
      await context.projectState.updateProject(projectToSave);

      // Refresh points to ensure any changes from other parts of the app are reflected
      await context.projectState.refreshPoints();

      setState(() {
        _isEffectivelyNew = false;
        _projectWasSuccessfullySaved = true;
        _hasUnsavedChanges = false;
        _lastUpdateTime = projectToSave.lastUpdate;
        realTotalLength = _calculateRealTotalLength(context.projectState.currentPoints);
        _updatedProjectData = null; // Clear the updated project data after saving
      });

      // Clear undo backup in PointsToolView
      _pointsTabKey.currentState?.onProjectSaved();
      _clearPointsBackup();
      showSuccessStatus('Project saved successfully');

      return true;
    } catch (e) {
      if (mounted) {
        showErrorStatus('Error saving project: $e');
      }
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onProjectDetailsChanged(
    ProjectModel updated, {
    bool hasUnsavedChanges = false,
  }) {
    logger.info(
      "_onProjectDetailsChanged called with hasUnsavedChanges: $hasUnsavedChanges",
    );
    logger.info("Previous _hasUnsavedChanges: $_hasUnsavedChanges");
    setState(() {
      _hasUnsavedChanges = hasUnsavedChanges;
      _updatedProjectData = updated; // Store the updated project data
    });
    logger.info("New _hasUnsavedChanges: $_hasUnsavedChanges");
  }

  /// Creates a backup of the current points list for undo functionality
  void _createPointsBackup() {
    if (_originalPointsBackup == null) {
      _originalPointsBackup = List.from(context.projectState.currentPoints);
      _hasPointsChanges = true;
      logger.info(
        "Created backup of ${_originalPointsBackup!.length} points for undo",
      );
    }
  }

  /// Restores the original points list and clears the backup
  Future<void> _undoPointsChanges() async {
    if (_originalPointsBackup != null) {
      logger.info(
        "Undoing points changes - restoring ${_originalPointsBackup!.length} points",
      );

      try {
        // Restore the original points in the database
        final dbHelper = DatabaseHelper.instance;
        final db = await dbHelper.database;
        await db.transaction((txn) async {
          // Clear all current points for this project
          await txn.delete(
            'points',
            where: 'project_id = ?',
            whereArgs: [widget.project.id],
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
          await dbHelper.updateProjectStartEndPoints(
            widget.project.id!,
            txn: txn,
          );
        });

        // Refresh global state
        await context.projectState.refreshPoints();

        setState(() {
          _hasPointsChanges = false;
          _hasUnsavedChanges = false;
          realTotalLength = _calculateRealTotalLength(
            context.projectState.currentPoints,
          );
        });

        // Clear the backup
        _originalPointsBackup = null;

        // Refresh the PointsToolView to show the restored points and update colors
        _pointsTabKey.currentState?.refreshPoints();

        logger.info("Points changes undone successfully");
      } catch (e, stackTrace) {
        logger.severe("Error undoing points changes", e, stackTrace);
        if (mounted) {
          showErrorStatus('Error undoing changes: $e');
        }
      }
    }
  }

  /// Clears the backup when project is saved
  void _clearPointsBackup() {
    if (_originalPointsBackup != null) {
      _originalPointsBackup = null;
      _hasPointsChanges = false;
      logger.info("Cleared points backup after project save");
    }
  }

  void _handleOnPopInvokedWithResult(bool didPop, Object? result) async {
    if (didPop) return;
    if (_isEffectivelyNew && !_projectWasSuccessfullySaved) {
      // Delete the project from DB if it was never saved
      await _deleteProjectFromDb();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (_hasUnsavedChanges) {
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

  void _calculateAzimuth() {
    final s = S.of(context);
    final currentPoints = context.projectState.currentPoints;
    if (currentPoints.length < 2) {
      showErrorStatus(
        s?.errorAzimuthPointsNotSet ?? 'At least two points are required',
      );
      return;
    }
    final startPoint = currentPoints.first;
    final endPoint = currentPoints.last;
    if (startPoint.id == endPoint.id) {
      showErrorStatus(
        s?.errorAzimuthPointsSame ?? 'Start and end points must be different',
      );
      return;
    }
    double _degreesToRadians(double degrees) =>
        degrees * 3.141592653589793 / 180.0;
    double _radiansToDegrees(double radians) =>
        radians * 180.0 / 3.141592653589793;
    double calculateBearingFromPoints(PointModel start, PointModel end) {
      final double lat1Rad = _degreesToRadians(start.latitude);
      final double lon1Rad = _degreesToRadians(start.longitude);
      final double lat2Rad = _degreesToRadians(end.latitude);
      final double lon2Rad = _degreesToRadians(end.longitude);
      final double dLon = lon2Rad - lon1Rad;
      final double y = math.sin(dLon) * math.cos(lat2Rad);
      final double x =
          math.cos(lat1Rad) * math.sin(lat2Rad) -
          math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
      double bearingRad = math.atan2(y, x);
      double bearingDeg = _radiansToDegrees(bearingRad);
      return (bearingDeg + 360) % 360;
    }

    final double calculatedAzimuth = calculateBearingFromPoints(
      startPoint,
      endPoint,
    );
    // Update the azimuth in the form via the tab's state
    _detailsTabKey.currentState?.setAzimuthFromParent(calculatedAzimuth);
    showSuccessStatus(
      s?.azimuthCalculatedSnackbar(calculatedAzimuth.toStringAsFixed(2)) ??
          'Azimuth calculated',
    );
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

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _initiateAddPointFromCompass(
    BuildContext descendantContext,
    double heading, {
    bool? setAsEndPoint,
  }) async {
    final bool addAsEndPoint = setAsEndPoint ?? false;
    final currentProject = context.projectState.currentProject;
    logger.info(
      "Initiating add point. Heading: $heading, Project ID: ${widget.project.id}, Explicit End Point: $setAsEndPoint",
    );
    if (mounted) {
      setState(() {
        _isAddingPointFromCompassInProgress = true;
      });
    }
    showLoadingStatus(S.of(context)!.infoFetchingLocation);

    try {
      final position = await _determinePosition();
      final pointFromCompass = PointModel(
        projectId: widget.project.id,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        ordinalNumber: 0, // Will be set by OrdinalManager
        note: S
            .of(context)!
            .pointFromCompassDefaultNote(heading.toStringAsFixed(1)),
      );

      String newPointIdFromCompass;
      final dbHelper = DatabaseHelper.instance;

      // Use OrdinalManager to handle the complex ordinal logic
      if (!addAsEndPoint && currentProject?.endingPointId != null) {
        // Insert before end point
        await dbHelper.ordinalManager.insertPointBeforeEndPoint(
          pointFromCompass,
          currentProject!.endingPointId!,
        );
        // Get the inserted point ID (we need to query for it)
        final points = await dbHelper.getPointsForProject(widget.project.id);
        final insertedPoint = points.firstWhere(
          (p) =>
              p.latitude == position.latitude &&
              p.longitude == position.longitude &&
              p.note == pointFromCompass.note,
          orElse: () => throw Exception('Inserted point not found'),
        );
        newPointIdFromCompass = insertedPoint.id;
      } else {
        // Append to end
        await dbHelper.ordinalManager.insertPointAtOrdinal(
          pointFromCompass,
          null,
        );
        // Get the inserted point ID
        final points = await dbHelper.getPointsForProject(widget.project.id);
        final insertedPoint = points.firstWhere(
          (p) =>
              p.latitude == position.latitude &&
              p.longitude == position.longitude &&
              p.note == pointFromCompass.note,
          orElse: () => throw Exception('Inserted point not found'),
        );
        newPointIdFromCompass = insertedPoint.id;
      }

      logger.info(
        'Point added via Compass: ID $newPointIdFromCompass, Lat: ${position.latitude}, Lon: ${position.longitude}, Heading used for note: $heading',
      );

      if (addAsEndPoint) {
        ProjectModel projectToUpdate = (currentProject ?? widget.project)
            .copyWith(endingPointId: newPointIdFromCompass);
        await context.projectState.updateProject(projectToUpdate);
        logger.info(
          "New point ID $newPointIdFromCompass set as the END point for project ${widget.project.id}.",
        );
      }

      await dbHelper.updateProjectStartEndPoints(widget.project.id);
      // Refresh global state instead of loading project details
      await context.projectState.refreshPoints();

      if (mounted) {
        hideStatus();
        // Get the final point to get the correct ordinal
        final finalPoint = await dbHelper.getPointById(newPointIdFromCompass);
        String baseMessage = S
            .of(context)!
            .pointAddedSnackbar(finalPoint?.ordinalNumber.toString() ?? '?');
        String suffix = "";
        if (addAsEndPoint == true) {
          suffix = " ${S.of(context)!.pointAddedSetAsEndSnackbarSuffix}";
        } else if (currentProject?.endingPointId != null) {
          suffix =
              " ${S.of(context)!.pointAddedInsertedBeforeEndSnackbarSuffix}";
        }
        showSuccessStatus(baseMessage + suffix);
      }
      _pointsToolViewKey.currentState?.refreshPoints();
    } catch (e, stackTrace) {
      logger.severe("Error adding point from compass", e, stackTrace);
      if (mounted) {
        hideStatus();
        showErrorStatus(S.of(context)!.errorAddingPoint(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingPointFromCompassInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final orientation = MediaQuery.of(context).orientation;
    final saveButtonColor = _hasUnsavedChanges ? Colors.green : null;

    // Use global state for project data
    final currentProject = context.projectStateListen.currentProject;
    final currentPoints = context.projectStateListen.currentPoints;

    Widget tabBarViewWidget = TabBarView(
      controller: _tabController,
      children: [
        ProjectDetailsTab(
          key: _detailsTabKey,
          project: currentProject ?? widget.project,
          isNew: _isEffectivelyNew,
          pointsCount: currentPoints.length,
          onChanged: _onProjectDetailsChanged,
          onSaveProject: _saveProject,
          onCalculateAzimuth: _calculateAzimuth,
        ),
        PointsTab(
          key: _pointsTabKey,
          project: currentProject ?? widget.project,
          onPointsChanged: () async {
            // Refresh global state
            await context.projectState.refreshPoints();
            if (mounted) {
              setState(() {
                realTotalLength = _calculateRealTotalLength(
                  context.projectState.currentPoints,
                );
              });
            }
          },
          onProjectChanged:
              (ProjectModel updatedProject, {bool hasUnsavedChanges = false}) {
                if (mounted) {
                  // Create backup when points are changed
                  _createPointsBackup();
                  _onProjectDetailsChanged(
                    updatedProject,
                    hasUnsavedChanges: hasUnsavedChanges,
                  );
                }
              },
        ),
        CompassToolView(
          project: currentProject ?? widget.project,
          onAddPointFromCompass: _initiateAddPointFromCompass,
          isAddingPoint: _isAddingPointFromCompassInProgress,
        ),
        MapToolView(
          key: _mapTabKey,
          project: currentProject ?? widget.project,
          onPointsChanged: () async {
            // Refresh global state
            await context.projectState.refreshPoints();
            if (mounted) {
              setState(() {
                realTotalLength = _calculateRealTotalLength(
                  context.projectState.currentPoints,
                );
              });
              // Refresh the map points to reflect any reordering
              _mapTabKey.currentState?.refreshPoints();
            }
          },
        ),
      ],
    );
    List<Widget> tabWidgets = [
      Tab(
        icon: const Icon(Icons.info_outline),
        text: s?.details_tab_label ?? "Details",
      ),
      Tab(
        icon: const Icon(Icons.list_alt_outlined),
        text: s?.points_tab_label ?? "Points",
      ),
      Tab(
        icon: const Icon(Icons.explore_outlined),
        text: s?.compass_tab_label ?? "Compass",
      ),
      Tab(
        icon: const Icon(Icons.map_outlined),
        text: s?.map_tab_label ?? "Map",
      ),
    ];
    List<Widget> tabBarActions = [
      // Temporary test button
      IconButton(
        icon: const Icon(Icons.science, color: Colors.purple),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProjectStateTestWidget(),
            ),
          );
        },
        tooltip: 'Test Global State',
      ),
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
      if (_hasPointsChanges)
        IconButton(
          icon: const Icon(Icons.undo, color: Colors.orange),
          onPressed: _isLoading ? null : _undoPointsChanges,
          tooltip: 'Undo Points Changes',
        ),
      if (_hasUnsavedChanges)
        IconButton(
          icon: Icon(Icons.save, color: saveButtonColor),
          onPressed: _isLoading
              ? null
              : () async {
                  // Use updated project data if available, otherwise use global state
                  final projectToSave = _updatedProjectData ?? currentProject ?? widget.project;
                  await _saveProject(projectToSave);
                },
          tooltip: s?.save_project_tooltip ?? 'Save Project',
        ),
    ];
    if (orientation == Orientation.portrait) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            _isEffectivelyNew
                ? (s?.new_project_title ?? 'New Project')
                : (s?.edit_project_title_named(
                        currentProject?.name ?? widget.project.name,
                      ) ??
                      currentProject?.name ??
                      widget.project.name),
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
          title: Text(
            _isEffectivelyNew
                ? (s?.new_project_title ?? 'New Project')
                : (s?.edit_project_title_named(
                        currentProject?.name ?? widget.project.name,
                      ) ??
                      currentProject?.name ??
                      widget.project.name),
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
