# Map Types in Teleferika

This document explains how map types are implemented and used throughout the Teleferika application.

## Overview

Teleferika supports multiple map types to provide users with different views of geographic data. Each map type has its own tile server, cache store, and localized display name.

## Available Map Types

### 1. **OpenStreetMap** (Basic Street Map)
- **URL**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Features**: Standard street map with roads, buildings, and basic geographic features
- **Elevation Data**: No
- **Best For**: General navigation and street-level detail

### 2. **Esri Satellite** (Aerial Imagery)
- **URL**: `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}`
- **Features**: High-resolution satellite imagery
- **Elevation Data**: No
- **Best For**: Aerial reconnaissance and visual identification

### 3. **Esri World Topo** (Topographic Map)
- **URL**: `https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}`
- **Features**: Topographic map with terrain shading and contour lines
- **Elevation Data**: Yes, through visual representation
- **Best For**: General topographic analysis

### 4. **Open Topo Map** ⭐ **NEW - Excellent for Europe**
- **URL**: `https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png`
- **Features**: High-quality topographic maps with detailed contour lines
- **Elevation Data**: Yes, excellent contour line detail
- **Best For**: European topographic surveys, elevation analysis
- **Coverage**: Excellent European coverage

### 5. **Thunderforest Outdoors** ⭐ **NEW - Outdoor Focus**
- **URL**: `https://{s}.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png`
- **Features**: Outdoor-focused maps with hiking trails, elevation contours
- **Elevation Data**: Yes, detailed contour lines and terrain features
- **Best For**: Outdoor activities, hiking, field surveys
- **Coverage**: Good European coverage

### 6. **CartoDB Positron** ⭐ **NEW - Clean Base**
- **URL**: `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png`
- **Features**: Clean, minimal design with subtle terrain shading
- **Elevation Data**: Minimal, through subtle shading
- **Best For**: Clean base maps for overlaying data
- **Coverage**: Global coverage

### 7. **Stamen Terrain** ⭐ **NEW - Artistic Terrain**
- **URL**: `https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}{r}.png`
- **Features**: Artistic terrain visualization with elevation shading
- **Elevation Data**: Yes, through artistic terrain representation
- **Best For**: Visual terrain analysis with artistic appeal
- **Coverage**: Global coverage

### 8. **OpenMapTiles Terrain** ⭐ **NEW - High-Quality Terrain**
- **URL**: `https://tiles.maptiler.com/terrain/{z}/{x}/{y}.png`
- **Features**: High-quality terrain visualization with detailed elevation data
- **Elevation Data**: Yes, excellent terrain representation
- **Best For**: Professional topographic analysis
- **Coverage**: Global coverage

## MapType Class (Data-Driven)

The core of the map type system is the `MapType` class located in `lib/ui/tabs/map/map_type.dart`:

```dart
class MapType {
  final String id;
  final String name;
  final String cacheStoreName;
  final bool allowsBulkDownload;
  final String tileLayerUrl;
  final String tileLayerAttribution;
  final String attributionUrl;
  final IconData icon;
  final bool supportsRetina;
  // ...
}
```

### Static List of Map Types

All available map types are defined directly in a static list:

```dart
static const List<MapType> all = [
  MapType(
    id: 'openStreetMap',
    name: 'Open Street Map',
    // ... other properties
  ),
  MapType(
    id: 'satellite',
    name: 'Satellite',
    // ... other properties
  ),
  // ... more map types
];
```

### Lookup by ID

You can look up a map type by its id:

```dart
MapType type = MapType.of('openStreetMap');
```

### Example MapType Definition

```dart
MapType(
  id: 'cartoPositron',
  name: 'CartoDB Positron',
  cacheStoreName: 'mapStore_cartoPositron',
  allowsBulkDownload: true,
  tileLayerUrl: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
  tileLayerAttribution: '© OpenStreetMap contributors, © CartoDB',
  attributionUrl: 'https://carto.com/',
  icon: Icons.map_outlined,
  supportsRetina: true,
),
```

## Accessing Properties

You can access properties directly:

```dart
String url = mapType.tileLayerUrl;
String name = mapType.getUiName(localizations);
IconData icon = mapType.icon;
```

## Localization

Map type names are taken directly from the `name` field in the `MapType` definition. The `getUiName()` method returns the `name` field directly.

## Usage Patterns

### 1. Map Type Selection

Iterate over `MapType.all` to build selectors:

```dart
for (final mapType in MapType.all) {
  // Use mapType in dropdowns, menus, etc.
}
```

### 2. State Management

Map types are managed through the `MapStateManager` and stored in `SharedPreferences` via `MapPreferencesService`.

### 3. Caching

Each map type has its own cache store for offline access:

```dart
String storeName = mapType.cacheStoreName; // e.g., 'mapStore_openTopoMap'
```

## Recommendations for European Elevation Data

For European projects requiring elevation data, we recommend:

1. **Open Topo Map** - Best overall for European topographic surveys
2. **Thunderforest Outdoors** - Excellent for outdoor field work
3. **OpenMapTiles Terrain** - High-quality terrain visualization
4. **Stamen Terrain** - Artistic terrain representation

## Adding New Map Types

To add a new map type:

1. Add the `MapType` entry directly to the `all` list in `map_type.dart`
2. Add to licensed features if applicable
3. Regenerate localization files with `flutter gen-l10n`

### Retina Mode Support

If the map type URL template includes the `{r}` placeholder for retina mode, set `supportsRetina: true`:

```dart
MapType(
  id: 'example',
  name: 'Example Map',
  cacheStoreName: 'mapStore_example',
  allowsBulkDownload: true,
  tileLayerUrl: 'https://example.com/tiles/{z}/{x}/{y}{r}.png', // Note the {r} placeholder
  tileLayerAttribution: '© Example',
  attributionUrl: 'https://example.com',
  icon: Icons.map,
  supportsRetina: true, // Enable retina mode for high-DPI displays
),
```

## Technical Notes

- All map types support bulk download for offline use
- Each map type has its own cache store for performance
- Attribution is automatically displayed on the map
- Map types are automatically included in the map type selector
- Localization is handled through the standard Flutter localization system

## Retina Mode Support

Some map types support high-resolution tiles for retina displays using the `{r}` placeholder in their URL templates. These map types have `supportsRetina: true` and will automatically use high-resolution tiles on high-density displays:

- **CartoDB Positron** - Supports retina mode for crisp display on high-DPI screens
- **Stamen Terrain** - Supports retina mode for high-quality terrain visualization

The `supportsRetina` field is automatically used by the `TileLayer` configuration to enable `RetinaMode.isHighDensity` when appropriate.

## Best Practices

1. **Always use the MapType class**: Never hardcode map type strings or use enums.
2. **Use the static list**: Iterate over `MapType.all` for selectors and utilities.
3. **Persist by id**: Store the id string, not the whole object.
4. **Handle localization**: Always provide fallbacks when localization is not available.
5. **Respect attribution**: Always display the required attribution for each map type.
6. **Test thoroughly**: Verify that new map types work across all supported locales.

## Related Files

- `lib/ui/tabs/map/map_type.dart` - Core MapType class
- `lib/ui/tabs/map/services/map_store_utils.dart` - Cache store utilities
- `lib/ui/tabs/map/services/map_cache_logger.dart` - Cache logging
- `lib/ui/tabs/map/services/map_cache_error_handler.dart` - Error handling and fallback
- `lib/ui/tabs/map/services/map_preferences_service.dart` - Preferences management
- `lib/ui/tabs/map/widgets/map_type_selector.dart` - UI selector
- `lib/ui/tabs/map/debug/debug_panel.dart` - Debug tools for cache management
- `lib/l10n/app_en.arb` & `lib/l10n/app_it.arb` - Localization
- `lib/main.dart` - Cache store initialization
- `lib/ui/tabs/map/widgets/flutter_map_widget.dart` - Map widget implementation

## Troubleshooting

- If a map type is missing from selectors, ensure it is included in `MapType.all`.
- If localization is missing, update the ARB files with the new id.
- If you see errors about missing properties, check your MapType definition for required fields.

```dart
// Example: Handle store errors in your code
try {
  final provider = MapCacheManager.getTileProviderWithFallback(mapType);
  // Use provider normally
} catch (e) {
  // The error handler has already provided a fallback
  // Log the error for debugging
  logger.warning('Store error handled by fallback: $e');
}
```

## Cache Management

### Cache Statistics
Cache performance is logged using `MapCacheLogger`:
```dart
// Log cache performance for current map type
MapCacheLogger.logCachePerformance(mapType);

// Log all cache statistics
MapCacheLogger.logAllCacheStats();
```

### Cache Cleanup
Cache stores can be managed individually or globally:
```dart
// Clear specific map type cache
await FMTCStore(mapType.cacheStoreName).manage.delete();

// Clear all caches
await FMTCRoot.instance.reset();
```

### Debug Tools
The debug panel provides tools for cache store management:

**Store Status**: View the validation status of all cache stores
**Revalidate All**: Re-run validation for all stores
**Reset Validation**: Clear validation state to force re-validation

Access these tools through the debug panel's "Store Status" button.

### Error Recovery
When cache stores fail, the system provides multiple recovery options:

1. **Automatic Fallback**: Failed stores automatically fall back to a fallback store
2. **Manual Revalidation**: Use debug tools to revalidate failed stores
3. **Store Reset**: Clear and recreate stores if needed
4. **Validation Reset**: Reset validation state to force fresh validation

```dart
// Example: Handle store errors in your code
try {
  final provider = MapCacheManager.getTileProviderWithFallback(mapType);
  // Use provider normally
} catch (e) {
  // The error handler has already provided a fallback
  // Log the error for debugging
  logger.warning('Store error handled by fallback: $e');
}
```

## Best Practices

1. **Always use the enum**: Never hardcode map type strings
2. **Use appropriate getters**: Use `name` for internal logic, `getUiName()` for UI display
3. **Handle localization**: Always provide fallbacks when localization is not available
4. **Cache efficiently**: Each map type has its own cache to avoid conflicts
5. **Respect attribution**: Always display the required attribution for each map type
6. **Test thoroughly**: Verify that new map types work across all supported locales
7. **Use error handling**: Always use `MapCacheManager.getTileProviderWithFallback()` for tile providers
8. **Monitor store status**: Use debug tools to monitor cache store health
9. **Handle errors gracefully**: Implement proper error handling for cache operations
10. **Validate stores**: Ensure stores are properly validated during initialization
