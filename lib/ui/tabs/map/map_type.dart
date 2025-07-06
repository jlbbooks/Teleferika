import 'package:teleferika/l10n/app_localizations.dart';

/// Enhanced MapType enum with getters for name and cache store name
enum MapType {
  openStreetMap,
  satellite,
  terrain;

  /// Get a nicely formatted display name for the map type
  String get name {
    switch (this) {
      case MapType.openStreetMap:
        return 'Open Street Map';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
    }
  }

  /// Get the cache store name for this map type
  String get cacheStoreName => 'mapStore_${toString().split('.').last}';

  /// Get the UI display name for this map type (localized if available)
  String getUiName([S? localizations]) {
    if (localizations == null) return name;

    switch (this) {
      case MapType.openStreetMap:
        return localizations.mapTypeStreet;
      case MapType.satellite:
        return localizations.mapTypeSatellite;
      case MapType.terrain:
        return localizations.mapTypeTerrain;
    }
  }

  /// Get the tile layer URL for this map type
  String get tileLayerUrl {
    switch (this) {
      case MapType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.terrain:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  /// Get the tile layer attribution for this map type
  String get tileLayerAttribution {
    switch (this) {
      case MapType.openStreetMap:
        return '© OpenStreetMap contributors';
      case MapType.satellite:
        return '© Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community';
      case MapType.terrain:
        return '© Esri — Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012';
    }
  }

  /// Get the attribution URL for this map type
  String get attributionUrl {
    switch (this) {
      case MapType.openStreetMap:
        return 'https://openstreetmap.org/copyright';
      case MapType.satellite:
      case MapType.terrain:
        return 'https://www.esri.com/en-us/home';
    }
  }
}
