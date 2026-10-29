---
tags:
  - domain
  - map
---

# Map Types

Configured in `lib/map/map_type.dart` (see also `doc/map/MAP_TYPES_README.md`).

| Type | Typical use |
|------|-------------|
| Open Topo Map | Contours / terrain (EU field) |
| Thunderforest Outdoors | Trails + outdoors |
| Thunderforest Landscape | Terrain-focused style |
| Esri World Topo | General topo |
| Esri Satellite | Obstacles, landings, LOS |
| CartoDB Positron | Minimal base for overlays |

API keys / attribution handled per provider in tile builder.

## Related

- [[Map]] · [[Export]] (offline download)
