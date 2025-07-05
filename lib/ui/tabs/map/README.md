# Map Components Structure

This directory contains the refactored map components, split from the original large `map_tool_view.dart` file for better maintainability and organization.

## Directory Structure

```
map/
├── debug/
│   └── debug_panel.dart              # Debug panel widget for development
├── markers/
│   ├── azimuth_arrow.dart            # Project azimuth arrow marker
│   ├── location_markers.dart         # Current location accuracy marker
│   └── polyline_arrowhead.dart       # Polyline path arrowhead marker
├── state/
│   └── map_state_manager.dart        # Map state management logic
├── widgets/
│   ├── flutter_map_widget.dart       # Main FlutterMap widget component
│   └── map_loading_widget.dart       # Loading state widget
├── map_controller.dart               # Business logic controller
├── map_controls.dart                 # Map control widgets (FABs, type selector)
├── map_markers.dart                  # Project point markers
├── map_tool_view.dart                # Main map view (refactored)
├── point_details_panel.dart          # Point details panel
└── README.md                         # This file
```

## Component Descriptions

### Debug Components (`debug/`)
- **`debug_panel.dart`**: Debug panel widget that displays sensor data, location information, and compass accuracy for development purposes.

### Marker Components (`markers/`)
- **`azimuth_arrow.dart`**: Custom marker that displays the project azimuth direction as an arrow overlay on the current location.
- **`location_markers.dart`**: Custom location marker with accuracy circle visualization.
- **`polyline_arrowhead.dart`**: Animated arrowhead marker that moves along polyline paths.

### State Management (`state/`)
- **`map_state_manager.dart`**: Centralized state management for all map-related state, including location tracking, compass data, point management, and UI state.

### Widget Components (`widgets/`)
- **`flutter_map_widget.dart`**: Main FlutterMap widget that handles the map rendering, layers, and interactions.
- **`map_loading_widget.dart`**: Loading state widget displayed while map data is being loaded.

### Core Files
- **`map_controller.dart`**: Business logic controller for map operations, calculations, and data management.
- **`map_controls.dart`**: Floating action buttons, map type selector, and permission overlays.
- **`map_markers.dart`**: Project point marker generation and styling.
- **`map_tool_view.dart`**: Main map view that orchestrates all components and handles user interactions.
- **`point_details_panel.dart`**: Panel for displaying and editing point details.

## Benefits of Refactoring

1. **Maintainability**: Each component has a single responsibility and is easier to understand and modify.
2. **Reusability**: Components can be reused in other parts of the application.
3. **Testability**: Smaller, focused components are easier to unit test.
4. **Collaboration**: Multiple developers can work on different components simultaneously.
5. **Performance**: Better separation of concerns can lead to more efficient rebuilds.

## Usage

The main entry point is `map_tool_view.dart`, which imports and uses all the other components. The state management is handled through `MapStateManager`, which coordinates between the UI components and the business logic in `MapControllerLogic`.

## State Management

The `MapStateManager` class centralizes all map-related state and provides methods for:
- Location and compass data management
- Point operations (add, move, delete, update)
- Map fitting and navigation
- Permission handling
- Animation control

This separation allows the UI components to focus on rendering while the state manager handles all the complex logic and state transitions. 