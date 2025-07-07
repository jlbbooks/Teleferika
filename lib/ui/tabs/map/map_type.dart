import 'package:teleferika/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Enhanced MapType enum with getters for name and cache store name
enum MapType {
  openStreetMap,
  satellite,
  terrain,
  opentopography;

  /// Get a nicely formatted display name for the map type
  String get name {
    switch (this) {
      case MapType.openStreetMap:
        return 'Open Street Map';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      case MapType.opentopography:
        return 'OpenTopography';
    }
  }

  /// Get a single stringname for this map type, e.g. for the cache store
  String get singleName => toString().split('.').last;

  /// Check if this map type allows bulk download operations
  bool get allowsBulkDownload {
    switch (this) {
      case MapType.openStreetMap:
        return false; // https://operations.osmfoundation.org/policies/tiles/
      case MapType.satellite:
        return true;
      case MapType.terrain:
        return true;
      case MapType.opentopography:
        return true;
    }
  }

  /// Get the UI display name for this map type (localized if available)
  String getUiName([S? localizations]) {
    if (localizations == null) return name;

    return localizations.mapTypeName(toString().split('.').last);
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
      case MapType.opentopography:
        return 'https://api.opentopography.org/api/v3/dem?dem_type=EU_DTM&locations={x},{y}&key=729ba1be05d312e3ce7da6cb9fe311e2';
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
      case MapType.opentopography:
        return '© OpenTopography';
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
      case MapType.opentopography:
        return 'https://www.opentopography.org/';
    }
  }

  /// Get the icon for a given MapType
  IconData get icon {
    switch (this) {
      case MapType.openStreetMap:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.opentopography:
        return Icons.terrain; // TODO: You may choose a more appropriate icon
    }
  }

  /// Convert a string to a MapType enum value. Defaults to openStreetMap if unknown.
  static MapType fromString(String mapTypeString) {
    switch (mapTypeString) {
      case 'satellite':
        return MapType.satellite;
      case 'terrain':
        return MapType.terrain;
      case 'opentopography':
        return MapType.opentopography;
      case 'openStreetMap':
      default:
        return MapType.openStreetMap;
    }
  }
}

/// Get the icon for a given MapType
IconData getMapTypeIcon(MapType mapType) {
  switch (mapType) {
    case MapType.openStreetMap:
      return Icons.map;
    case MapType.satellite:
      return Icons.satellite_alt;
    case MapType.terrain:
      return Icons.terrain;
    case MapType.opentopography:
      return Icons.terrain; // TODO: You may choose a more appropriate icon
  }
}
