import 'package:flutter/material.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';

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
            color: Theme.of(context).cardColor.withAlpha(230),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(25),
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
                      ).colorScheme.primary.withAlpha(13),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      currentMapType.icon,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(179),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentMapType.getUiName(s),
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
                    ).colorScheme.onSurfaceVariant.withAlpha(153),
                  ),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) => [
              for (final mapType in MapType.all)
                _buildMapTypeMenuItem(
                  mapType,
                  mapType.getUiName(s),
                  mapType.icon,
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
    final isSelected = currentMapType.id == mapType.id;
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
                    ? Theme.of(context).colorScheme.primary.withAlpha(25)
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
}
