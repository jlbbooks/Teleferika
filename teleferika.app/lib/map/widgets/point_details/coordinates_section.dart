import 'package:flutter/material.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class CoordinatesSection extends StatefulWidget {
  final PointModel? selectedPoint;
  final bool isMobile;
  final Function(double, double) onCoordinatesUpdated;

  const CoordinatesSection({
    super.key,
    required this.selectedPoint,
    required this.isMobile,
    required this.onCoordinatesUpdated,
  });

  @override
  State<CoordinatesSection> createState() => _CoordinatesSectionState();
}

class _CoordinatesSectionState extends State<CoordinatesSection> {
  bool _isCoordinatesExpanded = false;
  bool _isEditingLatitude = false;
  bool _isEditingLongitude = false;

  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late FocusNode _latitudeFocusNode;
  late FocusNode _longitudeFocusNode;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _latitudeFocusNode = FocusNode();
    _longitudeFocusNode = FocusNode();
    _updateControllers();
  }

  @override
  void didUpdateWidget(CoordinatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPoint?.id != widget.selectedPoint?.id ||
        oldWidget.selectedPoint != widget.selectedPoint) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    if (widget.selectedPoint != null) {
      _latitudeController.text = widget.selectedPoint!.latitude.toString();
      _longitudeController.text = widget.selectedPoint!.longitude.toString();
    }
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _latitudeFocusNode.dispose();
    _longitudeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          GestureDetector(
            onTap: () {
              setState(() {
                _isCoordinatesExpanded = !_isCoordinatesExpanded;
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: widget.isMobile ? 14 : 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: widget.isMobile ? 6 : 8),
                Text(
                  S.of(context)?.coordinates ?? 'Coordinates',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: widget.isMobile ? 11 : null,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isCoordinatesExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: widget.isMobile ? 16 : 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: widget.isMobile ? 4 : 6),
                // Latitude
                Row(
                  children: [
                    Icon(
                      AppConfig.latitudeIcon,
                      size: widget.isMobile ? 14 : 16,
                      color: AppConfig.latitudeColor,
                    ),
                    SizedBox(width: widget.isMobile ? 6 : 8),
                    _buildEditableCoordinate(
                      label: S.of(context)?.lat ?? 'Lat:',
                      controller: _latitudeController,
                      focusNode: _latitudeFocusNode,
                      isEditing: _isEditingLatitude,
                      onTap: () => _startEditingLatitude(),
                      onConfirm: () => _confirmLatitudeChange(),
                      onCancel: () => _cancelLatitudeChange(),
                    ),
                  ],
                ),
                SizedBox(height: widget.isMobile ? 2 : 4),
                // Longitude
                Row(
                  children: [
                    Icon(
                      AppConfig.longitudeIcon,
                      size: widget.isMobile ? 14 : 16,
                      color: AppConfig.longitudeColor,
                    ),
                    SizedBox(width: widget.isMobile ? 6 : 8),
                    _buildEditableCoordinate(
                      label: S.of(context)?.lon ?? 'Lon:',
                      controller: _longitudeController,
                      focusNode: _longitudeFocusNode,
                      isEditing: _isEditingLongitude,
                      onTap: () => _startEditingLongitude(),
                      onConfirm: () => _confirmLongitudeChange(),
                      onCancel: () => _cancelLongitudeChange(),
                    ),
                  ],
                ),
                SizedBox(height: widget.isMobile ? 2 : 4),
                // Altitude
                if (widget.selectedPoint?.altitude != null)
                  Row(
                    children: [
                      Icon(
                        AppConfig.altitudeIcon,
                        size: widget.isMobile ? 14 : 16,
                        color: AppConfig.altitudeColor,
                      ),
                      SizedBox(width: widget.isMobile ? 6 : 8),
                      Text(
                        '${S.of(context)?.altitude_label ?? 'Alt:'}: '
                        '${widget.selectedPoint!.altitude!.toStringAsFixed(2)} ${S.of(context)?.unit_meter ?? 'm'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConfig.altitudeColor,
                          fontSize: widget.isMobile ? 10 : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            crossFadeState: _isCoordinatesExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
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
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: widget.isMobile ? 10 : null,
          ),
        ),
        SizedBox(width: widget.isMobile ? 4 : 6),
        Flexible(
          child: isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: widget.isMobile ? 11 : null,
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
                    SizedBox(width: widget.isMobile ? 2 : 4),
                    // Cancel button
                    GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: EdgeInsets.all(widget.isMobile ? 2 : 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.close,
                          size: widget.isMobile ? 12 : 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: widget.isMobile ? 2 : 4),
                    // Confirm button
                    GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        padding: EdgeInsets.all(widget.isMobile ? 2 : 4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.check,
                          size: widget.isMobile ? 12 : 14,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: widget.isMobile ? 11 : null,
                    ),
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

  void _confirmLatitudeChange() {
    final newLatitude = double.tryParse(_latitudeController.text);
    if (newLatitude == null) {
      _cancelLatitudeChange();
      return;
    }

    if (newLatitude < -90 || newLatitude > 90) {
      _cancelLatitudeChange();
      return;
    }

    if (newLatitude != widget.selectedPoint!.latitude) {
      widget.onCoordinatesUpdated(newLatitude, widget.selectedPoint!.longitude);
    }
    setState(() {
      _isEditingLatitude = false;
    });
    _latitudeFocusNode.unfocus();
  }

  void _confirmLongitudeChange() {
    final newLongitude = double.tryParse(_longitudeController.text);
    if (newLongitude == null) {
      _cancelLongitudeChange();
      return;
    }

    if (newLongitude < -180 || newLongitude > 180) {
      _cancelLongitudeChange();
      return;
    }

    if (newLongitude != widget.selectedPoint!.longitude) {
      widget.onCoordinatesUpdated(widget.selectedPoint!.latitude, newLongitude);
    }
    setState(() {
      _isEditingLongitude = false;
    });
    _longitudeFocusNode.unfocus();
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
}
