---
tags:
  - data-model
---

# ProjectModel

Immutable domain model over the `Projects` table (`db/models/project_model.dart`).

## Key fields

- `id`, `name`, `note`
- `azimuth`, `presumedTotalLength`
- `cableEquipmentTypeId`
- `date`, `lastUpdate`
- In-memory `points` list
- Profile chart height prefs

## Behaviour

- Rope length / validation helpers
- `toMap` / `fromMap` / `copyWith`

## Related

- [[Projects]] · [[PointModel]] · [[Cable Types]] · [[Database]]
