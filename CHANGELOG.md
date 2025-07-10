# Changelog

All notable changes to this project will be documented in this file.

## [0.9.33+74] - 2025-07-10
### Fixed
- **Export Functionality**: Fixed hanging export dialog issue in licensed features
  - Replaced modal dialog approach with OverlayEntry for reliable dismissal
  - Added comprehensive logging to track export operation flow
  - Improved error handling to ensure loading dialog is always dismissed
  - Enhanced parameter validation with detailed debugging information
  - Export operations now complete successfully and provide proper user feedback

### Technical
- Enhanced GPS accuracy circle implementation with proper meters-to-pixels conversion
- Restored map download page initialization methods (_initializeZoomLevels and _loadLastKnownLocation)
- Improved map preferences service integration for last known location loading

## [0.9.32+73] - 2025-07-10
### Added
- Conditional localization mechanism for licensed features (LfpLocalizations)
- Localization support for licensed features package
- Enhanced map marker and point interaction features

### Changed
- Improved handling of unsaved points in map interactions
- Enhanced MapMarkers to accept custom points list
- Center map to current location when adding a point
- Updated setup-flavor.sh for robust flavor-aware localization

### Technical
- Bumped licensed_features_package version and updated subproject commit
- Updated CONTRIBUTING.md with documentation for conditional localization

## [0.9.31+72] - 2025-01-27
### Added
- **Map Zoom Controls**: Added zoom in/out buttons with zoom level indicator
  - Positioned at bottom right corner for easy thumb access on mobile devices
  - Real-time zoom level display with one decimal place precision
  - Respects map type's min/max zoom constraints from MapType configuration
  - Visual feedback with pale red color when buttons reach zoom limits
  - Enhanced zoom functions that set zoom to exact min/max when out of bounds
  - Comprehensive event handling for all zoom interactions (gestures, buttons, programmatic)
- **Enhanced Attribution**: Improved attribution widget positioning and styling
  - Uses RichAttributionWidget for consistent flutter_map integration
  - Proper clickable attribution with URL support when available

### Changed
- **Map UI**: Reorganized map controls for better user experience
  - Zoom controls moved to bottom right for mobile accessibility
  - Attribution positioned using flutter_map's built-in attribution system
  - Improved visual hierarchy and spacing of map interface elements

### Technical
- **Zoom Synchronization**: Implemented robust zoom level tracking across all interaction methods
  - Dual event handling via onMapEvent and mapController.stream
  - Handles all MapEvent types that can change zoom (MapEventMove, MapEventRotate, MapEventFlingAnimation, MapEventDoubleTapZoom, MapEventScrollWheelZoom, MapEventNonRotatedSizeChange)
  - Proper state management with mounted checks and error handling

## [Unreleased]
### Added
- **MapType**: Added minZoom and maxZoom properties to all map types based on actual HTTP testing
  - OpenStreetMap: 0-19 zoom levels
  - Esri Satellite: 0-23 zoom levels  
  - Esri World Topo: 0-23 zoom levels
  - OpenTopoMap: 0-17 zoom levels
  - CartoDB Positron: 0-20 zoom levels
  - Thunderforest Outdoors: 0-22 zoom levels
  - Thunderforest Landscape: 0-22 zoom levels
- **MapDownloadService**: Added zoom level validation against map type's supported range
  - Validates min/max zoom levels before starting downloads
  - Throws ArgumentError if zoom levels are outside supported range
  - Added getSupportedZoomRange() helper method
- **LicencedMapDownloadPage**: Enhanced zoom slider functionality with map type constraints
  - Replaced separate min/max sliders with a single RangeSlider showing full range (0-23)
  - Added red zones to visually indicate unsupported zoom ranges for each map type
  - Automatic validation prevents selecting values outside the map type's supported range
  - Visual legend explains red zones as "Unsupported by [MapType]"
  - Automatic adjustment of zoom levels when switching map types
  - Visual indicator in help panel showing supported zoom range for current map type
  - Proper initialization of zoom levels within valid ranges

### Fixed
- **LicencedMapDownloadPage**: Restored bulk download validation logic that was removed during redesign
  - Fixed download button to respect `allowsBulkDownload` property from selected map type
  - Restored red error message overlay for map types that don't allow bulk downloads
  - Added comprehensive documentation for bulk download restrictions and validation
  - Enhanced user feedback with visual indicators for restricted map types

### Changed
- **LicencedMapDownloadPage**: Updated documentation to include bulk download validation features
  - Added documentation for bulk download restrictions and error handling
  - Enhanced method documentation with validation details
  - Added inline comments explaining UI logic for bulk download restrictions
- **MapCacheManager**: Added TODO comment with researched zoom level information for future implementation

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

