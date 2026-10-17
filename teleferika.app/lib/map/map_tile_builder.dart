import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Placeholder for tiles that failed to load (offline, cache miss, HTTP error).
///
/// Uses [TileLayer.tileBuilder] (flutter_map 8.3+ applies this to errored tiles).
Widget teleferikaMapTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
  if (!tile.loadError) return tileWidget;

  final placeholder = Theme.of(context).colorScheme.surfaceContainerHighest;
  return ColoredBox(
    color: placeholder.withValues(alpha: 0.45),
    child: const SizedBox.expand(),
  );
}

/// Whether [point] can be safely passed to flutter_map layers (8.3+ rejects non-finite).
bool isFiniteLatLng(LatLng point) =>
    point.latitude.isFinite && point.longitude.isFinite;
