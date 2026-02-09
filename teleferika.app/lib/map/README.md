# Map Components Structure

This directory contains the refactored map components, split from the original large `map_tool_view.dart` file for better maintainability and organization.

## Directory Structure

```
map/
├── debug/
│   └── debug_panel.dart              # Debug panel widget for development
├── markers/
│   ├── location_markers.dart         # Current location accuracy marker
│   ├── map_markers.dart              # Project point markers
│   ├── moving_marker.dart            # Moving marker for project azimuth
│   └── polyline_arrowhead.dart       # Polyline path arrowhead marker
├── services/
│   ├── location_service.dart         # Location and compass handling
│   ├── map_cache_logger.dart         # Map cache logging
│   ├── map_cache_manager.dart        # Map tile cache management
│   ├── map_preferences_service.dart # Map preferences persistence
│   └── map_store_utils.dart          # Map store utilities
├── state/
│   └── map_state_manager.dart        # Map state management logic
├── widgets/
│   ├── point_details/
│   │   ├── coordinates_section.dart  # Editable coordinates component
│   │   └── point_details_panel.dart  # Point details panel
│   ├── flutter_map_widget.dart       # Main FlutterMap widget component
│   ├── floating_action_buttons.dart  # Map FAB controls
│   ├── map_loading_widget.dart       # Loading state widget
│   ├── map_type_selector.dart        # Map type selection control
│   └── permission_overlay.dart       # Permission request overlay
├── map_controller.dart               # Business logic controller (legacy)
├── map_controls.dart                 # Map control widgets (legacy - being phased out)
├── map_tool_view.dart                # Main map view (refactored)
└── README.md                         # This file
```

## Component Descriptions

### Debug Components (`debug/`)
- **`debug_panel.dart`**: Debug panel widget that displays sensor data, location information, and compass accuracy for development purposes.

### Marker Components (`markers/`)
- **`location_markers.dart`**: Custom location marker with accuracy circle visualization.
- **`map_markers.dart`**: Project point marker generation and styling (moved from root).
- **`moving_marker.dart`**: Moving marker that displays the project azimuth direction as an arrow overlay on the current location.
- **`polyline_arrowhead.dart`**: Animated arrowhead marker that moves along polyline paths.

### Service Components (`services/`)
- **`location_service.dart`**: Manages location and compass data streams, permission handling, and sensor access.
- **`map_cache_*.dart`**: Map tile caching and preferences.
- **`map_store_utils.dart`**: Map store utilities.

Geometry calculations (bearings, distances, angles) live in **`lib/geometry/geometry_service.dart`** and are used by both map and points UI.

### State Management (`state/`)
- **`map_state_manager.dart`**: Centralized state management for all map-related state, including location tracking, compass data, point management, and UI state.

### Widget Components (`widgets/`)
- **`flutter_map_widget.dart`**: Main FlutterMap widget that handles the map rendering, layers, and interactions.
- **`floating_action_buttons.dart`**: Floating action buttons for map controls (extracted from map_controls.dart).
- **`map_loading_widget.dart`**: Loading state widget displayed while map data is being loaded.
- **`map_type_selector.dart`**: Map type selection control (extracted from map_controls.dart).
- **`permission_overlay.dart`**: Permission request overlay (extracted from map_controls.dart).

### Point Details Components (`widgets/point_details/`)
- **`point_details_panel.dart`**: Panel for displaying and editing point details.
- **`coordinates_section.dart`**: Editable coordinates component with inline editing capabilities.

### Core Files
- **`map_controller.dart`**: Business logic controller for map operations, calculations, and data management (legacy - being replaced by services).
- **`map_controls.dart`**: Floating action buttons, map type selector, and permission overlays (legacy - being phased out).
- **`map_tool_view.dart`**: Main map view that orchestrates all components and handles user interactions.

## Benefits of Refactoring

1. **Maintainability**: Each component has a single responsibility and is easier to understand and modify.
2. **Reusability**: Components can be reused in other parts of the application.
3. **Testability**: Smaller, focused components are easier to unit test.
4. **Collaboration**: Multiple developers can work on different components simultaneously.
5. **Performance**: Better separation of concerns can lead to more efficient rebuilds.
6. **Service Layer**: Clear separation between business logic (services) and UI components.
7. **Modularity**: Services can be easily swapped or extended without affecting UI components.

## Architecture

The refactored architecture follows a clean separation of concerns:

- **Services Layer**: Handles business logic, data operations, and external integrations
- **State Management**: Centralizes UI state and coordinates between services and UI
- **Widget Layer**: Pure UI components that receive data and callbacks
- **Main Orchestrator**: `map_tool_view.dart` coordinates all components

## Usage

The main entry point is `map_tool_view.dart`, which imports and uses all the other components. The state management is handled through `MapStateManager`, which coordinates between the UI components and the business logic services.

## Migration Status

- ✅ **Completed**: Widget extraction and organization
- ✅ **Completed**: Service layer creation
- ✅ **Completed**: Marker organization
- 🔄 **In Progress**: Legacy file cleanup
- ⏳ **Pending**: Full service layer integration

## State Management

The `MapStateManager` class centralizes all map-related state and provides methods for:
- Location and compass data management
- Point operations (add, move, delete, update)
- Map fitting and navigation
- Permission handling
- Animation control

This separation allows the UI components to focus on rendering while the state manager handles all the complex logic and state transitions. 