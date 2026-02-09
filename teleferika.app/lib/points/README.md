# Points

This directory is reserved for point-domain logic shared across the app.

## Current usage

Point data and persistence live in:

- **`db/models/point_model.dart`** – Point data model
- **`ui/screens/points/`** – Points list and point editor screens
- **`geometry/`** – Geometry calculations (bearings, distances, angles) used for points and map

## Future use

Add here any point-specific logic that does not belong in the database layer or UI, for example:

- Point validation rules
- Point formatting or serialization for export
- Point ordering or numbering logic (if it grows beyond `core/utils/ordinal_manager.dart`)
