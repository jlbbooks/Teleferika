# ProjectPointsLayer Widget

## Overview

The `ProjectPointsLayer` is a reusable Flutter widget designed to display project points as markers and connect them with polylines on any FlutterMap. It provides a consistent way to visualize project data across different map views in the Teleferika application.

## Features

- **Dual Data Source Support**: Automatically tries to get projects from the Provider first, then falls back to database loading
- **Flexible Exclusion**: Can exclude specific projects from display (useful when showing project details)
- **Customizable Appearance**: Configurable marker size, colors, and line styling
- **Automatic Loading**: Handles loading states gracefully without blocking the UI
- **Error Handling**: Robust error handling with logging for debugging

## Usage

The widget provides two ways to use it:

1. **Static Method (Recommended)**: Use `ProjectPointsLayer.createLayers()` to get a list of layers that can be spread into FlutterMap children
2. **Widget Approach**: Use the widget directly (legacy approach, may have limitations)

### Static Method Approach (Recommended)

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:teleferika/ui/widgets/project_points_layer.dart';

FlutterMap(
  mapController: mapController,
  options: MapOptions(
    center: LatLng(45.4642, 9.1900),
    zoom: 13.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    // Add the project points layers using the static method
    ...ProjectPointsLayer.createLayers(),
  ],
)
```

### With Custom Styling

```dart
...ProjectPointsLayer.createLayers(
  markerSize: 12.0,
  markerColor: Colors.red,
  markerBorderColor: Colors.white,
  markerBorderWidth: 2.0,
  lineColor: Colors.blue,
  lineWidth: 2.0,
)
```

### Excluding a Specific Project

```dart
...ProjectPointsLayer.createLayers(
  excludeProjectId: 'current-project-id',
  markerSize: 8.0,
  markerColor: Colors.green,
)
```

### With Pre-loaded Projects

```dart
...ProjectPointsLayer.createLayers(
  projects: myProjectsList,
  markerColor: Colors.orange,
)
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `projects` | `List<ProjectModel>?` | `null` | Pre-loaded projects to display. If null, will load from Provider or database |
| `excludeProjectId` | `String?` | `null` | ID of project to exclude from display |
| `markerSize` | `double` | `8.0` | Size of point markers in pixels |
| `markerColor` | `Color` | `Colors.blue` | Fill color of point markers |
| `markerBorderColor` | `Color` | `Colors.white` | Border color of point markers |
| `markerBorderWidth` | `double` | `1.0` | Width of marker border in pixels |
| `lineColor` | `Color` | `Colors.black` | Color of connecting polylines |
| `lineWidth` | `double` | `1.0` | Width of polylines in pixels |

## Data Loading Strategy

The widget implements a smart data loading strategy:

1. **Direct Projects**: If `projects` parameter is provided, uses those directly
2. **Provider Access**: Tries to access projects through the global state Provider
3. **Database Fallback**: If Provider is unavailable, loads all projects from the database
4. **Error Handling**: Gracefully handles loading errors and continues operation

### Provider Integration

The widget automatically integrates with the global state management system:

```dart
// In didChangeDependencies()
final projectState = context.projectStateListen;
if (projectState.hasProject) {
  // Provider has project data available
  _loadProjectsFromDatabase(); // Currently loads all projects
} else {
  _loadProjectsFromDatabase();
}
```

## Visual Elements

### Point Markers
- **Shape**: Circular markers
- **Size**: Configurable (default: 8px)
- **Colors**: Customizable fill and border colors
- **Positioning**: Placed at each project point's latitude/longitude

### Project Polylines
- **Connection**: Lines connecting points within each project
- **Style**: Simple straight lines with configurable color and width
- **Filtering**: Only displays polylines for projects with 2+ valid points

## Error Handling

The widget includes comprehensive error handling:

- **Provider Access**: Catches Provider access errors and falls back to database
- **Database Loading**: Handles database query errors gracefully
- **Invalid Coordinates**: Filters out points with null latitude/longitude
- **Loading States**: Shows nothing during loading to avoid UI blocking

## Performance Considerations

- **Efficient Loading**: Only loads data when dependencies change
- **State Management**: Properly manages loading states to prevent multiple simultaneous requests
- **Memory Management**: Cleans up resources when widget is disposed
- **Coordinate Validation**: Filters invalid coordinates before creating markers

## Integration Examples

### In Project Details Page
```dart
// Show all projects except the current one
...ProjectPointsLayer.createLayers(
  excludeProjectId: currentProject.id,
  markerSize: 6.0,
  markerColor: Colors.grey,
  lineColor: Colors.grey,
)
```

### In Offline Map Download Page
```dart
// Show all projects for context
...ProjectPointsLayer.createLayers(
  markerSize: 10.0,
  markerColor: Colors.blue,
  lineColor: Colors.blue,
)
```

### In Projects List Map View
```dart
// Show all projects with default styling
...ProjectPointsLayer.createLayers()
```

## Dependencies

- `flutter_map`: For map integration
- `latlong2`: For coordinate handling
- `provider`: For global state access
- `teleferika/core/project_provider.dart`: For project state management
- `teleferika/db/database_helper.dart`: For database access
- `teleferika/db/models/project_model.dart`: For project data model
- `logging`: For error logging and debugging

## Future Enhancements

Potential improvements for the widget:

1. **Caching**: Implement project data caching to reduce database queries
2. **Clustering**: Add marker clustering for dense point areas
3. **Interactive Markers**: Add tap callbacks for marker interaction
4. **Animation**: Add smooth animations for marker appearance
5. **Filtering**: Add more sophisticated filtering options (by date, type, etc.)
6. **Custom Markers**: Support for custom marker widgets beyond simple circles

## Troubleshooting

### Common Issues

1. **No markers showing**: Check if projects have valid latitude/longitude coordinates
2. **Provider errors**: Ensure the widget is used within a Provider context
3. **Database errors**: Verify database connection and project data integrity
4. **Performance issues**: Consider reducing marker size or implementing clustering for large datasets

### Debug Logging

The widget includes comprehensive logging for debugging:

```dart
final Logger _logger = Logger('ProjectPointsLayer');
```

Check the logs for:
- Provider access attempts
- Database loading operations
- Error conditions
- Data filtering results 