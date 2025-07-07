# Map Types in Teleferika

This document explains how map types are implemented and used throughout the Teleferika application.

## Overview

Teleferika supports multiple map types to provide users with different views of geographic data. Each map type has its own tile server, cache store, and localized display name.

## Map Type Enum

The core of the map type system is the `MapType` enum located in `lib/ui/tabs/map/map_type.dart`:

```dart
enum MapType {
  openStreetMap,
  satellite,
  terrain,
  opentopography;
}
```

## Getters and Properties

Each `MapType` instance provides several getters for different use cases:

### 1. Display Name (`name`)
Returns a nicely formatted display name for UI purposes:
```dart
MapType.openStreetMap.name // "Open Street Map"
MapType.satellite.name     // "Satellite"
MapType.terrain.name       // "Terrain"
```

### 2. Cache Store Name (`cacheStoreName`)
Returns the cache store identifier for tile caching:
```dart
MapType.openStreetMap.cacheStoreName // "mapStore_openStreetMap"
MapType.satellite.cacheStoreName     // "mapStore_satellite"
MapType.terrain.cacheStoreName       // "mapStore_terrain"
```

### 3. Localized UI Name (`getUiName()`)
Returns a localized display name based on the current app locale:
```dart
// English
mapType.getUiName(localizations) // "Open Street Map", "Satellite", "Terrain"

// Italian
mapType.getUiName(localizations) // "Mappa Stradale Aperta", "Satellite", "Terreno"
```

### 4. Tile Layer URL (`tileLayerUrl`)
Returns the tile server URL for the map type:
```dart
MapType.openStreetMap.tileLayerUrl // "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
MapType.satellite.tileLayerUrl     // "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
MapType.terrain.tileLayerUrl       // "https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}"
```

### 5. Attribution (`tileLayerAttribution` & `attributionUrl`)
Returns the required attribution information for each map type:
```dart
MapType.openStreetMap.tileLayerAttribution // "© OpenStreetMap contributors"
MapType.openStreetMap.attributionUrl       // "https://openstreetmap.org/copyright"
```

## Localization

Map type names are localized using a parameterized approach in the ARB files:

### English (`lib/l10n/app_en.arb`)
```json
"mapTypeName": "{mapType, select, openStreetMap {Open Street Map} satellite {Satellite} terrain {Terrain} other {Unknown}}"
```

### Italian (`lib/l10n/app_it.arb`)
```json
"mapTypeName": "{mapType, select, openStreetMap {Mappa Stradale Aperta} satellite {Satellite} terrain {Terreno} other {Sconosciuto}}"
```

The `getUiName()` method automatically passes the enum name as a parameter to get the correct localized string.

## Tile Caching

Each map type has its own dedicated cache store to optimize performance and storage:

### Cache Store Creation
Cache stores are created and validated during app initialization in `lib/main.dart`:
```dart
// Create and validate stores for each MapType enum value
await MapCacheManager.validateAllStores();
```

### Cache Store Usage with Error Handling
The `FlutterMapWidget` uses the error handler to get tile providers with automatic fallback:
```dart
FMTCTileProvider _getTileProvider(MapType mapType) {
  return MapCacheManager.getTileProviderWithFallback(mapType);
}
```

### Error Handling and Fallback
The system includes comprehensive error handling for cache store operations:

**Automatic Validation**: Stores are validated during initialization and their status is cached
**Graceful Degradation**: If a store fails, the system automatically falls back to a fallback store
**Recovery Mechanisms**: Failed stores can be revalidated or reset through debug tools

```dart
// Get tile provider with automatic error handling
FMTCTileProvider provider = MapCacheManager.getTileProviderWithFallback(mapType);

// Check store status
Map<String, String> status = MapCacheManager.getStoreStatus();

// Revalidate all stores
await MapCacheManager.validateAllStores();

// Reset validation state for recovery
MapCacheManager.resetAllStoreValidation();
```

## Usage Patterns

### 1. Map Type Selection
Users can change map types using the `MapTypeSelector` widget:
```dart
MapTypeSelector.build(
  currentMapType: _stateManager.currentMapType,
  onMapTypeChanged: (mapType) {
    setState(() {
      _stateManager.currentMapType = mapType;
    });
  },
  context: context,
)
```

### 2. State Management
Map type state is managed in `MapStateManager`:
```dart
MapType _currentMapType = MapType.openStreetMap;

MapType get currentMapType => _currentMapType;

set currentMapType(MapType value) {
  if (_currentMapType != value) {
    _currentMapType = value;
    MapPreferencesService.saveMapType(value);
    MapCacheLogger.logCachePerformance(value);
    notifyListeners();
  }
}
```

### 3. Preferences
Map type preferences are persisted using `MapPreferencesService`:
```dart
// Save preference
await MapPreferencesService.saveMapType(mapType);

// Load preference
final savedMapType = await MapPreferencesService.loadMapType();
```

### 4. Tile Layer Configuration
The `FlutterMapWidget` configures tile layers based on the current map type:
```dart
TileLayer(
  urlTemplate: widget.currentMapType.tileLayerUrl,
  userAgentPackageName: 'com.jlbbooks.teleferika',
  tileProvider: _getTileProvider(widget.currentMapType),
),
RichAttributionWidget(
  attributions: [
    TextSourceAttribution(
      widget.currentMapType.tileLayerAttribution,
      onTap: () => launchUrl(Uri.parse(widget.currentMapType.attributionUrl)),
    ),
  ],
),
```

## Adding New Map Types

To add a new map type:

1. **Add to Enum**: Add the new value to the `MapType` enum
2. **Update Getters**: Add the new case to all getters (`tileLayerUrl`, `tileLayerAttribution`, etc.)
3. **Add Localization**: Add the new map type to the `mapTypeName` select statement in both ARB files
4. **Update Cache**: The cache store will be automatically created during app initialization
5. **Update UI**: Add the new map type to the `MapTypeSelector` widget

### Example: Adding a "Hybrid" Map Type
```dart
enum MapType {
  openStreetMap,
  satellite,
  terrain,
  hybrid; // New map type
}

// Update getters
String get tileLayerUrl {
  switch (this) {
    // ... existing cases
    case MapType.hybrid:
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  }
}
```

```json
// Update ARB files
"mapTypeName": "{mapType, select, openStreetMap {Open Street Map} satellite {Satellite} terrain {Terrain} hybrid {Hybrid} other {Unknown}}"
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

## Related Files

- `lib/ui/tabs/map/map_type.dart` - Core MapType enum
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

### Common Cache Store Errors

**Error**: `StoreNotExists: The requested store 'xyz' did not exist`

**Solution**: This error occurs when a cache store is missing or corrupted. The error handler automatically provides a fallback, but you can also:

1. Use the debug panel's "Store Status" button to check store health
2. Click "Revalidate All" to recreate missing stores
3. Click "Reset Validation" to clear cached validation state
4. Restart the app to trigger automatic store creation

**Error**: `StoreExists: The requested store 'xyz' already exists`

**Solution**: This is a normal error during store creation. The error handler automatically handles this by catching the exception and continuing.

**Error**: Map tiles not loading or showing blank areas

**Solution**: 
1. Check if the current map type's store is validated (use debug panel)
2. Try switching to a different map type
3. Use "Revalidate All" in the debug panel
4. Check network connectivity for tile servers

### Debug Tools Usage

**Store Status Dialog**: Shows the validation status of all cache stores with color coding:
- 🟢 **Green**: Store is validated and working
- 🔴 **Red**: Store has failed and will use fallback
- 🟠 **Orange**: Store status is unknown

**Revalidate All**: Recreates and validates all cache stores. Use this when stores are corrupted or missing.

**Reset Validation**: Clears the cached validation state. Use this to force fresh validation of all stores.

### Performance Monitoring

Monitor cache performance using the debug panel's "Log Cache Stats" button, which shows:
- Total cache size across all stores
- Individual store statistics (size, length, hits, misses)
- Error information for failed stores

### Recovery Procedures

**For Corrupted Stores**:
1. Use "Revalidate All" in debug panel
2. If that fails, use "Reset Validation" then "Revalidate All"
3. As a last resort, clear app data and restart

**For Missing Stores**:
1. Restart the app (stores are created during initialization)
2. Use "Revalidate All" in debug panel
3. Check logs for store creation errors

**For Performance Issues**:
1. Monitor cache statistics using debug tools
2. Clear individual store caches if needed
3. Check for network connectivity issues 