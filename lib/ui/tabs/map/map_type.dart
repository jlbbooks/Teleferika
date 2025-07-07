import 'package:flutter/material.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class MapType {
  final String id;
  final String name;
  final String cacheStoreName;
  final bool allowsBulkDownload;
  final String tileLayerUrl;
  final String tileLayerAttribution;
  final String attributionUrl;
  final IconData icon;

  const MapType({
    required this.id,
    required this.name,
    required this.cacheStoreName,
    required this.allowsBulkDownload,
    required this.tileLayerUrl,
    required this.tileLayerAttribution,
    required this.attributionUrl,
    required this.icon,
  });

  String getUiName([S? localizations]) {
    if (localizations == null) return name;
    return localizations.mapTypeName(id);
  }

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

  static const MapType satellite = MapType(
    id: 'satellite',
    name: 'Satellite',
    cacheStoreName: 'mapStore_satellite',
    allowsBulkDownload: true,
    tileLayerUrl:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    tileLayerAttribution:
        '© Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
    attributionUrl: 'https://www.esri.com/en-us/home',
    icon: Icons.satellite_alt,
  );

  static const MapType terrain = MapType(
    id: 'terrain',
    name: 'Terrain',
    cacheStoreName: 'mapStore_terrain',
    allowsBulkDownload: true,
    tileLayerUrl:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    tileLayerAttribution:
        '© Esri — Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012',
    attributionUrl: 'https://www.esri.com/en-us/home',
    icon: Icons.terrain,
  );

  static const List<MapType> all = [openStreetMap, satellite, terrain];

  static MapType of(String id) {
    return all.firstWhere((type) => type.id == id, orElse: () => openStreetMap);
  }
}
