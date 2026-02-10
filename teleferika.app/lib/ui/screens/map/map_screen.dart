import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/settings_service.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/screens/points/point_editor_screen.dart';
import 'package:teleferika/ui/widgets/compass_calibration_panel.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

import '../../../map/debug/debug_panel.dart';
import '../../../map/state/map_state_manager.dart';
import '../../../map/widgets/flutter_map_widget.dart';
import '../../../map/widgets/map_loading_widget.dart';
import '../../../map/widgets/point_details/point_details_panel.dart';
import '../../../map/widgets/floating_action_buttons.dart';
import '../../../map/widgets/gps_info_panel.dart';
import '../../../map/widgets/map_type_selector.dart';
import '../../../map/services/map_cache_manager.dart';
import '../../../ui/widgets/project_points_layer.dart';
import '../../../ble/ble_service.dart';
import '../../../ble/nmea_parser.dart';
import '../../../ble/rtk_device_service.dart';

class MapScreen extends StatefulWidget {
  final ProjectModel project;
  final String? selectedPointId;

  const MapScreen({super.key, required this.project, this.selectedPointId});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen>
    with StatusMixin, TickerProviderStateMixin {
  final Logger logger = Logger('MapScreen');
  final SettingsService _settingsService = SettingsService();
  final RtkDeviceService _rtkService = RtkDeviceService.instance;

  // State manager
  late MapStateManager _stateManager;
  bool _showAllProjectsOnMap = false;
  bool _showBleSatelliteButton = true;
  bool _isBleConnected = false;
  int? _bleFixQuality;
  StreamSubscription<BLEConnectionState>? _bleConnectionSubscription;
  StreamSubscription<NMEAData>? _nmeaDataSubscription;

  // Helper method for haptic feedback
  void _triggerHapticFeedback(String action) {
    try {
      if (kIsWeb) {
        logger.info('Haptic feedback skipped on web platform for: $action');
        return;
      }

      HapticFeedback.mediumImpact();
      logger.info('Haptic feedback triggered for: $action');
    } catch (e) {
      logger.warning('Failed to trigger haptic feedback for $action: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _stateManager = MapStateManager();
    _stateManager.selectedPointId = widget.selectedPointId;
    _loadSettings();
    _initBleConnectionListener();
  }

  void _initBleConnectionListener() {
    // Check initial connection state
    _isBleConnected = _rtkService.isConnected;

    // Listen to connection state changes
    BLEConnectionState? previousState;
    _bleConnectionSubscription = _rtkService.connectionState.listen((state) {
      if (mounted) {
        final wasConnected = previousState == BLEConnectionState.connected;
        final isNowDisconnected = state == BLEConnectionState.disconnected;

        setState(() {
          _isBleConnected = state == BLEConnectionState.connected;
          // Clear fix quality when disconnected
          if (!_isBleConnected) {
            _bleFixQuality = null;
          }
        });

        // Notify user of unexpected disconnection
        if (wasConnected && isNowDisconnected) {
          showInfoStatus(S.of(context)?.mapRtkDisconnectedUsingDeviceGps ?? 'RTK device disconnected. Using device GPS.');
          logger.info(
            'MapScreen: BLE device disconnected, switched to device GPS',
          );
        } else if (state == BLEConnectionState.error) {
          showErrorStatus(S.of(context)?.mapBleConnectionError ?? 'BLE connection error occurred.');
          logger.warning('MapScreen: BLE connection error');
        }

        previousState = state;
      }
    });

    // Listen to NMEA data to get fix quality
    _nmeaDataSubscription = _rtkService.nmeaData.listen((nmeaData) {
      if (mounted) {
        // NMEA data logging removed
        setState(() {
          _bleFixQuality = nmeaData.fixQuality;
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      _showAllProjectsOnMap = await _settingsService.showAllProjectsOnMap;
      _showBleSatelliteButton = await _settingsService.showBleSatelliteButton;
      setState(() {});
    } catch (e) {
      logger.warning('Error loading settings: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize state manager with current project from global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;
    _stateManager.initialize(this, currentProject, context.projectState);

    if (!_stateManager.didInitialLoad) {
      _stateManager.didInitialLoad = true;
      _loadProjectPoints();
    }
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Get current project from global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;
    final oldProject = oldWidget.project;

    if (currentProject.id != oldProject.id && !_stateManager.isLoadingPoints) {
      _loadProjectPoints();
    }

    if (widget.selectedPointId != oldWidget.selectedPointId) {
      _stateManager.selectedPointId = widget.selectedPointId;
      setState(() {}); // Only call setState once after updating state
    }
  }

  @override
  void dispose() {
    _bleConnectionSubscription?.cancel();
    _nmeaDataSubscription?.cancel();
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

    // Provide haptic feedback for successful point movement
    _triggerHapticFeedback('point movement');

    showSuccessStatus('Point ${pointToMove.name} moved (pending save)!');
  }

  void _showBleInfoPanel() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GPSInfoPanel(
          rtkService: _rtkService,
          currentPosition: _stateManager.currentPosition,
          isUsingBleGps: _stateManager.controller.isUsingBleGps,
        ),
      ),
    );
  }

  void _centerOnCurrentLocation() {
    _stateManager.centerOnCurrentLocation(context);
    showSuccessStatus('Centered on your current location.');
  }

  void _handleAddPointButtonPressed() async {
    // Center the map to the current location if available
    if (_stateManager.currentPosition != null) {
      final pos = _stateManager.currentPosition!;
      _stateManager.mapController.move(
        LatLng(pos.latitude, pos.longitude),
        _stateManager.mapController.camera.zoom,
      );
    }
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
    logger.info('Navigating to edit point ${point.name}');

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => PointEditorScreen(point: point)),
    );

    if (result != null && mounted) {
      final action = result['action'] as String?;

      if (action == 'updated') {
        final updatedPoint = result['point'] as PointModel?;
        if (updatedPoint != null) {
          // Do NOT call updatePointInEditingState again; PointEditorScreen already did it and notified listeners
          setState(() {
            _stateManager.recalculateAndDrawLines(context);
          });
          logger.info(
            'Point ${updatedPoint.name} details updated (pending save)!',
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
          logger.info('Point deleted from MapScreen.');
          showSuccessStatus('Point deleted (pending save)!');
        }
      }
    }
  }

  void _handleMovePointAction() {
    // Provide haptic feedback for move mode activation
    _triggerHapticFeedback('move mode activation');

    _stateManager.handleMovePointAction(context);
    setState(() {});

    if (_stateManager.isMovePointMode) {
      showInfoStatus('Move mode activated. Tap map to relocate point.');
    }
  }

  Future<void> _handleDeletePoint(PointModel point) async {
    logger.info('Delete tapped for point ${point.name}');
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
            'Point ${pointToDelete.name} (ID: ${pointToDelete.id}) removed from MapScreen after panel delete.',
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

  // Slide functionality handlers
  void _handleLongPressStart(PointModel point, LongPressStartDetails details) {
    // Provide haptic feedback for slide start
    _triggerHapticFeedback('slide start');

    // Store the original position and start sliding
    final originalPosition = LatLng(point.latitude, point.longitude);
    _stateManager.startSlidingMarker(point, originalPosition);
    setState(() {});
  }

  void _handleLongPressMoveUpdate(
    PointModel point,
    LongPressMoveUpdateDetails details,
  ) {
    if (_stateManager.isSlidingMarker &&
        _stateManager.slidingPointId == point.id) {
      // Get the original position from the state manager
      final originalPosition = _stateManager.originalPosition;
      if (originalPosition == null) return;

      // Calculate the drag delta in pixels
      final deltaX = details.offsetFromOrigin.dx;
      final deltaY = details.offsetFromOrigin.dy;

      // Use the map controller's coordinate conversion methods for accurate conversion
      final camera = _stateManager.mapController.camera;

      // Get the current map rotation in radians (negative for screen-to-map)
      final rotationDegrees = camera.rotation;
      final rotationRadians = -rotationDegrees * math.pi / 180.0;

      // Rotate the drag delta by the negative map rotation
      final rotatedDx =
          deltaX * math.cos(rotationRadians) -
          deltaY * math.sin(rotationRadians);
      final rotatedDy =
          deltaX * math.sin(rotationRadians) +
          deltaY * math.cos(rotationRadians);

      // Convert the original position to screen coordinates using the map's projection
      final originalScreenPoint = camera.projectAtZoom(
        originalPosition,
        camera.zoom,
      );

      // Calculate the new screen position
      final newScreenPoint = Offset(
        originalScreenPoint.dx + rotatedDx,
        originalScreenPoint.dy + rotatedDy,
      );

      // Convert back to map coordinates
      final newPosition = camera.unprojectAtZoom(newScreenPoint, camera.zoom);

      // Ensure the new position is valid
      if (newPosition.latitude.isFinite && newPosition.longitude.isFinite) {
        // Update the slide position
        _stateManager.updateSlidePosition(newPosition);
        setState(() {});
      }
    }
  }

  void _handleLongPressEnd(PointModel point, LongPressEndDetails details) {
    if (_stateManager.isSlidingMarker &&
        _stateManager.slidingPointId == point.id) {
      // Provide haptic feedback for successful slide completion
      _triggerHapticFeedback('slide completion');

      // End sliding and update the point
      _stateManager.endSlidingMarker(context);
      setState(() {});

      // Only show status if not a NEW (unsaved) point
      if (!point.isUnsaved) {
        showSuccessStatus('Point ${point.name} moved!');
      }
    }
  }

  /// Public method to refresh points from the database
  /// This can be called from the parent component when points are reordered
  Future<void> refreshPoints() async {
    logger.info('MapScreen: External refresh requested.');
    await _stateManager.refreshPoints(context);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _stateManager,
      child: Consumer2<ProjectStateManager, MapStateManager>(
        builder: (context, projectState, mapState, child) {
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
              requiredPermissions: const [
                PermissionType.location,
                PermissionType.sensor,
              ],
              onPermissionsResult: _handlePermissionResults,
              showOverlay: true,
              child: Stack(
                children: [
                  Scaffold(
                    body: SafeArea(
                      child: Stack(
                        children: [
                          FlutterMapWidget(
                            polylinePathPoints: polylinePathPoints,
                            connectingLine: connectingLine,
                            projectHeadingLine:
                                _stateManager.projectHeadingLine,
                            initialMapCenter: initialMapCenter,
                            initialMapZoom: initialMapZoom,
                            tileLayerUrl:
                                _stateManager.currentMapType.tileLayerUrl,
                            tileLayerAttribution: _stateManager
                                .currentMapType
                                .tileLayerAttribution,
                            attributionUrl:
                                _stateManager.currentMapType.attributionUrl,
                            mapController: _stateManager.mapController,
                            currentMapType: _stateManager.currentMapType,
                            isMapReady: _stateManager.isMapReady,
                            isLoadingPoints: _stateManager.isLoadingPoints,
                            isMovePointMode: _stateManager.isMovePointMode,
                            selectedPointId: _stateManager.selectedPointId,
                            currentPosition: _stateManager.currentPosition,
                            hasLocationPermission:
                                _stateManager.hasLocationPermission,
                            connectingLineFromFirstToLast:
                                _stateManager.connectingLineFromFirstToLast,
                            glowAnimationValue:
                                _stateManager.glowAnimationValue,
                            currentDeviceHeading:
                                _stateManager.currentDeviceHeading,
                            locationStreamController:
                                _stateManager.locationStreamController,
                            arrowheadAnimation:
                                _stateManager.arrowheadAnimation,
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
                            // Slide functionality parameters
                            onLongPressStart: _handleLongPressStart,
                            onLongPressMoveUpdate: _handleLongPressMoveUpdate,
                            onLongPressEnd: _handleLongPressEnd,
                            isSlidingMarker: _stateManager.isSlidingMarker,
                            slidingPointId: _stateManager.slidingPointId,
                            currentSlidePosition:
                                _stateManager.currentSlidePosition,
                            // Add other projects layer based on user preference
                            additionalLayers: _showAllProjectsOnMap
                                ? [
                                    ProjectPointsLayer(
                                      excludeProjectId:
                                          projectState.currentProject?.id,
                                      markerSize: 6.0,
                                      markerColor: Colors.grey,
                                      markerBorderColor: Colors.white,
                                      markerBorderWidth: 1.0,
                                      lineColor: Colors.grey,
                                      lineWidth: 1.0,
                                    ),
                                  ]
                                : null,
                          ),
                          MapTypeSelector.build(
                            currentMapType: _stateManager.currentMapType,
                            onMapTypeChanged: (mapType) {
                              logger.info(
                                'Map type changed from ${_stateManager.currentMapType.name} to ${mapType.name}',
                              );
                              setState(() {
                                _stateManager.currentMapType = mapType;
                              });

                              // Log cache status for debugging
                              MapCacheManager.logCacheStatus();

                              // Force map to refresh tiles by triggering a small movement
                              if (_stateManager.isMapReady) {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    if (mounted) {
                                      final currentCenter = _stateManager
                                          .mapController
                                          .camera
                                          .center;
                                      final currentZoom = _stateManager
                                          .mapController
                                          .camera
                                          .zoom;
                                      // Trigger a tiny zoom change to force tile reload
                                      _stateManager.mapController.move(
                                        currentCenter,
                                        currentZoom + 0.0001,
                                      );
                                      // Move back to original position
                                      Future.delayed(
                                        const Duration(milliseconds: 50),
                                        () {
                                          if (mounted) {
                                            _stateManager.mapController.move(
                                              currentCenter,
                                              currentZoom,
                                            );
                                          }
                                        },
                                      );
                                    }
                                  },
                                );
                              }
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
                                minimumSize: const Size(0, 0),
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
                              isBleConnected: _showBleSatelliteButton,
                              onBleInfoPressed: _showBleSatelliteButton
                                  ? _showBleInfoPanel
                                  : null,
                              bleFixQuality: _isBleConnected
                                  ? (_bleFixQuality ?? 0)
                                  : 0, // Default to 0 (No Fix) for internal GPS
                            ),
                          ),
                          // Debug panel only appears if _hasClosedDebugPanel is false
                          if (!_stateManager.hasClosedDebugPanel)
                            Positioned(
                              top: 16,
                              left: 16,
                              child: DebugPanel(
                                currentMapType: _stateManager.currentMapType,
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
            logger.severe('MapScreen: Exception building FlutterMap: $e\n$st');
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
          pattern: const StrokePattern.dotted(),
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
