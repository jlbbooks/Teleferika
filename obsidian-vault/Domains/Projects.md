---
tags:
  - domain
  - projects
---

# Projects

A **project** groups an ordered sequence of survey [[Points]] into one cable line / operation.

## Persistence

- Table `Projects` + model [[ProjectModel]]
- Optional FK `cableEquipmentTypeId` → [[Cable Types]]
- Profile chart heights stored per project (UI prefs, not “dirty” survey data)

## Domain fields (conceptual)

- Name, notes, date / lastUpdate
- **Azimuth** — intended line direction (true north) → [[Azimuth]]
- **Presumed total length** — quick estimate
- Cable/equipment type
- In-memory points list on the model; rope-length helpers

## UI

- `ProjectsListScreen` — list / open
- `ProjectTabbedScreen` — details, line profile, plan profile → see `PROFILE_TAB_README.md`
- Settings: cable types management screen

## State

[[State Management|ProjectStateManager]] owns current project edits.

## Related

- [[Points]] · [[Geometry]] · [[Cable Types]] · [[Field Survey Workflow]]
