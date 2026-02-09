# Geometry

Shared geometry and map math used by both the map and points features.

## Contents

- **`geometry_service.dart`** – Bearing and distance calculations, angle-at-point, polyline helpers, and angle-based coloring. Used by map widgets, markers, and points list/editor UI.
- **`angleColor(double)`** – Top-level helper for angle-based color interpolation (exported from `geometry_service.dart`).

## Dependencies

- `core/` (logger, app_config)
- `db/models/` (point_model, project_model)
- Flutter/material and flutter_map for `Polyline` / `Color`
