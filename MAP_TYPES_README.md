# Map Types in Teleferika

This document explains how map types are implemented and used throughout the Teleferika application.

## Overview

Teleferika supports multiple map types to provide users with different views of geographic data. Each map type has its own tile server, cache store, and localized display name.

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
  // ...
}
```

### Static List of Map Types

All available map types are defined in a static list:

```dart
static const List<MapType> all = [openStreetMap, satellite, terrain];
```

### Lookup by ID

You can look up a map type by its id:

```dart
MapType type = MapType.of('openStreetMap');
```

### Example MapType Definition

```dart
static const MapType openStreetMap = MapType(
  id: 'openStreetMap',
  name: 'Open Street Map',
  cacheStoreName: 'mapStore_openStreetMap',
  allowsBulkDownload: false,
  tileLayerUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  tileLayerAttribution: '© OpenStreetMap contributors',
  attributionUrl: 'https://openstreetmap.org/copyright',
  icon: Icons.map,
);
```

## Accessing Properties

You can access properties directly:

```dart
String url = mapType.tileLayerUrl;
String name = mapType.getUiName(localizations);
IconData icon = mapType.icon;
```

## Localization

Map type names are localized using the `getUiName()` method, which uses the id for lookup in ARB files.

## Usage Patterns

### 1. Map Type Selection

Iterate over `MapType.all` to build selectors:

```dart
for (final mapType in MapType.all) {
  // Use mapType in dropdowns, menus, etc.
}
```

### 2. State Management

Store the current map type as a `MapType` instance. Persist the id string and use `MapType.of(id)` to restore.

### 3. Preferences

Save the map type id to preferences. Restore using `MapType.of(savedId)`.

### 4. Tile Layer Configuration

Configure tile layers using the properties of the selected `MapType` instance.

## Adding New Map Types

To add a new map type:

1. **Define a new MapType**: Add a new static const in `MapType` and add it to the `all` list.
2. **Add Localization**: Add the new map type id to the `mapTypeName` select statement in both ARB files.
3. **Update UI**: The new map type will automatically appear in selectors if you iterate over `MapType.all`.

### Example: Adding a "Hybrid" Map Type

```dart
static const MapType hybrid = MapType(
  id: 'hybrid',
  name: 'Hybrid',
  cacheStoreName: 'mapStore_hybrid',
  allowsBulkDownload: true,
  tileLayerUrl: 'https://example.com/hybrid/{z}/{x}/{y}.png',
  tileLayerAttribution: '© Example',
  attributionUrl: 'https://example.com',
  icon: Icons.layers,
);

static const List<MapType> all = [openStreetMap, satellite, terrain, hybrid];
```

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
