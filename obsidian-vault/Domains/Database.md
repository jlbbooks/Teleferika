---
tags:
  - domain
  - database
---

# Database

**Drift** SQLite layer (`lib/db/`), schema version **8**.

## Tables

| Table | Notes |
|-------|-------|
| Projects | Line metadata; FK to CableTypes |
| Points | FK → Projects cascade |
| Images | FK → Points cascade |
| CableTypes | Diameter, weight, breaking load, E-modulus |
| NtripSettings | Saved NTRIP caster profiles |

Files: runtime DB `Teleferika.db`; legacy `photogrammetry.db` for one-shot migration.

## Access

- `database.dart` — schema + queries
- `drift_database_helper.dart` — app-facing API
- Models in `db/models/` abstract rows → [[ProjectModel]], [[PointModel]], [[ImageModel]]

## Rules

Foreign keys required for new reference columns — see `.cursor/rules/db-foreign-keys.mdc` and [[Open Reminders]].

## Related

- [[Drift]] · [[App Initialization]] · [[NTRIP]]
