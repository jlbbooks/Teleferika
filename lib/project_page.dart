// project_details_page.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/project_tools/compass_tab.dart';
import 'package:teleferika/project_tools/map_tab.dart';
import 'package:teleferika/project_tools/map_tool_view.dart';
import 'package:teleferika/project_tools/points_tab.dart';
import 'package:teleferika/project_tools/points_tool_view.dart';
import 'package:teleferika/project_tools/project_details_tab.dart';

import 'db/database_helper.dart'; // Ensure correct path
import 'db/models/point_model.dart';
import 'db/models/project_model.dart'; // Ensure correct path
import 'export/export_page.dart';
import 'l10n/app_localizations.dart';
import 'logger.dart';

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
  final GlobalKey<ProjectDetailsTabState> _detailsTabKey =
      GlobalKey<ProjectDetailsTabState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;

  late ProjectModel _currentProject;

  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isEffectivelyNew = true;

  final GlobalKey<PointsToolViewState> _pointsToolViewKey =
      GlobalKey<PointsToolViewState>();
  final GlobalKey<MapToolViewState> _mapToolViewKey =
      GlobalKey<MapToolViewState>();

  bool _isAddingPointFromCompassInProgress = false;
  String? _newlyAddedPointId;
  bool _projectWasSuccessfullySaved = false;

  final LicenceService _licenceService =
      LicenceService.instance; // Get instance

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _isEffectivelyNew = widget.isNew; // Initialize based on widget property

    _tabController = TabController(
      length: ProjectPageTab.values.length,
      vsync: this,
    );
    _projectDate =
        _currentProject.date ?? (widget.isNew ? DateTime.now() : null);
    _lastUpdateTime = _currentProject.lastUpdate;

    if (!widget.isNew) {
      logger.info(
        "ProjectPage initialized for EXISTING project. ID: \\${_currentProject.id}, Name: \\${_currentProject.name}. Loading details...",
      );
      _loadProjectDetails();
    } else {
      logger.info(
        "ProjectDetailsPage initialized for a NEW project. Name: \\${_currentProject.name}",
      );
    }
  }

  void _onChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _checkLicenceAndProceedToExport() async {
    bool licenceIsValid = await _licenceService.isLicenceValid();

    if (!licenceIsValid) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            final dialogS = S.of(
              dialogContext,
            ); // Get S instance for dialog's context
            return AlertDialog(
              title: Text(
                dialogS?.export_requires_licence_title ?? "Licence Required",
              ),
              content: Text(
                dialogS?.export_requires_licence_message ??
                    "Exporting project data requires an active licence. Please import a valid licence.",
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(dialogS?.dialog_cancel ?? 'Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    dialogS?.action_import_licence ?? 'Import Licence',
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close current dialog
                    // You might want to navigate to a dedicated licence page or trigger the import flow from here
                    // For simplicity, let's assume we can trigger the import flow similarly to ProjectsListPage
                    // This might involve passing a callback or navigating back to ProjectsListPage to handle it
                    // Or, call _licenceService.importLicenceFromFile() directly if UI context is suitable
                    // For now, let's just log and inform the user to do it from the main page
                    try {
                      final importedLicence = await _licenceService
                          .importLicenceFromFile();
                      if (mounted) {
                        if (importedLicence != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Licence for ${importedLicence.email} imported! Try exporting again.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Licence import cancelled or failed.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } on FormatException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error importing licence: $e. Please try from the main page.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      }
      return; // Stop export if licence is not valid
    }

    // If licence is valid, proceed to the actual export navigation
    _navigateToExportPage(); // Your existing method
  }

  void _switchToTab(ProjectPageTab tab) {
    if (!_tabController.indexIsChanging) {
      _tabController.animateTo(ProjectPageTab.values.indexOf(tab));
    }
    setState(() {});
  }

  Future<void> _loadProjectDetails() async {
    setStateIfMounted(() => _isLoading = true);
    try {
      final projectDataFromDb = await _dbHelper.getProjectById(
        _currentProject.id,
      );
      if (projectDataFromDb != null && mounted) {
        setState(() {
          _currentProject = projectDataFromDb;
          _projectDate = _currentProject.date;
          _lastUpdateTime = _currentProject.lastUpdate;
        });
      }
      logger.info(
        "Project details loaded/refreshed for ID: \\${_currentProject.id}",
      );
    } catch (e, stackTrace) {
      logger.severe(
        "Error loading project details for ID \\${_currentProject.id}",
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.errorLoadingProjectDetails(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setStateIfMounted(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Logic for Adding Point from Compass ---
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.warning('Location services are disabled.');
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.warning('Location permissions are denied.');
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.warning(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<int> _getNextOrdinalNumber(String projectId) async {
    final lastOrdinal = await _dbHelper.getLastPointOrdinal(projectId);
    return (lastOrdinal ?? -1) + 1; // If no points, next ordinal is 0
  }

  Future<void> _initiateAddPointFromCompass(
    BuildContext descendantContext,
    double heading, {
    bool? setAsEndPoint, // Added optional named parameter
  }) async {
    final bool addAsEndPoint =
        setAsEndPoint ?? false; // Default to false if null

    logger.info(
      "Initiating add point. Heading: $heading, Project ID: ${_currentProject.id}, Explicit End Point: $setAsEndPoint",
    );

    // START loading indicator in CompassToolView by setting state
    if (mounted) {
      setState(() {
        _isAddingPointFromCompassInProgress = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context)!.infoFetchingLocation),
        duration: const Duration(seconds: 2), // Short duration
      ),
    );

    PointModel? currentEndPointModel;
    int? originalEndPointOrdinal;
    int
    newPointOrdinal; // This will be the ordinal for the point being added from compass

    try {
      final position = await _determinePosition();
      // final nextOrdinal = await _getNextOrdinalNumber(_currentProject.id!);
      if (!addAsEndPoint && _currentProject.endingPointId != null) {
        // --- Case 1: NOT setting as new end point, AND an old end point exists ---
        currentEndPointModel = await _dbHelper.getPointById(
          _currentProject.endingPointId!,
        );

        if (currentEndPointModel != null) {
          originalEndPointOrdinal = currentEndPointModel.ordinalNumber;
          // The new point from compass will take the original end point's ordinal
          newPointOrdinal = originalEndPointOrdinal;

          // The OLD end point needs a new, higher ordinal
          final int newOrdinalForOldEndPoint = await _getNextOrdinalNumber(
            _currentProject.id,
          );

          PointModel updatedOldEndPoint = currentEndPointModel.copyWith(
            ordinalNumber: newOrdinalForOldEndPoint,
          );
          await _dbHelper.updatePoint(updatedOldEndPoint);
          logger.info(
            "Old end point (ID: ${currentEndPointModel.id})'s ordinal shifted from $originalEndPointOrdinal to $newOrdinalForOldEndPoint.",
          );
        } else {
          // Fallback if currentProject.endingPointId was set but point not found (data integrity issue)
          logger.warning(
            "Project's endingPointId ${_currentProject.endingPointId} not found in DB. Proceeding as if no end point.",
          );
          newPointOrdinal = await _getNextOrdinalNumber(_currentProject.id);
        }
      } else {
        // --- Case 2: Setting as new end point OR no existing end point to shuffle ---
        newPointOrdinal = await _getNextOrdinalNumber(_currentProject.id);
      }

      final pointFromCompass = PointModel(
        projectId: _currentProject.id,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        ordinalNumber: newPointOrdinal,
        // You might want a default note or a way to add one later
        note: S
            .of(context)!
            .pointFromCompassDefaultNote(heading.toStringAsFixed(1)),
      );

      final newPointIdFromCompass = await _dbHelper.insertPoint(
        pointFromCompass,
      );
      logger.info(
        'Point added via Compass: ID $newPointIdFromCompass, Lat: ${position.longitude}, Lon: ${position.longitude}, Heading used for note: $heading, Ordinal: ${pointFromCompass.ordinalNumber}',
      );

      // AFTER point is inserted, update the project's start/end points
      if (addAsEndPoint) {
        // Update the project's endingPointId with the newPointIdFromCompass
        // Create a copy of _currentProject to modify its endingPointId
        ProjectModel projectToUpdate = _currentProject.copyWith(
          endingPointId: newPointIdFromCompass,
        );
        await _dbHelper.updateProject(projectToUpdate);
        logger.info(
          "New point ID $newPointIdFromCompass set as the END point for project ${_currentProject.id}.",
        );
      }
      // If !addAsExplicitEndPoint, _currentProject.endingPointId remains unchanged,
      // pointing to the ID of the original end point (which now has a new ordinal).

      // This method should now correctly identify start and end points based on their IDs
      // and potentially their ordinals (if it falls back to highest ordinal for end point if not set).
      await _dbHelper.updateProjectStartEndPoints(_currentProject.id!);
      await _loadProjectDetails(); // Reload project to get updated start/end IDs for the UI

      if (mounted) {
        setState(() {
          _newlyAddedPointId = newPointIdFromCompass;
        });
        ScaffoldMessenger.of(
          context,
        ).removeCurrentSnackBar(); // Remove "Fetching location..."
        String baseMessage = S
            .of(context)!
            .pointAddedSnackbar(pointFromCompass.ordinalNumber.toString());
        String suffix = "";
        if (addAsEndPoint == true) {
          // Explicitly check for true if addAsEndPoint is bool?
          suffix = " ${S.of(context)!.pointAddedSetAsEndSnackbarSuffix}";
        } else if (currentEndPointModel != null) {
          suffix =
              " ${S.of(context)!.pointAddedInsertedBeforeEndSnackbarSuffix}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(baseMessage + suffix),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh PointsToolView if it's active or if you always want it updated
      _pointsToolViewKey.currentState
          ?.refreshPoints(); // Call refreshPoints on PointsToolView

      // If the compass tool is active, and you want to switch to points view
      _switchToTab(ProjectPageTab.points);
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
      // STOP loading indicator in CompassToolView
      if (mounted) {
        setState(() {
          _isAddingPointFromCompassInProgress = false;
        });
      }
    }
  }
  // --- End Logic for Adding Point ---

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _selectProjectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _projectDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _projectDate) {
      setStateIfMounted(() {
        _projectDate = pickedDate;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _calculateAzimuth() async {
    logger.info(
      "Calculate Azimuth button tapped for project: ${_currentProject.name}",
    );

    final String? startPointId = _currentProject.startingPointId;
    final String? endPointId = _currentProject.endingPointId;

    if (startPointId == null || endPointId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.errorAzimuthPointsNotSet),
          backgroundColor: Colors.orange,
        ),
      );
      setStateIfMounted(() {
        _currentProject = _currentProject.copyWith(
          azimuth: null,
          clearAzimuth: true,
        );
      });
      return;
    }

    if (startPointId == endPointId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.errorAzimuthPointsSame),
          backgroundColor: Colors.orange,
        ),
      );
      setStateIfMounted(() {
        _currentProject = _currentProject.copyWith(
          azimuth: null,
          clearAzimuth: true,
        );
      });
      return;
    }

    try {
      final PointModel? startPoint = await _dbHelper.getPointById(startPointId);
      final PointModel? endPoint = await _dbHelper.getPointById(endPointId);

      if (startPoint == null || endPoint == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context)!.errorAzimuthCouldNotRetrievePoints),
              backgroundColor: Colors.red,
            ),
          );
        }
        logger.severe(
          "Error calculating azimuth: StartPoint (ID $startPointId) or EndPoint (ID $endPointId) not found.",
        );
        return;
      }

      final double calculatedAzimuth = calculateBearingFromPoints(
        startPoint,
        endPoint,
      );

      setStateIfMounted(() {
        _currentProject = _currentProject.copyWith(azimuth: calculatedAzimuth);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S
                  .of(context)!
                  .azimuthCalculatedSnackbar(
                    calculatedAzimuth.toStringAsFixed(2),
                  ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      logger.info(
        "Azimuth calculated successfully: ${calculatedAzimuth.toStringAsFixed(2)}° from P${startPoint.ordinalNumber} to P${endPoint.ordinalNumber}",
      );
    } catch (e, stackTrace) {
      logger.severe("Error during azimuth calculation: $e", e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)!.errorCalculatingAzimuth(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _saveProject() async {
    if (_isLoading) return null;

    if (_detailsTabKey.currentState?.validateForm() ?? false) {
      setState(() => _isLoading = true);

      // Use _currentProject, which is kept up-to-date by ProjectDetailsTab
      ProjectModel projectToSave = _currentProject.copyWith(
        id: _currentProject.id,
        date: _projectDate,
        lastUpdate: DateTime.now(),
        startingPointId: _currentProject.startingPointId,
        endingPointId: _currentProject.endingPointId,
      );

      try {
        if (_isEffectivelyNew) {
          String newId = await _dbHelper.insertProject(projectToSave);
          if (mounted) {
            // Update _currentProject to reflect the saved state (especially lastUpdate from DB if different)
            // For now, projectToSave is good enough.
            _currentProject = projectToSave.copyWith(
              id: newId, // FIXME: no need.. id does not change.. remove
            ); // Ensure ID consistency if DB generated it differently (not for UUIDs)
            // For client-generated UUIDs, projectToSave.id is already the ID.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context)!.project_created_successfully),
                backgroundColor: Colors.green,
              ),
            );
            _hasUnsavedChanges = false;
            _isEffectivelyNew =
                false; // It's no longer 'new' for this page instance
            _projectWasSuccessfullySaved = true;
            setState(
              () {},
            ); // To refresh display with new ID/lastUpdate if needed
          }
        } else {
          // For an existing project, update it
          int updatedRows = await _dbHelper.updateProject(projectToSave);
          if (updatedRows > 0) {
            _currentProject = projectToSave;
            _lastUpdateTime = _currentProject.lastUpdate;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context)!.projectSavedSuccessfully),
                  backgroundColor: Colors.green,
                ),
              );
              _hasUnsavedChanges = false;
              _projectWasSuccessfullySaved = true;
              setState(() {}); // To refresh display of lastUpdate
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context)!.project_already_up_to_date),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
          }
        }
      } catch (e, stackTrace) {
        logger.severe("Error saving project: $e", e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context)!.error_saving_project(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.please_correct_form_errors),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return _projectWasSuccessfullySaved;
  }

  Future<void> _confirmDeleteProject() async {
    if (_isEffectivelyNew || _currentProject.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.cannot_delete_unsaved_project),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final s = S.of(context); // Get S instance for localizations
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            s?.confirm_delete_project_content(_currentProject.name) ??
                'Are you sure you want to delete the project "${_currentProject.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(s?.buttonCancel ?? 'Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
            ),
            TextButton(
              child: Text(
                s?.buttonDelete ?? 'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (_isLoading) return; // Prevent multiple delete attempts
      setState(() {
        _isLoading = true;
      });

      try {
        int deletedRows = await _dbHelper.deleteProject(_currentProject.id!);
        if (deletedRows > 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context)!.project_deleted_successfully),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(
              context,
            ).pop({'action': 'deleted', 'id': _currentProject.id!});
          }
        } else {
          // This case might indicate the project was already deleted or not found
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context)!.project_not_found_or_deleted),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        logger.severe("Error deleting project: $e", e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context)!.error_deleting_project(e.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToExportPage() {
    // Get the S instance for localization
    final s = S.of(context);
    if (s == null) {
      // This should ideally not happen if localizations are set up correctly.
      // Fallback or log an error.
      logger.warning(
        "S.of(context) is null in _navigateToExportPage. Using default strings.",
      );
      // As a minimal fallback, you might proceed without localized strings,
      // or show an error and prevent navigation.
      // For this example, we'll use hardcoded defaults if 's' is null,
      // but in a real app, you'd want a more robust fallback.
    }

    if (_currentProject != null) {
      if (_hasUnsavedChanges && !_isEffectivelyNew) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            // Use dialogContext
            final dialogS = S.of(
              dialogContext,
            ); // Get S instance for dialog's context

            return AlertDialog(
              title: Text(dialogS?.unsaved_changes_title ?? 'Unsaved Changes'),
              content: Text(
                dialogS?.unsaved_changes_export_message ??
                    'You have unsaved changes. Please save the project before exporting to ensure all data is included.',
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(dialogS?.dialog_cancel ?? 'Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: Text(dialogS?.save_button_label ?? 'Save'),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close the dialog first
                    bool saved = await _saveProject() ?? false;
                    if (saved && mounted) {
                      // Check 'mounted' again after async operation
                      Navigator.push(
                        context, // Use the original page context for navigation
                        MaterialPageRoute(
                          builder: (context) =>
                              ExportPage(project: _currentProject),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      } else if (_currentProject!.id.isEmpty && _isEffectivelyNew) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.please_save_project_first_to_export ??
                  'Please save the new project first to enable export.',
            ),
          ),
        );
      } else {
        // Proceed to export page if no unsaved changes for an existing project,
        // or if it's a new project that's already been saved (has an ID).
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExportPage(project: _currentProject!),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.project_not_loaded_cannot_export ??
                'Project not loaded. Cannot export data.',
          ),
        ),
      );
    }
  }

  void _handleOnPopInvokedWithResult(bool didPop, Object? result) async {
    final s = S.of(context); // Get S instance for localizations
    if (didPop) {
      return;
    }
    if (_hasUnsavedChanges) {
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
        // ignore: use_build_context_synchronously
        if (mounted) Navigator.of(context).pop();
      }
    } else {
      // No unsaved changes, so we can pop.
      // Now check if a save occurred at any point.
      if (mounted) {
        if (_projectWasSuccessfullySaved) {
          Navigator.of(context).pop<Map<String, dynamic>>({
            'action': 'saved', // Or 'saved_and_exited'
            'id': _currentProject.id, // Pass the latest saved state
          });
        } else {
          // No unsaved changes, and no save occurred during this page's lifetime
          Navigator.of(
            context,
          ).pop(); //({'action': 'no_changes_made'}); // Or simply pop() for null
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context); // Get S instance for localizations
    if (s == null) {
      logger.warning(
        "S.of(context) is null in ProjectPage build. UI may not be localized.",
      );
      // Handle fallback if necessary, or proceed with default strings in tooltips/text
    }

    String formattedProjectDate;
    if (_projectDate != null) {
      // Use a common, locale-aware skeleton.
      // yMMMd() is a good general purpose format (e.g., "Sep 10, 2023" or "10 Sep 2023")
      // You can explore other skeletons like:
      // DateFormat.yMd(Localizations.localeOf(context).toString()).format(_projectDate!)
      // DateFormat.yMEd(Localizations.localeOf(context).toString()).format(_projectDate!) // Includes day of week
      // DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString()).format(_projectDate!) // Very verbose

      // Get the current locale from the context
      final locale = Localizations.localeOf(context).toString();
      formattedProjectDate = DateFormat.yMMMd(locale).format(_projectDate!);
    } else {
      formattedProjectDate = s?.tap_to_set_date ?? 'Tap to set date';
    }
    String formattedLastUpdate = _lastUpdateTime != null
        ? DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_Hm().format(_lastUpdateTime!)
        : s?.not_yet_saved_label ?? 'Not yet saved';

    // Determine the title based on whether it's a new project or editing an existing one
    String appBarTitle;
    if (_isEffectivelyNew) {
      appBarTitle = s?.new_project_title ?? 'New Project';
    } else {
      appBarTitle =
          s?.edit_project_title_named(_currentProject.name) ??
          _currentProject.name;
    }

    final orientation = MediaQuery.of(context).orientation;
    Widget tabBarViewWidget = TabBarView(
      controller: _tabController,
      children: [
        ProjectDetailsTab(
          key: _detailsTabKey,
          project: _currentProject,
          isNew: _isEffectivelyNew,
          projectDate: _projectDate,
          lastUpdateTime: _lastUpdateTime,
          onChanged: _onProjectDetailsChanged,
        ),
        PointsTab(
          project: _currentProject,
          onPointsChanged: _onPointsChanged,
          // newlyAddedPointId: _newlyAddedPointId, // Add if you track this
        ),
        CompassTab(
          project: _currentProject,
          // onAddPointFromCompass: _initiateAddPointFromCompass, // Add if you use this callback
          // isAddingPoint: _isAddingPointFromCompassInProgress, // Add if you track this
        ),
        MapTab(
          project: _currentProject,
          // selectedPointId: null, // Add if you track this
          // onNavigateToCompassTab: () { _switchToTab(ProjectPageTab.compass); }, // Add if you use this
          // onAddPointFromCompass: _initiateAddPointFromCompass, // Add if you use this
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
      if (!_isEffectivelyNew) // Show delete only for existing projects
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: _isLoading ? null : _confirmDeleteProject,
          tooltip: s?.delete_project_tooltip ?? 'Delete Project',
        ),
      if (!_isEffectivelyNew)
        IconButton(
          icon: const Icon(
            Icons.output,
          ), // Or Icons.ios_share, Icons.file_upload
          // Using the localized string for the tooltip
          tooltip: s?.export_project_data_tooltip ?? 'Export Project Data',
          onPressed: (_isEffectivelyNew || _isLoading)
              ? null // Disable if project is new and never saved, or if loading
              : _checkLicenceAndProceedToExport,
        ),
      IconButton(
        icon: Icon(_hasUnsavedChanges ? Icons.save : Icons.save_outlined),
        onPressed: _isLoading
            ? null
            : () {
                // Only validate if on the details tab, or always if you want
                if (_tabController.index == ProjectPageTab.details.index) {
                  final isValid =
                      _detailsTabKey.currentState?.validateForm() ?? false;
                  if (!isValid) {
                    // Optionally show a message
                    return;
                  }
                }
                _saveProject();
              },
        tooltip: s?.save_project_tooltip ?? 'Save Project',
        color: _hasUnsavedChanges
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
    ];

    if (orientation == Orientation.portrait) {
      // Portrait layout
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(appBarTitle),
          actions: tabBarActions,
          bottom: TabBar(
            controller: _tabController,
            isScrollable:
                false, // Set to true if you have many tabs that don't fit
            tabs: tabWidgets,
          ),
        ),
        body: PopScope(
          // Use PopScope for "are you sure you want to leave" dialog
          canPop: false,
          onPopInvokedWithResult: _handleOnPopInvokedWithResult,
          child: tabBarViewWidget,
        ),
      );
    } else {
      // Horizontal layout
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(appBarTitle),
          actions: tabBarActions,
          // No bottom TabBar in AppBar for landscape
        ),
        body: PopScope(
          // Use PopScope for "are you sure you want to leave" dialog
          canPop: false,
          onPopInvokedWithResult: _handleOnPopInvokedWithResult,
          child: Row(
            children: <Widget>[
              // Vertical TabBar on the side
              Material(
                // Optional: to provide a background color and elevation
                elevation: 4.0, // Example elevation
                child: RotatedBox(
                  // Use RotatedBox if you want to reuse TabBar, but it can be tricky
                  // A custom Column of InkWell/GestureDetector widgets might be easier for vertical tabs
                  quarterTurns: 3, // Rotate a horizontal TabBar to be vertical
                  // Note: This might not look perfect and might need width constraints
                  child: TabBar(
                    controller: _tabController,
                    isScrollable:
                        false, // Likely needed for vertical tabs if text is present
                    indicatorWeight: 2.0, // Adjust as needed
                    indicatorSize: TabBarIndicatorSize.tab, // Adjust as needed
                    labelPadding: EdgeInsets.fromLTRB(0.0, 8, 0, 8),
                    tabs: tabWidgets
                        .map((tab) => RotatedBox(quarterTurns: 1, child: tab))
                        .toList(), // Counter-rotate tab content
                    // You might need to set a specific width for this vertical TabBar
                    // e.g., using a SizedBox or ConstrainedBox
                  ),
                ),
              ),

              // Alternative: A custom vertical tab bar implementation
              // buildVerticalTabBar(context, _tabController, tabWidgets, s),
              Expanded(child: tabBarViewWidget),
            ],
          ),
        ),
      );
    }
  }

  void _onProjectDetailsChanged(
    ProjectModel updatedProject, {
    bool hasUnsavedChanges = false,
    DateTime? projectDate,
    DateTime? lastUpdateTime,
  }) {
    setState(() {
      _currentProject = updatedProject;
      _hasUnsavedChanges = hasUnsavedChanges;
      if (projectDate != null) _projectDate = projectDate;
      if (lastUpdateTime != null) _lastUpdateTime = lastUpdateTime;
    });
  }

  void _onPointsChanged() {
    logger.info(
      "ProjectDetailsPage: Points changed, reloading project details.",
    );
    _loadProjectDetails(); // Reload project details to get new start/end IDs
    _pointsToolViewKey.currentState
        ?.refreshPoints(); // Ensure PointsToolView itself also refreshes its internal list
  }

  void _onCompassAction() {
    setState(() {
      // Optionally reload project or update state if needed
    });
  }

  void _onMapAction() {
    setState(() {
      // Optionally reload project or update state if needed
    });
  }
}
