import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/pages/point_details_page.dart';
import 'package:teleferika/ui/widgets/compass_calibration_panel.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

import 'debug/debug_panel.dart';
import 'state/map_state_manager.dart';
import 'widgets/flutter_map_widget.dart';
import 'widgets/map_loading_widget.dart';
import 'widgets/point_details_panel.dart';
import 'widgets/floating_action_buttons.dart';
import 'widgets/map_type_selector.dart';

class MapToolView extends StatefulWidget {
  final ProjectModel project;
  final String? selectedPointId;
  final VoidCallback? onNavigateToCompassTab;

  const MapToolView({
    super.key,
    required this.project,
    this.selectedPointId,
    this.onNavigateToCompassTab,
  });

  @override
  State<MapToolView> createState() => MapToolViewState();
}

class MapToolViewState extends State<MapToolView>
    with StatusMixin, TickerProviderStateMixin {
  final Logger logger = Logger('MapToolView');

  // State manager
  late MapStateManager _stateManager;

  @override
  void initState() {
    super.initState();
    _stateManager = MapStateManager();
    _stateManager.selectedPointId = widget.selectedPointId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize state manager with current project from global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;
    _stateManager.initialize(this, currentProject);

    if (!_stateManager.didInitialLoad) {
      _stateManager.didInitialLoad = true;
      _loadProjectPoints();
    }
  }

  @override
  void didUpdateWidget(covariant MapToolView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Get current project from global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;
    final oldProject = oldWidget.project;

    if (currentProject.id != oldProject.id && !_stateManager.isLoadingPoints) {
      _loadProjectPoints();
    } else if (currentProject.startingPointId != oldProject.startingPointId ||
        currentProject.endingPointId != oldProject.endingPointId) {
      // Project start/end points changed, reload points to get updated data
      // But skip if we're in the middle of saving a new point
      if (!_stateManager.skipNextFitToPoints &&
          !_stateManager.isLoadingPoints) {
        _loadProjectPoints();
      }
    }

    if (widget.selectedPointId != oldWidget.selectedPointId) {
      _stateManager.selectedPointId = widget.selectedPointId;
      setState(() {}); // Only call setState once after updating state
    }
  }

  @override
  void dispose() {
    _stateManager.dispose();
    super.dispose();
  }

  // Handle permission results from the PermissionHandlerWidget
  void _handlePermissionResults(Map<PermissionType, bool> permissions) {
    final hasLocation = permissions[PermissionType.location] ?? false;
    final hasSensor = permissions[PermissionType.sensor] ?? false;

    _stateManager.handlePermissionResults(context, permissions);

    if (hasLocation) {
      showInfoStatus(
        'Location permission granted. Map features are now available.',
      );
    } else {
      showInfoStatus(
        'Location permission denied. Map features requiring location will be limited.',
      );
    }

    if (hasSensor) {
      showInfoStatus(
        'Sensor permission granted. Device orientation features are now available.',
      );
    } else {
      showInfoStatus(
        'Sensor permission denied. Device orientation features will be unavailable.',
      );
    }
  }

  Future<void> _loadProjectPoints() async {
    await _stateManager.loadProjectPoints(context);
    setState(() {});
  }

  Future<void> _handleMovePoint(
    PointModel pointToMove,
    LatLng newPosition,
  ) async {
    await _stateManager.handleMovePoint(context, pointToMove, newPosition);
    if (!mounted) return;
    setState(() {});
    showSuccessStatus('Point ${pointToMove.name} moved (pending save)!');
  }

  void _centerOnCurrentLocation() {
    _stateManager.centerOnCurrentLocation(context);
    showSuccessStatus('Centered on your current location.');
  }

  void _handleAddPointButtonPressed() async {
    await _stateManager.handleAddPointButtonPressed(context);
    if (!mounted) return;
    setState(() {});

    if (_stateManager.newPoint != null) {
      showInfoStatus(
        'New point created. Tap "Save" to add it to your project.',
      );
    }
  }

  Future<void> _handleSaveNewPoint() async {
    await _stateManager.handleSaveNewPoint(context);
    if (!mounted) return;
    setState(() {});
    final s = S.of(context);
    showSuccessStatus(s?.mapNewPointSaved ?? 'New point saved (pending save)!');
  }

  void _handleDiscardNewPoint() {
    _stateManager.handleDiscardNewPoint(context);
    setState(() {});
    showInfoStatus('New point discarded.');
  }

  Future<void> _handleEditPoint(PointModel point) async {
    logger.info("Navigating to edit point ${point.name}");

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => PointDetailsPage(point: point)),
    );

    if (result != null && mounted) {
      final action = result['action'] as String?;

      if (action == 'updated') {
        final updatedPoint = result['point'] as PointModel?;
        if (updatedPoint != null) {
          // Do NOT call updatePointInEditingState again; PointDetailsPage already did it and notified listeners
          setState(() {
            _stateManager.recalculateAndDrawLines(context);
          });
          logger.info(
            "Point ${updatedPoint.name} details updated (pending save)!",
          );
          showSuccessStatus(
            'Point ${updatedPoint.name} details updated (pending save)!',
          );
        }
      } else if (action == 'deleted') {
        final pointId = result['pointId'] as String?;
        if (pointId != null) {
          // Use global state to delete the point in memory
          final projectState = Provider.of<ProjectStateManager>(
            context,
            listen: false,
          );
          projectState.deletePointInEditingState(pointId);
          setState(() {
            if (_stateManager.selectedPointId == pointId) {
              _stateManager.selectedPointId = null;
            }
            _stateManager.recalculateAndDrawLines(context);
          });
          logger.info("Point deleted from MapToolView.");
          showSuccessStatus('Point deleted (pending save)!');
        }
      }
    }
  }

  void _handleMovePointAction() {
    _stateManager.handleMovePointAction(context);
    setState(() {});

    if (_stateManager.isMovePointMode) {
      showInfoStatus('Move mode activated. Tap map to relocate point.');
    }
  }

  Future<void> _handleDeletePoint(PointModel point) async {
    logger.info("Delete tapped for point ${point.name}");
    await _handleDeletePointFromPanel(point);
  }

  Future<void> _handleDeletePointFromPanel(PointModel pointToDelete) async {
    final s = S.of(context);
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(s?.mapDeletePointDialogTitle ?? 'Delete Point'),
          content: Text(
            s?.mapDeletePointDialogContent(pointToDelete.name) ??
                'Are you sure you want to delete point ${pointToDelete.name}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s?.buttonCancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(s?.buttonDelete ?? 'Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      try {
        // Use global state to delete the point in memory
        final projectState = Provider.of<ProjectStateManager>(
          context,
          listen: false,
        );
        projectState.deletePointInEditingState(pointToDelete.id);

        setState(() {
          logger.info(
            "Point ${pointToDelete.name} (ID: ${pointToDelete.id}) removed from MapToolView after panel delete.",
          );
          if (_stateManager.selectedPointId == pointToDelete.id) {
            _stateManager.selectedPointId = null;
          }
        });

        showSuccessStatus(
          s?.point_deleted_pending_save(pointToDelete.name) ??
              'Point ${pointToDelete.name} deleted (pending save).',
        );
      } catch (e) {
        if (!mounted) return;
        logger.severe(
          'Failed to delete point ${pointToDelete.name} from panel: $e',
        );

        showErrorStatus(
          s?.error_deleting_point_generic(pointToDelete.name, e.toString()) ??
              'Error deleting point ${pointToDelete.name}: ${e.toString()}',
        );
      }
    }
  }

  void _handlePointTap(PointModel point) {
    setState(() {
      if (_stateManager.selectedPointId == point.id) {
        _stateManager.selectedPointId = null;
      } else {
        _stateManager.selectedPointId = point.id;
      }
    });
  }

  // Handle point updates from inline editing
  Future<void> _handlePointUpdated(PointModel updatedPoint) async {
    await _stateManager.handlePointUpdated(context, updatedPoint);
    if (!mounted) return;
    setState(() {});

    if (updatedPoint.isUnsaved) {
      showSuccessStatus('Point ${updatedPoint.name} updated!');
    } else {
      showSuccessStatus('Point ${updatedPoint.name} updated (pending save)!');
    }
  }

  /// Public method to refresh points from the database
  /// This can be called from the parent component when points are reordered
  Future<void> refreshPoints() async {
    logger.info("MapToolView: External refresh requested.");
    await _stateManager.refreshPoints(context);
    if (!mounted) return;
    setState(() {});
  }

  /// Public method to undo changes (reload from DB)
  Future<void> undoChanges() async {
    await _stateManager.undoChanges(context);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _stateManager,
      child: Consumer<ProjectStateManager>(
        builder: (context, projectState, child) {
          // Always recalculate lines when state changes
          _stateManager.recalculateAndDrawLines(context);

          if (_stateManager.isLoadingPoints) {
            return MapLoadingWidget(
              currentStatus: currentStatus,
              onDismissStatus: hideStatus,
            );
          }

          // Get points from global state
          final points = projectState.currentPoints;

          final List<LatLng> polylinePathPoints = _buildPolylinePathPoints();
          final connectingLine = _buildConnectingLine();

          LatLng initialMapCenter = _stateManager.controller.getInitialCenter(
            points,
            _stateManager.currentPosition,
          );
          double initialMapZoom = _stateManager.controller.getInitialZoom(
            points,
            _stateManager.currentPosition,
          );

          if (initialMapCenter.latitude.isNaN ||
              initialMapCenter.longitude.isNaN ||
              initialMapZoom.isNaN ||
              initialMapZoom.isInfinite) {
            return Stack(
              children: [
                const Center(child: Text('Waiting for valid map data...')),
                Positioned(
                  top: 24,
                  right: 24,
                  child: StatusIndicator(
                    status: currentStatus,
                    onDismiss: hideStatus,
                  ),
                ),
              ],
            );
          }

          // Get the selected point from the latest global state
          PointModel? selectedPoint;
          if (_stateManager.selectedPointId != null) {
            if (_stateManager.newPoint != null &&
                _stateManager.newPoint!.id == _stateManager.selectedPointId) {
              selectedPoint = _stateManager.newPoint;
            } else {
              try {
                selectedPoint = points.firstWhere(
                  (p) => p.id == _stateManager.selectedPointId,
                );
              } catch (_) {
                selectedPoint = null;
              }
            }
          }

          try {
            return PermissionHandlerWidget(
              requiredPermissions: [
                PermissionType.location,
                PermissionType.sensor,
              ],
              onPermissionsResult: _handlePermissionResults,
              showOverlay: true,
              child: Stack(
                children: [
                  Scaffold(
                    body: Stack(
                      children: [
                        FlutterMapWidget(
                          polylinePathPoints: polylinePathPoints,
                          connectingLine: connectingLine,
                          projectHeadingLine: _stateManager.projectHeadingLine,
                          initialMapCenter: initialMapCenter,
                          initialMapZoom: initialMapZoom,
                          tileLayerUrl: _stateManager.controller
                              .getTileLayerUrl(_stateManager.currentMapType),
                          tileLayerAttribution: _stateManager.controller
                              .getTileLayerAttribution(
                                _stateManager.currentMapType,
                              ),
                          attributionUrl: _stateManager.controller
                              .getAttributionUrl(_stateManager.currentMapType),
                          mapController: _stateManager.mapController,
                          isMapReady: _stateManager.isMapReady,
                          isLoadingPoints: _stateManager.isLoadingPoints,
                          isMovePointMode: _stateManager.isMovePointMode,
                          selectedPointId: _stateManager.selectedPointId,
                          currentPosition: _stateManager.currentPosition,
                          hasLocationPermission:
                              _stateManager.hasLocationPermission,
                          connectingLineFromFirstToLast:
                              _stateManager.connectingLineFromFirstToLast,
                          glowAnimationValue: _stateManager.glowAnimationValue,
                          currentDeviceHeading:
                              _stateManager.currentDeviceHeading,
                          locationStreamController:
                              _stateManager.locationStreamController,
                          arrowheadAnimation: _stateManager.arrowheadAnimation,
                          onPointTap: _handlePointTap,
                          onMovePoint: _handleMovePoint,
                          onMapReady: () {
                            setState(() {
                              _stateManager.isMapReady = true;
                            });
                            _stateManager.fitMapToPoints(context);
                          },
                          onDeselectPoint: () {
                            setState(() {
                              _stateManager.selectedPointId = null;
                            });
                          },
                        ),
                        MapTypeSelector.build(
                          currentMapType: _stateManager.currentMapType,
                          onMapTypeChanged: (mapType) {
                            setState(() {
                              _stateManager.currentMapType = mapType;
                            });
                          },
                          context: context,
                        ),
                        // Debug button below map type selector (always visible)
                        Positioned(
                          top: 60,
                          left: 16,
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.bug_report_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              'Debug',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _stateManager.hasClosedDebugPanel = false;
                              });
                            },
                          ),
                        ),
                        _buildPointDetailsPanel(selectedPoint),
                        Positioned(
                          bottom: 24,
                          left: 24,
                          child: FloatingActionButtons.build(
                            context: context,
                            hasLocationPermission:
                                _stateManager.hasLocationPermission,
                            currentPosition: _stateManager.currentPosition,
                            onCenterOnLocation: _centerOnCurrentLocation,
                            onAddPoint: _handleAddPointButtonPressed,
                            onCenterOnPoints: () =>
                                _stateManager.fitMapToPoints(context),
                            isAddingNewPoint:
                                _stateManager.isAddingNewPoint ||
                                _stateManager.newPoint != null,
                          ),
                        ),
                        // Debug panel only appears if _hasClosedDebugPanel is false
                        if (!_stateManager.hasClosedDebugPanel)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: DebugPanel(
                              onClose: () {
                                setState(() {
                                  _stateManager.hasClosedDebugPanel = true;
                                });
                              },
                              onTestCalibrationPanel: () {
                                setState(() {
                                  _stateManager.forceShowCalibrationPanel =
                                      true;
                                });
                              },
                            ),
                          ),
                        if (_stateManager.shouldCalibrateCompass == true ||
                            _stateManager.forceShowCalibrationPanel)
                          CompassCalibrationPanel(
                            onClose: _stateManager.forceShowCalibrationPanel
                                ? () => setState(
                                    () =>
                                        _stateManager
                                                .forceShowCalibrationPanel =
                                            false,
                                  )
                                : null,
                          ),
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
          } catch (e, st) {
            logger.severe(
              'MapToolView: Exception building FlutterMap: $e\n$st',
            );
            return Stack(
              children: [
                const Center(child: Text('Error building map. See logs.')),
                Positioned(
                  top: 24,
                  right: 24,
                  child: StatusIndicator(
                    status: currentStatus,
                    onDismiss: hideStatus,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  List<LatLng> _buildPolylinePathPoints() {
    if (!_stateManager.isLoadingPoints) {
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      final points = projectState.currentPoints;

      if (points.length >= 2) {
        return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      }
    }
    return [];
  }

  Polyline? _buildConnectingLine() {
    if (_stateManager.connectingLineFromFirstToLast != null) {
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      final points = projectState.currentPoints;

      if (points.length >= 2) {
        return Polyline(
          points: [
            LatLng(points.first.latitude, points.first.longitude),
            LatLng(points.last.latitude, points.last.longitude),
          ],
          gradientColors: [
            AppConfig.angleColorGood.withValues(alpha: 0.5),
            AppConfig.angleColorBad.withValues(alpha: 0.5),
          ],
          colorsStop: [0.0, 1.0],
          strokeWidth: 3.0,
          pattern: StrokePattern.dotted(),
        );
      }
    }
    return null;
  }

  Widget _buildPointDetailsPanel(PointModel? selectedPoint) {
    return PointDetailsPanel(
      selectedPoint: selectedPoint,
      isMovePointMode: _stateManager.isMovePointMode,
      isMovingPointLoading: _stateManager.isMovingPointLoading,
      selectedPointId: _stateManager.selectedPointId,
      isMapReady: _stateManager.isMapReady,
      mapController: _stateManager.mapController,
      onClose: () {
        setState(() {
          _stateManager.selectedPointId = null;
        });
      },
      onEdit: () => _handleEditPoint(selectedPoint!),
      onMove: _handleMovePointAction,
      onDelete: () => _handleDeletePoint(selectedPoint!),
      onPointUpdated: _handlePointUpdated,
      onSaveNewPoint: _stateManager.newPoint != null
          ? _handleSaveNewPoint
          : null,
      onDiscardNewPoint: _stateManager.newPoint != null
          ? _handleDiscardNewPoint
          : null,
    );
  }
}
