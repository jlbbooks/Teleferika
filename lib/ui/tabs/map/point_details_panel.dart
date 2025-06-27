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

    return Positioned(
      top: shouldShowAtBottom ? null : 16,
      bottom: shouldShowAtBottom ? 16 : null,
      right: 16,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.black26,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(16.0),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Coordinates
              Container(
                padding: const EdgeInsets.all(8),
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
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${selectedPoint!.latitude.toStringAsFixed(6)}, ${selectedPoint!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Note section
              if (selectedPoint!.note?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
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
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedPoint!.note!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Move mode indicator
              if (isMovePointMode && selectedPoint!.id == selectedPointId) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap on the map to set new location',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              _buildActionButtons(),

              // Loading indicator
              if (isMovingPointLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Center(child: LinearProgressIndicator()),
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

  Widget _buildActionButtons() {
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
          ),
        ),
        const SizedBox(width: 8),
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
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.red,
            onPressed: (isMovePointMode || isMovingPointLoading)
                ? null
                : onDelete,
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                size: 20,
                color: onPressed != null ? color : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
