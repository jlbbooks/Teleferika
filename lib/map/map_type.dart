import 'package:flutter/material.dart';

class MapType {
  final String id;
  final String name;
  final bool allowsBulkDownload;
  final String tileLayerUrl;
  final String tileLayerAttribution;
  final String attributionUrl;
  final IconData icon;
  final bool supportsRetina;
  final String? apiKey;
  final String? apiKeyParameterName;
  final String? cacheStoreName;
  final int minZoom;
  final int maxZoom;

  const MapType({
    required this.id,
    required this.name,
    required this.allowsBulkDownload,
    required this.tileLayerUrl,
    required this.tileLayerAttribution,
    required this.attributionUrl,
    required this.icon,
    this.supportsRetina = false,
    this.apiKey,
    this.apiKeyParameterName,
    this.cacheStoreName,
    required this.minZoom,
    required this.maxZoom,
  });

  // All map types defined directly in the list
  static const List<MapType> all = [
    MapType(
      id: 'openStreetMap',
      name: 'Open Street Map',
      allowsBulkDownload: false,
      tileLayerUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      tileLayerAttribution: '© OpenStreetMap contributors',
      attributionUrl: 'https://openstreetmap.org/copyright',
      icon: Icons.map,
      minZoom: 0,
      maxZoom: 19,
    ),
    MapType(
      id: 'satellite',
      name: 'Esri Satellite',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      tileLayerAttribution:
          '© Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
      attributionUrl: 'https://www.esri.com/en-us/home',
      icon: Icons.satellite_alt,
      minZoom: 0,
      maxZoom: 23,
    ),
    MapType(
      id: 'terrain',
      name: 'Esri World Topo',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
      tileLayerAttribution:
          '© Esri — Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012',
      attributionUrl: 'https://www.esri.com/en-us/home',
      icon: Icons.layers,
      minZoom: 0,
      maxZoom: 23,
    ),
    MapType(
      id: 'openTopoMap',
      name: 'Open Topo Map',
      allowsBulkDownload: true,
      tileLayerUrl: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      tileLayerAttribution: '© OpenTopoMap contributors',
      attributionUrl: 'https://opentopomap.org/',
      icon: Icons.terrain_outlined,
      minZoom: 0,
      maxZoom: 17,
    ),
    MapType(
      id: 'cartoPositron',
      name: 'CartoDB Positron',
      allowsBulkDownload: true,
      tileLayerUrl:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      tileLayerAttribution: '© OpenStreetMap contributors, © CartoDB',
      attributionUrl: 'https://carto.com/',
      icon: Icons.map_outlined,
      supportsRetina: true,
      minZoom: 0,
      maxZoom: 20,
    ),
    MapType(
      id: 'thunderforestOutdoors',
      name: 'Thunderforest Outdoors',
      allowsBulkDownload: false,
      tileLayerUrl:
          'https://{s}.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png',
      tileLayerAttribution:
          'Maps: © Thunderforest | Data: © OpenStreetMap contributors',
      attributionUrl: 'https://www.thunderforest.com/',
      icon: Icons.hiking,
      apiKey: null,
      apiKeyParameterName: 'apikey',
      minZoom: 0,
      maxZoom: 22,
    ),
    MapType(
      id: 'thunderforestLandscape',
      name: 'Thunderforest Landscape',
      allowsBulkDownload: false,
      tileLayerUrl:
          'https://{s}.tile.thunderforest.com/landscape/{z}/{x}/{y}.png',
      tileLayerAttribution:
          'Maps: © Thunderforest | Data: © OpenStreetMap contributors',
      attributionUrl: 'https://www.thunderforest.com/',
      icon: Icons.landscape,
      apiKey: null,
      apiKeyParameterName: 'apikey',
      minZoom: 0,
      maxZoom: 22,
    ),
  ];

  static MapType of(String id) {
    final base = all.firstWhere(
      (type) => type.id == id,
      orElse: () => all.first,
    );
    return MapType(
      id: base.id,
      name: base.name,
      allowsBulkDownload: base.allowsBulkDownload,
      tileLayerUrl: base.tileLayerUrl,
      tileLayerAttribution: base.tileLayerAttribution,
      attributionUrl: base.attributionUrl,
      icon: base.icon,
      supportsRetina: base.supportsRetina,
      apiKey: base.apiKey,
      apiKeyParameterName: base.apiKeyParameterName,
      cacheStoreName: 'mapStore_${base.id}',
      minZoom: base.minZoom,
      maxZoom: base.maxZoom,
    );
  }
}
