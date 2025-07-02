// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class PointDetailsPanel extends StatefulWidget {
  final PointModel? selectedPoint;
  final bool isMovePointMode;
  final bool isMovingPointLoading;
  final String? selectedPointId;
  final bool isMapReady;
  final MapController mapController;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final Function(PointModel)? onPointUpdated;
  final VoidCallback? onSaveNewPoint;
  final VoidCallback? onDiscardNewPoint;

  const PointDetailsPanel({
    super.key,
    required this.selectedPoint,
    required this.isMovePointMode,
    required this.isMovingPointLoading,
    required this.selectedPointId,
    required this.isMapReady,
    required this.mapController,
    required this.onClose,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    this.onPointUpdated,
    this.onSaveNewPoint,
    this.onDiscardNewPoint,
  });

  @override
  State<PointDetailsPanel> createState() => _PointDetailsPanelState();
}

class _PointDetailsPanelState extends State<PointDetailsPanel> {
  // Editing state
  bool _isEditingLatitude = false;
  bool _isEditingLongitude = false;
  bool _isEditingNote = false;

  // Controllers for text fields
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _noteController;

  // Focus nodes for text fields
  late FocusNode _latitudeFocusNode;
  late FocusNode _longitudeFocusNode;
  late FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _noteController = TextEditingController();
    _latitudeFocusNode = FocusNode();
    _longitudeFocusNode = FocusNode();
    _noteFocusNode = FocusNode();
    _updateControllers();
  }

  @override
  void didUpdateWidget(PointDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if point ID changes OR if point data changes (for edits)
    if (oldWidget.selectedPoint?.id != widget.selectedPoint?.id ||
        oldWidget.selectedPoint != widget.selectedPoint) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    if (widget.selectedPoint != null) {
      _latitudeController.text = widget.selectedPoint!.latitude.toStringAsFixed(
        6,
      );
      _longitudeController.text = widget.selectedPoint!.longitude
          .toStringAsFixed(6);
      _noteController.text = widget.selectedPoint!.note;
    }
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _noteController.dispose();
    _latitudeFocusNode.dispose();
    _longitudeFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedPoint == null) return const SizedBox.shrink();

    // Determine if the panel should appear at the bottom
    final bool shouldShowAtBottom = _shouldShowPanelAtBottom();

    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Calculate responsive width and positioning - make it narrower
    final maxWidth = isMobile
        ? screenWidth * 0.65
        : 280.0; // Reduced from 0.85 and 320
    final horizontalPadding = isMobile ? 8.0 : 16.0;
    final verticalPadding = isMobile ? 12.0 : 16.0;

    // Account for floating action buttons - they're on the left side
    final bottomOffset = 100.0; // Space for floating buttons

    return Positioned(
      top: shouldShowAtBottom ? null : 16,
      bottom: shouldShowAtBottom
          ? 24.0
          : null, // Match floating buttons bottom position
      right: horizontalPadding,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.black26,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: EdgeInsets.all(verticalPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with point number and close button
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.selectedPoint!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: isMobile ? 14 : null,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: isMobile ? 18 : 20),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 28 : 32,
                      minHeight: isMobile ? 28 : 32,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? 8 : 12),

              // Coordinates - now editable
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: isMobile ? 14 : 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: isMobile ? 6 : 8),
                        Text(
                          S.of(context)?.coordinates ?? 'Coordinates',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: isMobile ? 11 : null,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    // Latitude
                    _buildEditableCoordinate(
                      label: S.of(context)?.lat ?? 'Lat:',
                      controller: _latitudeController,
                      focusNode: _latitudeFocusNode,
                      isEditing: _isEditingLatitude,
                      onTap: () => _startEditingLatitude(),
                      onConfirm: () => _confirmLatitudeChange(),
                      onCancel: () => _cancelLatitudeChange(),
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    // Longitude
                    _buildEditableCoordinate(
                      label: S.of(context)?.lon ?? 'Lon:',
                      controller: _longitudeController,
                      focusNode: _longitudeFocusNode,
                      isEditing: _isEditingLongitude,
                      onTap: () => _startEditingLongitude(),
                      onConfirm: () => _confirmLongitudeChange(),
                      onCancel: () => _cancelLongitudeChange(),
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),

              // Note section - now editable
              SizedBox(height: isMobile ? 8 : 12),
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildEditableNote(isMobile),
              ),

              // Move mode indicator
              if (widget.isMovePointMode &&
                  widget.selectedPoint!.id == widget.selectedPointId) ...[
                SizedBox(height: isMobile ? 8 : 12),
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: isMobile ? 14 : 16,
                        color: Colors.orange.shade700,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Expanded(
                        child: Text(
                          S.of(context)?.tapOnTheMapToSetNewLocation ??
                              'Tap on the map to set new location',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: isMobile ? 12 : 16),

              // Action buttons
              _buildActionButtons(isMobile),

              // Loading indicator
              if (widget.isMovingPointLoading)
                Padding(
                  padding: EdgeInsets.only(top: isMobile ? 8.0 : 12.0),
                  child: const Center(child: LinearProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableCoordinate({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isEditing,
    required VoidCallback onTap,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: isMobile ? 10 : null,
          ),
        ),
        SizedBox(width: isMobile ? 4 : 6),
        Expanded(
          child: isEditing
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: isMobile ? 11 : null,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onSubmitted: (_) => onConfirm(),
                      ),
                    ),
                    SizedBox(width: isMobile ? 2 : 4),
                    // Cancel button
                    GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 2 : 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.close,
                          size: isMobile ? 12 : 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 2 : 4),
                    // Confirm button
                    GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 2 : 4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.check,
                          size: isMobile ? 12 : 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: onTap,
                  child: Text(
                    controller.text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: isMobile ? 11 : null,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEditableNote(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.note_outlined,
          size: isMobile ? 14 : 16,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Expanded(
          child: _isEditingNote
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          fontSize: isMobile ? 11 : null,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintText: S.of(context)?.addANote ?? 'Add a note...',
                        ),
                        maxLines: isMobile ? 2 : 3,
                        onSubmitted: (_) => _confirmNoteChange(),
                      ),
                    ),
                    SizedBox(width: isMobile ? 2 : 4),
                    // Cancel button
                    GestureDetector(
                      onTap: _cancelNoteChange,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 2 : 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.close,
                          size: isMobile ? 12 : 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 2 : 4),
                    // Confirm button
                    GestureDetector(
                      onTap: _confirmNoteChange,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 2 : 4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.check,
                          size: isMobile ? 12 : 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: _startEditingNote,
                  child: Text(
                    widget.selectedPoint!.note.isEmpty
                        ? S.of(context)?.tapToAddNote ?? 'Tap to add note...'
                        : widget.selectedPoint!.note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.selectedPoint!.note.isNotEmpty
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                      fontSize: isMobile ? 11 : null,
                      fontStyle: widget.selectedPoint!.note.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
      ],
    );
  }

  void _startEditingLatitude() {
    setState(() {
      _isEditingLatitude = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _latitudeFocusNode.requestFocus();
    });
  }

  void _startEditingLongitude() {
    setState(() {
      _isEditingLongitude = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _longitudeFocusNode.requestFocus();
    });
  }

  void _startEditingNote() {
    setState(() {
      _isEditingNote = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _noteFocusNode.requestFocus();
    });
  }

  void _confirmLatitudeChange() {
    final newLatitude = double.tryParse(_latitudeController.text);
    if (newLatitude == null) {
      // Invalid number format - revert to original value
      _cancelLatitudeChange();
      return;
    }

    // Validate latitude range
    if (newLatitude < -90 || newLatitude > 90) {
      // Invalid latitude range - revert to original value
      _cancelLatitudeChange();
      return;
    }

    if (newLatitude != widget.selectedPoint!.latitude) {
      _updatePointCoordinates(newLatitude, widget.selectedPoint!.longitude);
    }
    setState(() {
      _isEditingLatitude = false;
    });
    _latitudeFocusNode.unfocus();
  }

  void _confirmLongitudeChange() {
    final newLongitude = double.tryParse(_longitudeController.text);
    if (newLongitude == null) {
      // Invalid number format - revert to original value
      _cancelLongitudeChange();
      return;
    }

    // Validate longitude range
    if (newLongitude < -180 || newLongitude > 180) {
      // Invalid longitude range - revert to original value
      _cancelLongitudeChange();
      return;
    }

    if (newLongitude != widget.selectedPoint!.longitude) {
      _updatePointCoordinates(widget.selectedPoint!.latitude, newLongitude);
    }
    setState(() {
      _isEditingLongitude = false;
    });
    _longitudeFocusNode.unfocus();
  }

  void _confirmNoteChange() {
    final newNote = _noteController.text.trim();
    if (newNote != widget.selectedPoint!.note) {
      _updatePointNote(newNote);
    }
    setState(() {
      _isEditingNote = false;
    });
    _noteFocusNode.unfocus();
  }

  void _cancelLatitudeChange() {
    _latitudeController.text = widget.selectedPoint!.latitude.toStringAsFixed(
      6,
    );
    setState(() {
      _isEditingLatitude = false;
    });
    _latitudeFocusNode.unfocus();
  }

  void _cancelLongitudeChange() {
    _longitudeController.text = widget.selectedPoint!.longitude.toStringAsFixed(
      6,
    );
    setState(() {
      _isEditingLongitude = false;
    });
    _longitudeFocusNode.unfocus();
  }

  void _cancelNoteChange() {
    _noteController.text = widget.selectedPoint!.note;
    setState(() {
      _isEditingNote = false;
    });
    _noteFocusNode.unfocus();
  }

  void _updatePointCoordinates(double newLatitude, double newLongitude) {
    if (widget.selectedPoint == null) return;

    final updatedPoint = widget.selectedPoint!.copyWith(
      latitude: newLatitude,
      longitude: newLongitude,
    );
    // Add logging
    debugPrint(
      '[PointDetailsPanel] _updatePointCoordinates: id=${updatedPoint.id}, ordinal=${updatedPoint.ordinalNumber}, name=${updatedPoint.name}, lat=${updatedPoint.latitude}, lon=${updatedPoint.longitude}, note=${updatedPoint.note}',
    );
    widget.onPointUpdated?.call(updatedPoint);

    // Don't center the map - let it stay where it is
  }

  void _updatePointNote(String newNote) {
    if (widget.selectedPoint == null) return;

    final updatedPoint = widget.selectedPoint!.copyWith(note: newNote);
    // Add logging
    debugPrint(
      '[PointDetailsPanel] _updatePointNote: id=${updatedPoint.id}, ordinal=${updatedPoint.ordinalNumber}, name=${updatedPoint.name}, lat=${updatedPoint.latitude}, lon=${updatedPoint.longitude}, note=${updatedPoint.note}',
    );
    widget.onPointUpdated?.call(updatedPoint);
  }

  bool _shouldShowPanelAtBottom() {
    if (widget.selectedPoint == null || !widget.isMapReady) return false;

    try {
      // Get the current map bounds
      final bounds = widget.mapController.camera.visibleBounds;

      // Get the selected point's position
      final pointLatLng = LatLng(
        widget.selectedPoint!.latitude,
        widget.selectedPoint!.longitude,
      );

      // Calculate the midpoint of the visible map
      final mapMidpoint =
          (bounds.northEast.latitude + bounds.southWest.latitude) / 2;

      // If the point is in the upper half of the map, show panel at bottom
      return pointLatLng.latitude > mapMidpoint;
    } catch (e) {
      // Fallback to showing at top if there's any error
      return false;
    }
  }

  Widget _buildActionButtons(bool isMobile) {
    // If this is a new unsaved point, show Save/Discard buttons
    if (widget.selectedPoint?.isUnsaved == true) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.save,
              label: S.of(context)?.save ?? 'Save',
              color: Colors.green,
              onPressed: widget.onSaveNewPoint,
              isMobile: isMobile,
            ),
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.delete_outline,
              label: S.of(context)?.discard ?? 'Discard',
              color: Colors.red,
              onPressed: widget.onDiscardNewPoint,
              isMobile: isMobile,
            ),
          ),
        ],
      );
    }

    // Regular buttons for existing points
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit_outlined,
            label: S.of(context)?.edit ?? 'Edit',
            color: Colors.blue,
            onPressed: widget.isMovePointMode ? null : widget.onEdit,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Expanded(
          child: _buildActionButton(
            icon:
                widget.isMovePointMode &&
                    widget.selectedPoint!.id == widget.selectedPointId
                ? Icons.cancel_outlined
                : Icons.open_with,
            label:
                widget.isMovePointMode &&
                    widget.selectedPoint!.id == widget.selectedPointId
                ? S.of(context)?.cancel ?? 'Cancel'
                : S.of(context)?.move ?? 'Move',
            color:
                widget.isMovePointMode &&
                    widget.selectedPoint!.id == widget.selectedPointId
                ? Colors.orange
                : Colors.teal,
            onPressed: widget.isMovingPointLoading ? null : widget.onMove,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.delete_outline,
            label: S.of(context)?.delete ?? 'Delete',
            color: Colors.red,
            onPressed: (widget.isMovePointMode || widget.isMovingPointLoading)
                ? null
                : widget.onDelete,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isMobile,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 6 : 8,
            horizontal: isMobile ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onPressed != null
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isMobile ? 16 : 20,
                color: onPressed != null ? color : Colors.grey,
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  color: onPressed != null ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
