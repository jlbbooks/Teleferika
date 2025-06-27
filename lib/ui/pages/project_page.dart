// project_details_page.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/ui/tabs/compass_tool_view.dart';
import 'package:teleferika/ui/tabs/map_tool_view.dart';
import 'package:teleferika/ui/tabs/points_tab.dart';
import 'package:teleferika/ui/tabs/points_tool_view.dart';
import 'package:teleferika/ui/tabs/project_details_tab.dart';

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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;

  late ProjectModel _currentProject;

  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isEffectivelyNew = true;

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
      } else {
        int updatedRows = await _dbHelper.updateProject(projectToSave);
        if (updatedRows > 0) {
          setState(() {
            _currentProject = projectToSave;
            _lastUpdateTime = _currentProject.lastUpdate;
            _hasUnsavedChanges = false;
            _projectWasSuccessfullySaved = true;
          });
        }
      }
      // Do NOT pop here; just update state
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    setState(() {
      _currentProject = updated;
      _hasUnsavedChanges = hasUnsavedChanges;
    });
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.project_deleted_successfully ?? 'Project deleted.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pop({'action': 'deleted', 'id': _currentProject.id});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.error_deleting_project(e.toString()) ??
                    'Error deleting project: $e',
              ),
              backgroundColor: Colors.red,
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.errorAzimuthPointsNotSet ?? 'At least two points are required.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final startPoint = _currentProject.points.first;
    final endPoint = _currentProject.points.last;
    if (startPoint.id == endPoint.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.errorAzimuthPointsSame ??
                'Start and end points must be different.',
          ),
          backgroundColor: Colors.orange,
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s?.azimuthCalculatedSnackbar(calculatedAzimuth.toStringAsFixed(2)) ??
              'Azimuth calculated.',
        ),
        backgroundColor: Colors.green,
      ),
    );
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
    final lastOrdinal = await _dbHelper.getLastPointOrdinal(projectId);
    return (lastOrdinal ?? -1) + 1;
  }

  Future<void> _initiateAddPointFromCompass(
    BuildContext descendantContext,
    double heading, {
    bool? setAsEndPoint,
  }) async {
    final bool addAsEndPoint = setAsEndPoint ?? false;
    logger.info(
      "Initiating add point. Heading: $heading, Project ID: \\${_currentProject.id}, Explicit End Point: $setAsEndPoint",
    );
    if (mounted) {
      setState(() {
        _isAddingPointFromCompassInProgress = true;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context)!.infoFetchingLocation),
        duration: const Duration(seconds: 2),
      ),
    );
    PointModel? currentEndPointModel;
    int? originalEndPointOrdinal;
    int newPointOrdinal;
    try {
      final position = await _determinePosition();
      if (!addAsEndPoint && _currentProject.endingPointId != null) {
        currentEndPointModel = await _dbHelper.getPointById(
          _currentProject.endingPointId!,
        );
        if (currentEndPointModel != null) {
          originalEndPointOrdinal = currentEndPointModel.ordinalNumber;
          newPointOrdinal = originalEndPointOrdinal;
          final int newOrdinalForOldEndPoint = await _getNextOrdinalNumber(
            _currentProject.id,
          );
          PointModel updatedOldEndPoint = currentEndPointModel.copyWith(
            ordinalNumber: newOrdinalForOldEndPoint,
          );
          await _dbHelper.updatePoint(updatedOldEndPoint);
          logger.info(
            "Old end point (ID: \\${currentEndPointModel.id})'s ordinal shifted from $originalEndPointOrdinal to $newOrdinalForOldEndPoint.",
          );
        } else {
          logger.warning(
            "Project's endingPointId \\${_currentProject.endingPointId} not found in DB. Proceeding as if no end point.",
          );
          newPointOrdinal = await _getNextOrdinalNumber(_currentProject.id);
        }
      } else {
        newPointOrdinal = await _getNextOrdinalNumber(_currentProject.id);
      }
      final pointFromCompass = PointModel(
        projectId: _currentProject.id,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        ordinalNumber: newPointOrdinal,
        note: S
            .of(context)!
            .pointFromCompassDefaultNote(heading.toStringAsFixed(1)),
      );
      final newPointIdFromCompass = await _dbHelper.insertPoint(
        pointFromCompass,
      );
      logger.info(
        'Point added via Compass: ID $newPointIdFromCompass, Lat: \\${position.latitude}, Lon: \\${position.longitude}, Heading used for note: $heading, Ordinal: \\${pointFromCompass.ordinalNumber}',
      );
      if (addAsEndPoint) {
        ProjectModel projectToUpdate = _currentProject.copyWith(
          endingPointId: newPointIdFromCompass,
        );
        await _dbHelper.updateProject(projectToUpdate);
        logger.info(
          "New point ID $newPointIdFromCompass set as the END point for project \\${_currentProject.id}.",
        );
      }
      await _dbHelper.updateProjectStartEndPoints(_currentProject.id);
      await _loadProjectDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        String baseMessage = S
            .of(context)!
            .pointAddedSnackbar(pointFromCompass.ordinalNumber.toString());
        String suffix = "";
        if (addAsEndPoint == true) {
          suffix = " \\${S.of(context)!.pointAddedSetAsEndSnackbarSuffix}";
        } else if (currentEndPointModel != null) {
          suffix =
              " \\${S.of(context)!.pointAddedInsertedBeforeEndSnackbarSuffix}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(baseMessage + suffix),
            backgroundColor: Colors.green,
          ),
        );
      }
      _pointsToolViewKey.currentState?.refreshPoints();
    } catch (e, stackTrace) {
      logger.severe("Error adding point from compass", e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)!.errorAddingPoint(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
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
        ),
        CompassToolView(
          project: _currentProject,
          onAddPointFromCompass: _initiateAddPointFromCompass,
          isAddingPoint: _isAddingPointFromCompassInProgress,
        ),
        MapToolView(
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
      if (_tabController.index == ProjectPageTab.details.index)
        IconButton(
          icon: Icon(Icons.save, color: saveButtonColor),
          onPressed: _isLoading || !_hasUnsavedChanges
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
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: _handleOnPopInvokedWithResult,
          child: tabBarViewWidget,
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
        body: PopScope(
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
                        .map((tab) => RotatedBox(quarterTurns: 1, child: tab))
                        .toList(),
                  ),
                ),
              ),
              Expanded(child: tabBarViewWidget),
            ],
          ),
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
