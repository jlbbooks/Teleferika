import 'package:flutter/material.dart';

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

  const MapType({
    required this.id,
    required this.name,
    required this.cacheStoreName,
    required this.allowsBulkDownload,
    required this.tileLayerUrl,
    required this.tileLayerAttribution,
    required this.attributionUrl,
    required this.icon,
    this.supportsRetina = false,
  });

  // All map types defined directly in the list
  static const List<MapType> all = [
    MapType(
      id: 'openStreetMap',
      name: 'Open Street Map',
      cacheStoreName: 'mapStore_openStreetMap',
      allowsBulkDownload: false,
      tileLayerUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      tileLayerAttribution: '© OpenStreetMap contributors',
      attributionUrl: 'https://openstreetmap.org/copyright',
      icon: Icons.map,
    ),
    MapType(
      id: 'satellite',
      name: 'Esri Satellite',
      cacheStoreName: 'mapStore_satellite',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      tileLayerAttribution:
          '© Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
      attributionUrl: 'https://www.esri.com/en-us/home',
      icon: Icons.satellite_alt,
    ),
    MapType(
      id: 'terrain',
      name: 'Esri World Topo',
      cacheStoreName: 'mapStore_terrain',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
      tileLayerAttribution:
          '© Esri — Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012',
      attributionUrl: 'https://www.esri.com/en-us/home',
      icon: Icons.layers,
    ),
    MapType(
      id: 'openTopoMap',
      name: 'Open Topo Map',
      cacheStoreName: 'mapStore_openTopoMap',
      allowsBulkDownload: true,
      tileLayerUrl: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      tileLayerAttribution: '© OpenTopoMap contributors',
      attributionUrl: 'https://opentopomap.org/',
      icon: Icons.terrain_outlined,
    ),
    MapType(
      id: 'thunderforestOutdoors',
      name: 'Thunderforest Outdoors',
      cacheStoreName: 'mapStore_thunderforestOutdoors',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://{s}.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png',
      tileLayerAttribution: '© OpenStreetMap contributors, © Thunderforest',
      attributionUrl: 'https://www.thunderforest.com/',
      icon: Icons.hiking,
    ),
    MapType(
      id: 'cartoPositron',
      name: 'CartoDB Positron',
      cacheStoreName: 'mapStore_cartoPositron',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      tileLayerAttribution: '© OpenStreetMap contributors, © CartoDB',
      attributionUrl: 'https://carto.com/',
      icon: Icons.map_outlined,
      supportsRetina: true,
    ),
    MapType(
      id: 'stamenTerrain',
      name: 'Stamen Terrain',
      cacheStoreName: 'mapStore_stamenTerrain',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}{r}.png',
      tileLayerAttribution: '© Stamen Design, © OpenStreetMap contributors',
      attributionUrl: 'https://stamen.com/',
      icon: Icons.landscape,
      supportsRetina: true,
    ),
    MapType(
      id: 'openMapTilesTerrain',
      name: 'OpenMapTiles Terrain',
      cacheStoreName: 'mapStore_openMapTilesTerrain',
      allowsBulkDownload: true,
      tileLayerUrl: 'https://tiles.maptiler.com/terrain/{z}/{x}/{y}.png',
      tileLayerAttribution: '© OpenMapTiles © OpenStreetMap contributors',
      attributionUrl: 'https://openmaptiles.org/',
      icon: Icons.landscape_outlined,
    ),
  ];

  static MapType of(String id) {
    return all.firstWhere((type) => type.id == id, orElse: () => all.first);
  }
}
