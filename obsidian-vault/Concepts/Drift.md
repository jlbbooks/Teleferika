---
tags:
  - concept
  - database
---

# Drift

Type-safe SQLite ORM for Dart (formerly Moor). Teleferika migrated from raw sqflite.

## Why

Compile-time queries, codegen (`database.g.dart`), structured migrations, better DX.

## In this project

- Schema in `database.dart` — `schemaVersion => 8`
- Generate: `dart run build_runner build`
- Migration from old DB via `MigrationService` / `SqliteMigrationHelper`

Docs: `lib/db/README.md`, `doc/db/DRIFT_MIGRATION_README.md`

## Related

- [[Database]]
