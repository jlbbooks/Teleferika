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
  terrain;
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
Cache stores are created during app initialization in `lib/main.dart`:
```dart
for (final mapType in MapType.values) {
  final storeName = mapType.cacheStoreName;
  await FMTCStore(storeName).manage.create();
  MapCacheLogger.logStoreCreated(storeName);
}
```

### Cache Store Usage
The `FlutterMapWidget` uses the appropriate cache store based on the current map type:
```dart
FMTCTileProvider _getTileProvider(MapType mapType) {
  final storeName = MapStoreUtils.getStoreNameForMapType(mapType);
  return FMTCTileProvider(
    stores: {storeName: BrowseStoreStrategy.readUpdateCreate},
  );
}
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

## Best Practices

1. **Always use the enum**: Never hardcode map type strings
2. **Use appropriate getters**: Use `name` for internal logic, `getUiName()` for UI display
3. **Handle localization**: Always provide fallbacks when localization is not available
4. **Cache efficiently**: Each map type has its own cache to avoid conflicts
5. **Respect attribution**: Always display the required attribution for each map type
6. **Test thoroughly**: Verify that new map types work across all supported locales

## Related Files

- `lib/ui/tabs/map/map_type.dart` - Core MapType enum
- `lib/ui/tabs/map/services/map_store_utils.dart` - Cache store utilities
- `lib/ui/tabs/map/services/map_cache_logger.dart` - Cache logging
- `lib/ui/tabs/map/services/map_preferences_service.dart` - Preferences management
- `lib/ui/tabs/map/widgets/map_type_selector.dart` - UI selector
- `lib/l10n/app_en.arb` & `lib/l10n/app_it.arb` - Localization
- `lib/main.dart` - Cache store initialization
- `lib/ui/tabs/map/widgets/flutter_map_widget.dart` - Map widget implementation 