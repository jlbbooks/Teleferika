---
tags:
  - domain
  - map
---

# Map

Flutter Map–based field map for surveying and reviewing lines.

## Structure (`lib/map/`)

| Area | Examples |
|------|----------|
| widgets | `flutter_map_widget`, FABs, type selector, GPS info, point details |
| markers | Project points, location accuracy, azimuth/moving timber, arrowheads |
| services | Location/compass, tile cache manager, preferences |
| state | `MapStateManager` |

## Behaviours

- Multiple [[Map Types]]
- Offline tiles via FMTC; bulk download in [[licensed_features_package]]
- Marker slide for fine positioning
- Heading: compass vs true via [[Magnetic Variation]]
- Permission overlay + location service

## Entry UI

Map screen under `ui/screens/map/` orchestrates map + RTK streams.

## Related

- [[Geometry]] · [[Points]] · [[Azimuth]] · [[BLE RTK]]
