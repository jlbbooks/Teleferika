---
tags:
  - data-model
  - domain
aliases:
  - CableTypes
---

# Cable Types

DB table + presets for rope/equipment characteristics used at project level.

## Columns

- `name`, `diameterMm`, `weightPerMeterKg`, `breakingLoadKn`
- Optional `elasticModulusGPa`, `sortOrder`

## Seeding

`projects/cable_equipment_presets.dart` — built-in Italy/EU forestry types (fune portante, fune traente, skyline, mainline, …) with **fixed UUIDs**, seeded only when the table is empty.

UI: `CableTypesScreen` under settings. Projects store `cableEquipmentTypeId` FK.

## Related

- [[Projects]] · [[Cable Crane Planning]] · [[Database]]
