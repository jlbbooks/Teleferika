import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/models/point_model.dart';

class PointDetailsPanel extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPoint == null) return const SizedBox.shrink();

    // Determine if the panel should appear at the bottom
    final bool shouldShowAtBottom = _shouldShowPanelAtBottom();
    
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Calculate responsive width and positioning - make it narrower
    final maxWidth = isMobile ? screenWidth * 0.65 : 280.0; // Reduced from 0.85 and 320
    final horizontalPadding = isMobile ? 8.0 : 16.0;
    final verticalPadding = isMobile ? 12.0 : 16.0;
    
    // Account for floating action buttons - they're on the left side
    final bottomOffset = 100.0; // Space for floating buttons

    return Positioned(
      top: shouldShowAtBottom ? null : 16,
      bottom: shouldShowAtBottom ? 24.0 : null, // Match floating buttons bottom position
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
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedPoint!.name}',
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
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 28 : 32,
                      minHeight: isMobile ? 28 : 32,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? 8 : 12),

              // Coordinates
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: isMobile ? 14 : 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Expanded(
                      child: Text(
                        '${selectedPoint!.latitude.toStringAsFixed(isMobile ? 5 : 6)}, ${selectedPoint!.longitude.toStringAsFixed(isMobile ? 5 : 6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: isMobile ? 11 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Note section
              if (selectedPoint!.note?.isNotEmpty ?? false) ...[
                SizedBox(height: isMobile ? 8 : 12),
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: isMobile ? 14 : 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Expanded(
                        child: Text(
                          selectedPoint!.note!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                fontSize: isMobile ? 11 : null,
                              ),
                          maxLines: isMobile ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Move mode indicator
              if (isMovePointMode && selectedPoint!.id == selectedPointId) ...[
                SizedBox(height: isMobile ? 8 : 12),
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
              if (isMovingPointLoading)
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

  bool _shouldShowPanelAtBottom() {
    if (selectedPoint == null || !isMapReady) return false;

    try {
      // Get the current map bounds
      final bounds = mapController.camera.visibleBounds;
      if (bounds == null) return false;

      // Get the selected point's position
      final pointLatLng = LatLng(
        selectedPoint!.latitude,
        selectedPoint!.longitude,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: Colors.blue,
            onPressed: isMovePointMode ? null : onEdit,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Expanded(
          child: _buildActionButton(
            icon: isMovePointMode && selectedPoint!.id == selectedPointId
                ? Icons.cancel_outlined
                : Icons.open_with,
            label: isMovePointMode && selectedPoint!.id == selectedPointId
                ? 'Cancel'
                : 'Move',
            color: isMovePointMode && selectedPoint!.id == selectedPointId
                ? Colors.orange
                : Colors.teal,
            onPressed: isMovingPointLoading ? null : onMove,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.red,
            onPressed: (isMovePointMode || isMovingPointLoading)
                ? null
                : onDelete,
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
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onPressed != null
                  ? color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
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
