// project_details_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/project_tools/points_tool_view.dart';

import 'db/database_helper.dart'; // Ensure correct path
import 'db/models/point_model.dart';
import 'db/models/project_model.dart'; // Ensure correct path
import 'logger.dart';
import 'project_tools/compass_tool_view.dart';
import 'project_tools/map_tool_view.dart';

// At the top of project_details_page.dart, or in a separate file
enum ActiveCardTool { compass, points, map }

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

class ProjectDetailsPage extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _azimuthController;

  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;

  late ProjectModel _currentProject;

  ActiveCardTool? _activeCardTool; // To track the currently active Card button

  // Tracks if the form fields have changes not yet saved
  bool _isFormCurrentlyDirty = false;
  bool _isLoading = false;

  // Tracks if a save occurred this session
  bool _projectWasSavedThisSession = false;

  // To know if the project was new when the page was opened
  bool _isNewProjectOnLoad = false;
  // Store initial values to compare against for dirty checking
  String? _initialName;
  String? _initialNote;
  String? _initialAzimuthText;
  DateTime? _initialProjectDate;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // GlobalKey to access PointsToolView's state if needed for refresh
  // This is one way to trigger refresh. Another is to manage points list here.
  final GlobalKey<PointsToolViewState> _pointsToolViewKey =
      GlobalKey<PointsToolViewState>();

  // State variable to control CompassToolView's spinner for this action
  bool _isAddingPointFromCompassInProgress = false;
  // ID of the most recently added point (for adding NEW icon)
  int? _newlyAddedPointId;

  @override
  void initState() {
    super.initState();
    _currentProject =
        widget.project; // Initialize with the project passed to the widget

    _isNewProjectOnLoad = _currentProject.id == null;
    _nameController = TextEditingController(text: _currentProject.name);
    _noteController = TextEditingController(text: _currentProject.note ?? '');
    _azimuthController = TextEditingController(
      text: _currentProject.azimuth?.toStringAsFixed(2) ?? '',
    );
    _projectDate =
        _currentProject.date ?? (_isNewProjectOnLoad ? DateTime.now() : null);
    _lastUpdateTime = _currentProject.lastUpdate;

    _setInitialFormValuesAndResetDirtyState(); // Set baseline and mark form as not dirty

    // Add listeners
    _nameController.addListener(_handleFormChange);
    _noteController.addListener(_handleFormChange);
    _azimuthController.addListener(_handleFormChange);

    if (!_isNewProjectOnLoad) {
      // Only load if it's an existing project
      _loadProjectDetails();
    } else {
      logger.info(
        "ProjectDetailsPage initialized for a NEW project. Name: ${_currentProject.name}",
      );
    }
  }

  Future<void> _loadProjectDetails() async {
    if (_currentProject.id == null) {
      logger.warning(
        "_loadProjectDetails called with null project ID. This shouldn't happen for existing projects.",
      );
      // Optionally, set loading to false and return if this state is unexpected
      // setStateIfMounted(() => _isLoading = false);
      return;
    }
    setStateIfMounted(() => _isLoading = true);
    try {
      final projectDataFromDb = await _dbHelper.getProjectById(
        _currentProject.id!,
      );
      if (projectDataFromDb != null && mounted) {
        setState(() {
          _currentProject = (projectDataFromDb);

          _nameController.text = _currentProject.name;
          _noteController.text = _currentProject.note ?? '';
          _azimuthController.text =
              _currentProject.azimuth?.toStringAsFixed(2) ?? '';
          _projectDate = _currentProject.date;
          _lastUpdateTime = _currentProject.lastUpdate;

          // After loading data and updating controllers, reset the baseline
          _setInitialFormValuesAndResetDirtyState();
        });
      } else if (mounted) {
        // Handle case where project is not found in DB (e.g., deleted elsewhere)
        logger.warning(
          "Project with ID ${_currentProject.id} not found in database during load.",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: Project (ID: ${_currentProject.id}) not found. It might have been deleted.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        // Optionally, you might want to pop the page if the project doesn't exist anymore
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      logger.severe(
        "Error loading project details for ID: ${_currentProject.id}",
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading project data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // You might want to set some state here to indicate an error,
      // e.g., if you have a specific UI for error states.
      // setStateIfMounted(() {
      //   _hasLoadingError = true; // Example state variable
      // });
    } finally {
      setStateIfMounted(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleFormChange);
    _noteController.removeListener(_handleFormChange);
    _azimuthController.removeListener(_handleFormChange);
    _nameController.dispose();
    _noteController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  void _setInitialFormValuesAndResetDirtyState() {
    _initialName = _nameController.text;
    _initialNote = _noteController.text;
    _initialAzimuthText = _azimuthController.text;
    _initialProjectDate = _projectDate;

    if (mounted && _isFormCurrentlyDirty) {
      setState(() {
        _isFormCurrentlyDirty = false;
      });
    } else {
      _isFormCurrentlyDirty =
          false; // Directly set if not mounted or no change needed
    }
  }

  void _handleFormChange() {
    final bool changed =
        _nameController.text != _initialName ||
        _noteController.text != _initialNote ||
        _azimuthController.text != _initialAzimuthText ||
        _projectDate != _initialProjectDate;

    if (changed != _isFormCurrentlyDirty) {
      setStateIfMounted(() {
        _isFormCurrentlyDirty = changed;
      });
    }
  }

  void _toggleActiveCardTool(ActiveCardTool? tool) {
    setState(() {
      if (_activeCardTool == tool || tool == null) {
        _activeCardTool = null; // Deactivate if already active
      } else {
        _activeCardTool = tool; // Activate the new tool
      }
      logger.info("Active Card tool toggled to: $_activeCardTool");
    });
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

  Future<int> _getNextOrdinalNumber(int projectId) async {
    final lastOrdinal = await _dbHelper.getLastPointOrdinal(projectId);
    return (lastOrdinal ?? -1) + 1; // If no points, next ordinal is 0
  }

  Future<void> _initiateAddPointFromCompass(
    double heading, {
    bool? setAsEndPoint, // Added optional named parameter
  }) async {
    final bool addAsEndPoint =
        setAsEndPoint ?? false; // Default to false if null

    logger.info(
      "Initiating add point. Heading: $heading, Project ID: ${_currentProject.id}, Explicit End Point: $setAsEndPoint",
    );

    if (_currentProject.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please save the project before adding points.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // If we bail early, ensure the spinner is stopped if it was started
      if (mounted && _isAddingPointFromCompassInProgress) {
        setState(() => _isAddingPointFromCompassInProgress = false);
      }
      return;
    }

    // START loading indicator in CompassToolView by setting state
    if (mounted) {
      setState(() {
        _isAddingPointFromCompassInProgress = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fetching location...'),
        duration: Duration(seconds: 2), // Short duration
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
          newPointOrdinal =
              originalEndPointOrdinal ??
              await _getNextOrdinalNumber(_currentProject.id!);

          // The OLD end point needs a new, higher ordinal
          final int newOrdinalForOldEndPoint = await _getNextOrdinalNumber(
            _currentProject.id!,
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
          newPointOrdinal = await _getNextOrdinalNumber(_currentProject.id!);
        }
      } else {
        // --- Case 2: Setting as new end point OR no existing end point to shuffle ---
        newPointOrdinal = await _getNextOrdinalNumber(_currentProject.id!);
      }

      final pointFromCompass = PointModel(
        projectId: _currentProject.id!,
        latitude: position.latitude,
        longitude: position.longitude,
        ordinalNumber: newPointOrdinal,
        // You might want a default note or a way to add one later
        note: 'Point from Compass (H: ${heading.toStringAsFixed(1)}°)',
        heading: heading, // FIXME: what about the timestamp????
      );

      final newPointIdFromCompass = await _dbHelper.insertPoint(
        pointFromCompass,
      );
      logger.info(
        'Point added via Compass: ID $newPointIdFromCompass, Lat: ${position.latitude}, Lon: ${position.longitude}, Heading used for note: $heading, Ordinal: ${pointFromCompass.ordinalNumber}',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Point P${pointFromCompass.ordinalNumber} added. ${addAsEndPoint ? "Set as END point." : (currentEndPointModel != null ? "Inserted before current end point." : "")}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh PointsToolView if it's active or if you always want it updated
      _pointsToolViewKey.currentState
          ?.refreshPoints(); // Call refreshPoints on PointsToolView

      // If the compass tool is active, and you want to switch to points view:
      // TODO: should we switch views? If not, remove this
      if (_activeCardTool == ActiveCardTool.compass) {
        _toggleActiveCardTool(ActiveCardTool.points);
      }
    } catch (e, stackTrace) {
      logger.severe("Error adding point from compass", e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding point: ${e.toString()}'),
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

  Future<void> _saveProjectDetails() async {
    // 1. Check if there are actual changes to save or if it's a new project
    //    (New projects can be "saved" even if no fields were touched yet, to create the initial record)
    if (!_isFormCurrentlyDirty && !_isNewProjectOnLoad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. Prevent saving if a card tool is active
    if (_activeCardTool != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Close the active tool to modify project details.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 3. Validate the form
    if (!_formKey.currentState!.validate()) {
      logger.warning("Form validation failed.");
      // Optionally, show a SnackBar if you want more explicit feedback than just field errors
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Please correct the errors in the form.'),
      //     backgroundColor: Colors.orange,
      //   ),
      // );
      return;
    }

    // If all checks pass, proceed with saving
    setStateIfMounted(() => _isLoading = true);

    // Parse Azimuth (validator should have caught errors, but good to be safe)
    double? azimuthValue;
    if (_azimuthController.text.isNotEmpty) {
      azimuthValue = double.tryParse(_azimuthController.text);
      if (azimuthValue == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Internal error: Invalid Azimuth despite validation.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setStateIfMounted(() => _isLoading = false);
        return;
      }
    }

    // Prepare the project model to save
    // Note: For a new project, widget.project.id will be null.
    // startingPointId and endingPointId are preserved from the current widget.project state
    ProjectModel projectToSave = ProjectModel(
      id: _currentProject.id,
      name: _nameController.text.trim(), // Trim whitespace
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      azimuth: azimuthValue,
      date: _projectDate,
      startingPointId: _currentProject.startingPointId,
      endingPointId: _currentProject.endingPointId,
      // lastUpdate will be set by the database or on successful save
    );

    try {
      String successMessage;
      if (projectToSave.id == null) {
        // ---- CREATING A NEW PROJECT ----
        final newId = await _dbHelper.insertProject(projectToSave);
        // Fetch the newly saved project to get all DB-generated fields (like lastUpdate and the ID itself)
        final savedProject = await _dbHelper.getProjectById(newId);

        if (savedProject != null && mounted) {
          setState(() {
            // Update the page's main project instance with the saved data
            _currentProject = savedProject;

            // Update controllers and local state to reflect the fully saved state
            _nameController.text =
                _currentProject.name; // Should match, but good practice
            _noteController.text = _currentProject.note ?? '';
            _azimuthController.text =
                _currentProject.azimuth?.toStringAsFixed(2) ?? '';
            _projectDate = _currentProject.date;
            _lastUpdateTime = _currentProject.lastUpdate; // Crucial for display

            _projectWasSavedThisSession =
                true; // Mark that a save operation happened
            // _isNewProjectOnLoad =
            //     false; // It's no longer "new" in the context of this page load
            // FIXME: it actually should stay "new" even after saving

            // After saving, the form is now based on the saved data, so reset dirty check
            _setInitialFormValuesAndResetDirtyState();
          });
          successMessage = 'Project "${_currentProject.name}" created.';
          logger.info(
            "New project created and state updated. ID: $newId, Name: ${_currentProject.name}",
          );
        } else {
          throw Exception("Failed to retrieve the newly created project.");
        }
      } else {
        // ---- UPDATING AN EXISTING PROJECT ----
        await _dbHelper.updateProject(projectToSave);
        // Fetch the updated project to get new lastUpdate, etc.
        final updatedProjectFromDb = await _dbHelper.getProjectById(
          projectToSave.id!,
        );

        if (updatedProjectFromDb != null && mounted) {
          setState(() {
            // Update the page's main project instance
            _currentProject = updatedProjectFromDb;

            // Update controllers and local state
            _nameController.text = _currentProject.name;
            _noteController.text = _currentProject.note ?? '';
            _azimuthController.text =
                _currentProject.azimuth?.toStringAsFixed(2) ?? '';
            _projectDate = _currentProject.date;
            _lastUpdateTime = _currentProject.lastUpdate;

            _projectWasSavedThisSession =
                true; // Mark that a save operation happened

            // After saving, the form is now based on the saved data, so reset dirty check
            _setInitialFormValuesAndResetDirtyState();
          });
          successMessage = 'Project "${_currentProject.name}" updated.';
          logger.info(
            "Project details updated and state refreshed for ID: ${_currentProject.id}, Name: ${_currentProject.name}",
          );
        } else {
          throw Exception(
            "Failed to retrieve the updated project (ID: ${projectToSave.id}).",
          );
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.severe("Error saving project details", e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setStateIfMounted(() => _isLoading = false);
    }
  }

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
        _handleFormChange(); // Call the unified handler
      });
    } else if (pickedDate == null && _projectDate != null && mounted) {
      // Handle clearing date
      setState(() {
        _projectDate = null;
        _handleFormChange();
      });
    }
  }

  Future<void> _calculateAzimuth() async {
    logger.info(
      "Calculate Azimuth button tapped for project: ${_currentProject.name}",
    );

    if (_activeCardTool != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Close the active tool before calculating azimuth.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final int? startPointId = _currentProject.startingPointId;
    final int? endPointId = _currentProject.endingPointId;

    if (startPointId == null || endPointId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Starting and/or ending point not set. Cannot calculate azimuth.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      _azimuthController.text = '';
      _currentProject.azimuth = null;
      return;
    }

    if (startPointId == endPointId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Starting and ending points are the same. Azimuth is undefined or 0.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      _azimuthController.text = '';
      _currentProject.azimuth = null;
      return;
    }

    try {
      final PointModel? startPoint = await _dbHelper.getPointById(startPointId);
      final PointModel? endPoint = await _dbHelper.getPointById(endPointId);

      if (startPoint == null || endPoint == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not retrieve point data for calculation. Please check points.',
              ),
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

      setState(() {
        _azimuthController.text = calculatedAzimuth.toStringAsFixed(2);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Azimuth calculated: ${calculatedAzimuth.toStringAsFixed(2)}°',
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
            content: Text('Error calculating azimuth: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSetPoint(String pointType) {
    logger.info("Set $pointType Point button tapped.");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set $pointType point to be implemented.')),
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: Text(
        _currentProject.name.isNotEmpty && _nameController.text.isNotEmpty
            ? _nameController
                  .text // Use controller text for potentially unsaved name
            : (_currentProject.name.isNotEmpty
                  ? _currentProject.name
                  : "Project Details"),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.save_outlined,
            color: _isFormCurrentlyDirty && !_isLoading
                ? Colors
                      .greenAccent
                      .shade400 // "Glowing" green
                : null, // Default color
          ),
          tooltip: 'Save Project',
          onPressed:
              (_isFormCurrentlyDirty || _isNewProjectOnLoad) && !_isLoading
              ? _saveProjectDetails
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
      formattedProjectDate = 'Tap to set date';
    }
    String formattedLastUpdate = _lastUpdateTime != null
        ? DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_Hm().format(_lastUpdateTime!) // Also localize time
        : 'Not yet saved';

    bool isMainFormVisible = _activeCardTool == null;

    return WillPopScope(
      onWillPop: _onWillPop, // Assign the callback
      child: Scaffold(
        appBar: _appBar(),
        // --- WRAP MAIN CONTENT WITH FORM ---
        body: Form(
          key: _formKey, // Assign the key to the Form
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Project Tools",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                // Define a threshold for switching layout
                                // You might need to adjust this value based on testing
                                const double narrowLayoutThreshold =
                                    350.0; // e.g., for total width of 3 buttons
                                const double buttonSpacing =
                                    8.0; // spacing between buttons

                                bool useVerticalLayout =
                                    constraints.maxWidth <
                                    narrowLayoutThreshold;

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    _buildCardToolButton(
                                      tool: ActiveCardTool.compass,
                                      icon: Icons.explore_outlined,
                                      label: 'Compass',
                                      useVerticalLayout:
                                          useVerticalLayout, // Pass the flag
                                    ),
                                    if (useVerticalLayout)
                                      const SizedBox(width: buttonSpacing),
                                    _buildCardToolButton(
                                      tool: ActiveCardTool.points,
                                      icon: Icons.list_alt_outlined,
                                      label: 'Points',
                                      useVerticalLayout:
                                          useVerticalLayout, // Pass the flag
                                    ),
                                    if (useVerticalLayout)
                                      const SizedBox(width: buttonSpacing),
                                    _buildCardToolButton(
                                      tool: ActiveCardTool.map,
                                      icon: Icons.map_outlined,
                                      label: 'Map',
                                      useVerticalLayout:
                                          useVerticalLayout, // Pass the flag
                                    ),
                                  ],
                                );
                              },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Conditional Main Form Area ---
                if (isMainFormVisible)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextFormField(
                        controller: _nameController,
                        label: "Project Name",
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Project name cannot be empty.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Project Date",
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 11.0,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            formattedProjectDate,
                            style: const TextStyle(fontSize: 18.0),
                          ),
                          trailing: const Icon(Icons.calendar_month_outlined),
                          onTap: () => _selectProjectDate(context),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 5.0,
                          ),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_noteController, "Notes", maxLines: 4),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _azimuthController,
                              label: "Azimuth (°)",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid number format.';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton(
                              onPressed: _calculateAzimuth,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text("Calculate"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                        "Last Updated",
                        formattedLastUpdate,
                        textStyle: const TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _majorActionButton(
                              Icons.flag_outlined,
                              'SET START',
                              () => _onSetPoint("Start"),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _majorActionButton(
                              Icons.sports_score_outlined,
                              'SET END',
                              () => _onSetPoint("End"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                else // Show placeholder if a card tool is active
                  _buildActiveToolView(), // Call helper to display the active tool's widget
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_activeCardTool != null) {
      // If a tool is active, the first back press should close the tool
      _toggleActiveCardTool(
        null,
      ); // Assuming this method sets _activeCardTool to null and rebuilds
      return false; // Prevent immediate pop, let the UI update to close the tool
    }

    if (_isFormCurrentlyDirty) {
      final bool? discardChanges = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them and go back?',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Discard'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      if (discardChanges == null || !discardChanges) {
        return false; // User cancelled or dialog dismissed, do not pop
      }
      // If user chose to discard, proceed to pop but indicate no *new* save happened for this specific pop action
      // _projectWasSavedThisSession remains as is.
    }

    // If no tool is active, proceed to pop with results
    Map<String, dynamic> result = {
      'modified': _projectWasSavedThisSession,
      'id': _currentProject
          .id, // This will be the new ID if it was a new project and saved
      'isNew':
          _isNewProjectOnLoad &&
          _projectWasSavedThisSession &&
          _currentProject.id != null,
      // 'isNew': _isNewProjectOnLoad && !_projectWasSavedThisSession, // Logic if it was new AND no save occurred
      // More accurate 'isNew' for the calling page if it wants to know if THIS project (by id) was just created
    };
    logger.info("Popping ProjectDetailsPage with result: $result");
    // FIXME: actually we should return some values, but for now just a bool will do, so the full list is reloaded. Simplify logic to remove _isNewProjectOnLoad, since now we must manually save then pop
    if (mounted) Navigator.pop(context, result);
    return true; // Allow pop after manually calling Navigator.pop
    // Or `return false` if Navigator.pop already handled it and you don't want
    // WillPopScope to pop again. `true` is usually fine here since we popped.
  }

  // --- Helper to build toggleable Card Tool Buttons ---
  Widget _buildCardToolButton({
    required ActiveCardTool tool,
    required IconData icon,
    required String label,
    required bool useVerticalLayout, // New parameter
  }) {
    bool isActive = _activeCardTool == tool;
    final Color? activeForegroundColor = isActive
        ? Theme.of(context).colorScheme.onPrimary
        : null;
    final Color? activeBackgroundColor = isActive
        ? Theme.of(context).colorScheme.primary
        : null;
    final ButtonStyle activeStyle = ElevatedButton.styleFrom(
      foregroundColor: activeForegroundColor,
      backgroundColor: activeBackgroundColor,
      padding: useVerticalLayout
          ? const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 4.0,
            ) // Adjust padding for vertical
          : const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ), // Original or adjusted padding
      textStyle: const TextStyle(
        fontSize: 12,
      ), // Potentially smaller text for vertical
    );

    if (useVerticalLayout) {
      return Expanded(
        // Ensure buttons take up available space in the Row
        child: ElevatedButton(
          style: activeStyle,
          onPressed: () => _toggleActiveCardTool(tool),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // So the column doesn't expand unnecessarily
            children: <Widget>[
              Icon(icon, size: 24), // Adjust size as needed
              const SizedBox(height: 4), // Space between icon and label
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    } else {
      // Using Flexible or Expanded so buttons can share space,
      // but ElevatedButton.icon already handles its sizing well.
      // If they still overflow, wrap with Expanded.
      return ElevatedButton.icon(
        style: activeStyle,
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: () => _toggleActiveCardTool(tool),
      );
    }
  }

  // If PointsToolView handles its own additions/deletions and calls DB directly:
  // PointsToolView would also need to call _dbHelper.updateProjectStartEndPoints(projectId)
  // and then notify ProjectDetailsPage to reload project details (e.g., via a callback).
  // For now, _initiateAddPointFromCompass is the main adder.
  // Deletions from PointsToolView will trigger the DB helper's updated delete methods.
  // After deletion in PointsToolView, it calls _loadPoints, which is good.
  // We also need ProjectDetailsPage to be aware that widget.project start/end might have changed.
  // This can be done by passing a callback from ProjectDetailsPage to PointsToolView
  // that PointsToolView calls after a successful deletion, which then calls _loadProjectDetails.

  // Example callback for PointsToolView:
  void _onPointsChanged() async {
    logger.info(
      "ProjectDetailsPage: Points changed, reloading project details.",
    );
    await _loadProjectDetails(); // Reload project details to get new start/end IDs
    _pointsToolViewKey.currentState
        ?.refreshPoints(); // Ensure PointsToolView itself also refreshes its internal list
  }

  Widget _buildActiveToolView() {
    // FIXME: is this necessary?
    // if (_activeCardTool == null) {
    //   return _buildProjectForm();
    // }

    switch (_activeCardTool) {
      case ActiveCardTool.compass:
        return CompassToolView(
          project: _currentProject,
          onAddPointFromCompass:
              _initiateAddPointFromCompass, // Pass the callback
          isAddingPoint: _isAddingPointFromCompassInProgress,
        );
      case ActiveCardTool.points:
        return PointsToolView(
          key: _pointsToolViewKey, // Assign the GlobalKey
          project: _currentProject,
          onPointsChanged: _onPointsChanged,
          newlyAddedPointId: _newlyAddedPointId,
        );
      case ActiveCardTool.map:
        // If the parent of this Column is scrollable, MapToolView needs constraints.
        // Option A: Give it a fixed height
        return SizedBox(
          height:
              MediaQuery.of(context).size.height *
              0.6, // e.g., 60% of screen height
          child: MapToolView(project: _currentProject),
        );
      // Option B: If _buildActiveCardToolView is already in a context that allows expansion
      // return Expanded(
      //   // Or Flexible
      //   child: MapToolView(project: _currentProject),
      // );
      default:
        return const SizedBox.shrink();
    }
  }

  // Original _buildTextField for fields without form validation (like Notes)
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 18.0,
        ),
      ),
      style: const TextStyle(fontSize: 18.0),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  // --- New _buildTextFormField helper ---
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 18.0,
        ),
      ),
      style: const TextStyle(fontSize: 18.0),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: autovalidateMode, // Show errors as user interacts
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value, {
    TextStyle? textStyle,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 18.0),
      ),
      child: Text(value, style: textStyle ?? const TextStyle(fontSize: 18.0)),
    );
  }

  Widget _majorActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }
}
