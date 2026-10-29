---
tags:
  - domain
  - geometry
---

# Geometry

Shared math in `lib/geometry/geometry_service.dart`.

## Provides

- Bearing and distance between consecutive points
- Angle-at-point (slope-related)
- Polyline helpers
- **Angle-based coloring** (`angleColor`) for map segments — thresholds from `AppConfig`

## Consumers

- Map widgets / markers / polylines
- Points list & editor UI
- Project rope-length estimates (with [[ProjectModel]])

## Related

- [[Map]] · [[Points]] · [[Projects]]
