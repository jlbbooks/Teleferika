# Projects

This directory is reserved for project-domain logic shared across the app.

## Current usage

Project data and persistence live in:

- **`db/models/project_model.dart`** – Project data model
- **`projects/cable_equipment_presets.dart`** – Seed data for cable types (fixed UUIDs, used only when DB cable_types table is empty; project details read from the DB via `getAllCableTypes()`)
- **`ui/screens/projects/`** – Projects list and project tabbed screens
- **`core/project_provider.dart`** and **`core/project_state_manager.dart`** – Current project state

## Future use

Add here any project-specific logic that does not belong in the database layer or UI, for example:

- Project validation or rules
- Project export or import
- Rope length or cable-crane calculations (if extracted from map/geometry)
