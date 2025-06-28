// project_details_page.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:teleferika/core/logger.dart';
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
    with SingleTickerProviderStateMixin, StatusMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;

  late ProjectModel _currentProject;

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

  // Add a GlobalKey to access the ProjectDetailsTab state
  final GlobalKey<ProjectDetailsTabState> _detailsTabKey =
      GlobalKey<ProjectDetailsTabState>();

  // Add a GlobalKey to access the PointsTab state
  final GlobalKey<PointsTabState> _pointsTabKey = GlobalKey<PointsTabState>();

  // GlobalKey to access MapToolView methods
  final GlobalKey<MapToolViewState> _mapTabKey = GlobalKey<MapToolViewState>();

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _isEffectivelyNew = widget.isNew;
    _projectDate =
        _currentProject.date ?? (widget.isNew ? DateTime.now() : null);
    _lastUpdateTime = _currentProject.lastUpdate;
    realTotalLength = _calculateRealTotalLength(_currentProject.points);
    if (widget.isNew) {
      _insertNewProjectToDb();
    } else {
      _loadProjectDetails();
    }

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
  }

  Future<void> _insertNewProjectToDb() async {
    // Insert the new project into the DB so points can be added
    await _dbHelper.insertProject(_currentProject);
    // Optionally reload from DB to get any DB-generated fields
    final dbProject = await _dbHelper.getProjectById(_currentProject.id);
    if (dbProject != null && mounted) {
      setState(() {
        _currentProject = dbProject;
        _isEffectivelyNew = true;
      });
    }
  }

  Future<void> _deleteProjectFromDb() async {
    await _dbHelper.deleteProject(_currentProject.id);
  }

  Future<void> _loadProjectDetails() async {
    setState(() => _isLoading = true);
    try {
      final projectDataFromDb = await _dbHelper.getProjectById(
        _currentProject.id,
      );
      if (projectDataFromDb != null && mounted) {
        setState(() {
          _currentProject = projectDataFromDb;
          _projectDate = _currentProject.date;
          _lastUpdateTime = _currentProject.lastUpdate;
          realTotalLength = _calculateRealTotalLength(_currentProject.points);
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
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
      if (_isEffectivelyNew) {
        await _dbHelper.updateProject(projectToSave);
        setState(() {
          _isEffectivelyNew = false;
          _projectWasSuccessfullySaved = true;
          _hasUnsavedChanges = false;
          _currentProject = projectToSave;
        });
        // Clear undo backup in PointsToolView
        _pointsTabKey.currentState?.onProjectSaved();
        _clearPointsBackup();
        showSuccessStatus('Project saved successfully');
      } else {
        int updatedRows = await _dbHelper.updateProject(projectToSave);
        if (updatedRows > 0) {
          setState(() {
            _currentProject = projectToSave;
            _lastUpdateTime = _currentProject.lastUpdate;
            _hasUnsavedChanges = false;
            _projectWasSuccessfullySaved = true;
          });
          // Clear undo backup in PointsToolView
          _pointsTabKey.currentState?.onProjectSaved();
          _clearPointsBackup();
          showSuccessStatus('Project updated successfully');
        }
      }
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
      _currentProject = updated;
      _hasUnsavedChanges = hasUnsavedChanges;
    });
    logger.info("New _hasUnsavedChanges: $_hasUnsavedChanges");
  }

  /// Creates a backup of the current points list for undo functionality
  void _createPointsBackup() {
    if (_originalPointsBackup == null) {
      _originalPointsBackup = List.from(_currentProject.points);
      _hasPointsChanges = true;
      logger.info("Created backup of ${_originalPointsBackup!.length} points for undo");
    }
  }

  /// Restores the original points list and clears the backup
  Future<void> _undoPointsChanges() async {
    if (_originalPointsBackup != null) {
      logger.info("Undoing points changes - restoring ${_originalPointsBackup!.length} points");
      
      try {
        // Restore the original points in the database
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          // Clear all current points for this project
          await txn.delete(
            'points',
            where: 'project_id = ?',
            whereArgs: [_currentProject.id],
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
          await _dbHelper.updateProjectStartEndPoints(_currentProject.id!, txn: txn);
        });
        
        // Reload project data from database
        final updatedProject = await _dbHelper.getProjectById(_currentProject.id!);
        if (updatedProject != null) {
          setState(() {
            _currentProject = updatedProject;
            _hasPointsChanges = false;
            _hasUnsavedChanges = false;
          });
        }
        
        // Clear the backup
        _originalPointsBackup = null;
        
        // Refresh the PointsToolView to show the restored points and update colors
        _pointsTabKey.currentState?.refreshPoints();
        
        // Also update the PointsToolView's local project state to reflect the restored start/end points
        _pointsTabKey.currentState?.updateLocalProject(updatedProject!);
        
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
            ).pop({'action': 'saved', 'id': _currentProject.id});
          } else {
            Navigator.of(context).pop();
          }
        }
      }
    } else {
      // Pop with 'saved' if project was ever saved, otherwise 'navigated_back'
      if (mounted && _projectWasSuccessfullySaved) {
        Navigator.of(
          context,
        ).pop({'action': 'saved', 'id': _currentProject.id});
      } else if (mounted && !_isEffectivelyNew) {
        Navigator.of(
          context,
        ).pop({'action': 'navigated_back', 'id': _currentProject.id});
      } else if (mounted) {
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
            s?.confirm_delete_project_content(_currentProject.name) ??
                'Are you sure you want to delete the project "${_currentProject.name}"? This action cannot be undone.',
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
          ).pop({'action': 'deleted', 'id': _currentProject.id});
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
    if (_currentProject.points.length < 2) {
      showErrorStatus(
        s?.errorAzimuthPointsNotSet ?? 'At least two points are required',
      );
      return;
    }
    final startPoint = _currentProject.points.first;
    final endPoint = _currentProject.points.last;
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
    if (_currentProject.points.isEmpty) {
      showErrorStatus(s?.errorExportNoPoints ?? 'No points to export');
      return;
    }

    try {
      showLoadingStatus(s?.infoExporting ?? 'Exporting...');

      final success = await LicensedFeaturesLoader.showExportDialog(
        context,
        _currentProject,
        _currentProject.points,
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

  Future<int> _getNextOrdinalNumber(String projectId) async {
    return await _dbHelper.ordinalManager.getNextOrdinal(projectId);
  }

  Future<void> _initiateAddPointFromCompass(
    BuildContext descendantContext,
    double heading, {
    bool? setAsEndPoint,
  }) async {
    final bool addAsEndPoint = setAsEndPoint ?? false;
    logger.info(
      "Initiating add point. Heading: $heading, Project ID: ${_currentProject.id}, Explicit End Point: $setAsEndPoint",
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
        projectId: _currentProject.id,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        ordinalNumber: 0, // Will be set by OrdinalManager
        note: S
            .of(context)!
            .pointFromCompassDefaultNote(heading.toStringAsFixed(1)),
      );

      String newPointIdFromCompass;

      // Use OrdinalManager to handle the complex ordinal logic
      if (!addAsEndPoint && _currentProject.endingPointId != null) {
        // Insert before end point
        await _dbHelper.ordinalManager.insertPointBeforeEndPoint(
          pointFromCompass,
          _currentProject.endingPointId!,
        );
        // Get the inserted point ID (we need to query for it)
        final points = await _dbHelper.getPointsForProject(_currentProject.id);
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
        await _dbHelper.ordinalManager.insertPointAtOrdinal(
          pointFromCompass,
          null,
        );
        // Get the inserted point ID
        final points = await _dbHelper.getPointsForProject(_currentProject.id);
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
        ProjectModel projectToUpdate = _currentProject.copyWith(
          endingPointId: newPointIdFromCompass,
        );
        await _dbHelper.updateProject(projectToUpdate);
        logger.info(
          "New point ID $newPointIdFromCompass set as the END point for project ${_currentProject.id}.",
        );
      }

      await _dbHelper.updateProjectStartEndPoints(_currentProject.id);
      await _loadProjectDetails();

      if (mounted) {
        hideStatus();
        // Get the final point to get the correct ordinal
        final finalPoint = await _dbHelper.getPointById(newPointIdFromCompass);
        String baseMessage = S
            .of(context)!
            .pointAddedSnackbar(finalPoint?.ordinalNumber.toString() ?? '?');
        String suffix = "";
        if (addAsEndPoint == true) {
          suffix = " ${S.of(context)!.pointAddedSetAsEndSnackbarSuffix}";
        } else if (_currentProject.endingPointId != null) {
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
    Widget tabBarViewWidget = TabBarView(
      controller: _tabController,
      children: [
        ProjectDetailsTab(
          key: _detailsTabKey,
          project: _currentProject,
          isNew: _isEffectivelyNew,
          pointsCount: _currentProject.points.length,
          onChanged: _onProjectDetailsChanged,
          onSaveProject: _saveProject,
          onCalculateAzimuth: _calculateAzimuth,
        ),
        PointsTab(
          key: _pointsTabKey,
          project: _currentProject,
          onPointsChanged: () async {
            final updatedProject = await _dbHelper.getProjectById(
              _currentProject.id,
            );
            if (updatedProject != null && mounted) {
              setState(() {
                _currentProject = updatedProject;
                realTotalLength = _calculateRealTotalLength(
                  _currentProject.points,
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
          project: _currentProject,
          onAddPointFromCompass: _initiateAddPointFromCompass,
          isAddingPoint: _isAddingPointFromCompassInProgress,
        ),
        MapToolView(
          key: _mapTabKey,
          project: _currentProject,
          onPointsChanged: () async {
            final updatedProject = await _dbHelper.getProjectById(
              _currentProject.id,
            );
            if (updatedProject != null && mounted) {
              setState(() {
                _currentProject = updatedProject;
                realTotalLength = _calculateRealTotalLength(
                  _currentProject.points,
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
      if (!_isEffectivelyNew)
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: _isLoading ? null : _confirmDeleteProject,
          tooltip: s?.delete_project_tooltip ?? 'Delete Project',
        ),
      if (!_isEffectivelyNew && _currentProject.points.isNotEmpty)
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
                  await _saveProject(_currentProject);
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
                : (s?.edit_project_title_named(_currentProject.name) ??
                      _currentProject.name),
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
                : (s?.edit_project_title_named(_currentProject.name) ??
                      _currentProject.name),
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
