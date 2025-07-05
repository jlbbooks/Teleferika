import 'package:flutter/material.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/tabs/map/map_controller.dart';

class MapTypeSelector {
  static Widget build({
    required MapType currentMapType,
    required Function(MapType) onMapTypeChanged,
    required BuildContext context,
  }) {
    final s = S.of(context);
    return Positioned(
      top: 16,
      left: 16,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        shadowColor: Colors.black12,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: PopupMenuButton<MapType>(
            onSelected: onMapTypeChanged,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _getMapTypeIcon(currentMapType),
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getMapTypeDisplayName(currentMapType, s),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) => [
              _buildMapTypeMenuItem(
                MapType.openStreetMap,
                s?.mapTypeStreet ?? 'Street',
                Icons.map,
                currentMapType,
                context,
              ),
              _buildMapTypeMenuItem(
                MapType.satellite,
                s?.mapTypeSatellite ?? 'Satellite',
                Icons.satellite_alt,
                currentMapType,
                context,
              ),
              _buildMapTypeMenuItem(
                MapType.terrain,
                s?.mapTypeTerrain ?? 'Terrain',
                Icons.terrain,
                currentMapType,
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static PopupMenuItem<MapType> _buildMapTypeMenuItem(
    MapType mapType,
    String label,
    IconData icon,
    MapType currentMapType,
    BuildContext context,
  ) {
    final isSelected = currentMapType == mapType;
    return PopupMenuItem<MapType>(
      value: mapType,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  static IconData _getMapTypeIcon(MapType mapType) {
    switch (mapType) {
      case MapType.openStreetMap:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
    }
  }

  static String _getMapTypeDisplayName(MapType mapType, S? s) {
    switch (mapType) {
      case MapType.openStreetMap:
        return s?.mapTypeStreet ?? 'Street';
      case MapType.satellite:
        return s?.mapTypeSatellite ?? 'Satellite';
      case MapType.terrain:
        return s?.mapTypeTerrain ?? 'Terrain';
    }
  }
}
