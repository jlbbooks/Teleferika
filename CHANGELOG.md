# Changelog

All notable changes to this project will be documented in this file.

## [0.9.30+71] - 2025-01-27
### Added
- Complete project state management refactoring: Centralized all database operations through ProjectStateManager
- File cleanup functionality: Added cleanupOrphanedImageFiles configuration flag in AppConfig
- Automatic file cleanup on project deletion: Removes all related files and folders when deleting projects
- Enhanced error handling and user feedback throughout the application

### Changed
- Renamed ProjectEditorScreen to ProjectTabbedScreen to better reflect its tabbed interface
- Removed _editingProject field from ProjectStateManager, now editing directly on _currentProject
- Updated all UI components to use centralized state management instead of direct database calls
- Improved method signatures for consistency (e.g., movePoint now takes pointId instead of PointModel)
- Enhanced save/undo functionality with better state management

### Technical
- Refactored 20+ files to eliminate direct DatabaseHelper usage
- Added new methods: _cleanupOrphanedImageFilesForCurrentProject(), _cleanupProjectFiles(), updateProjectInDB()
- Improved logging and error handling across the application
- Enhanced performance by reducing redundant database operations

## [0.9.28+69] - 2025-07-08
### Changed
- Dynamic injection of MapType `cacheStoreName` and update of all usages to use the new pattern.
- Generalized Thunderforest API key support (now works for any map type with a parameterized API key).
- Debug panel and store status UI improvements (clearer map type display, better store status layout, icons for status).
- Documentation and code consistency improvements throughout the codebase. 

## [0.9.27+68]
- Removed `startingPointId` and `endingPointId` from `ProjectModel` and the database schema.

## [0.9.26+67]
- Added GeoJSON and Shapefile export formats

## [0.9.25+66]
- big code refactor and fix exporting

## [0.9.24+65]
- Added more map types

## [0.9.23+64]
- Removed map downloading from opensource version

## [0.9.22+63]
- Added pre-downloading map

## [0.9.21+62]
- Added map caching

## [0.9.20+61]
- Added sliding points on map

## [0.9.19+60]
- Add angle display in PointsToolView and PointDetailsPage with dynamic calculation

## [0.9.18+59]
- Added angles and colors based on angles

## [0.9.17+58]
- Updated photo notes and fixed some UI icons

## [0.9.16+57]
- update photo manager

## [0.9.15+56]
- UI update

## [0.9.14+55]
- Update version to 0.9.14+55 and enhance Points Tool View with expandable point details

## [0.9.13+54]
- Updated project list UI

## [0.9.12+53]
- Added Offset from line and more localisations

## [0.9.11+52]
- Update version and enhance localization strings for no updates message

## [0.9.10+51]
- Reformat project files.

## [0.9.7+48]
- Merge remote-tracking branch 'origin/main'

## [0.9.2+43]
- Implement point editing functionality in PointDetailsPanel and MapToolView

## [0.8.2+39]
- Update pubspec versions

## [0.7.6+36]
- feat: Add localization for map tool view

## [0.7.3+32]
- Refactor: Add heroTags to FABs and implement landscape layout for ProjectPage

## [0.7.1+30]
- Refactor: Simplify flavor setup scripts and ignore pubspec.lock

## [0.3.1+25]
- feat: Implement "Move Point" functionality in Map Tool

## [0.2.3+21]
- Refactor: Simplify project list update logic

## [0.2.2+20]
- Refactor: Improve tab switching and remove redundant save logic

## [0.2.1+19]
- Refactor: Transition ProjectDetailsPage to TabBarView

## [0.1.1+18]
- feat: Implement interactive map in MapToolView

## [0.0.10+17]
- feat: Add "NEW" badge to newly added points in `PointsToolView`

## [0.0.9+16]
- feat: Add Heading and Timestamp to Points

## [0.0.8+15]
- feat: Allow setting compass point as END point

## [0.0.7+14]
- feat: Highlight start/end points in PointsToolView list

## [0.0.6+13]
- feat: Add loading indicator to "Add Point" in Compass Tool

## [0.0.5+10]
- feat: Implement dirty checking and enhance save/navigation logic in ProjectDetailsPage

## [0.0.3+8]
- feat: Update project start/end points dynamically and calculate azimuth

## [0.0.2+7]
- Refactor: Improve point deletion and ordinal re-sequencing

## [0.0.2+6]
- feat: Implement "Add Point" from Compass Tool

## [0.0.1+3]
- feat: Implement Compass Tool View with dynamic heading display

## [0.0.1+1]
- feat: Implement project creation and details editing

## [0.9.29+70] - 2025-07-08
### Added
- GPS precision feature: Introduced gpsPrecision field in PointModel, updated database schema, and enhanced UI to display GPS precision. Updated localization for new label in English and Italian.

### Changed
- Refactored Point Editor: Replaced PointCoordinatesSection with PointDetailsSection to consolidate point details (latitude, longitude, altitude, note, GPS precision) into a single UI component. Updated localization for new section title in English and Italian, and adjusted related controllers and validation logic.

