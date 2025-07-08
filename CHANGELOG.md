# Changelog

All notable changes to this project will be documented in this file.

## [0.9.27+68]
### Changed
- Removed `startingPointId` and `endingPointId` from `ProjectModel` and the database schema.
- All logic now uses the first and last point in the project's points list as the start and end points, respectively.
- Updated all export strategies and UI/state management to use first/last point logic instead of explicit IDs.
- Added database migration to drop the removed columns if present. 