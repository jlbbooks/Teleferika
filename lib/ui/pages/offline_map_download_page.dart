import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';
import 'package:teleferika/ui/widgets/map_area_selector.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class OfflineMapDownloadPage extends StatefulWidget {
  const OfflineMapDownloadPage({super.key});

  @override
  State<OfflineMapDownloadPage> createState() => _OfflineMapDownloadPageState();
}

class _OfflineMapDownloadPageState extends State<OfflineMapDownloadPage> {
  MapType? _selectedMapType;
  LatLngBounds? _selectedArea;

  @override
  void initState() {
    super.initState();
    _selectedMapType = null; // Start with no map type selected
  }

  void _onAreaSelected(LatLngBounds bounds) {
    setState(() {
      _selectedArea = bounds;
    });
  }

  void _onClearSelection() {
    setState(() {
      _selectedArea = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.offline_maps_download_title ?? 'Download Offline Maps'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<MapType?>(
              value: _selectedMapType,
              items: [
                DropdownMenuItem<MapType?>(
                  value: null,
                  child: Text(
                    s?.offline_maps_select_map_type ?? 'Select Map Type',
                  ),
                ),
                ...MapType.values.map((type) {
                  return DropdownMenuItem<MapType?>(
                    value: type,
                    child: Text(type.getUiName(null)),
                  );
                }),
              ],
              onChanged: (type) {
                setState(() {
                  _selectedMapType = type;
                  // Clear area selection when map type changes
                  _selectedArea = null;
                });
              },
            ),
            const SizedBox(height: 24),
            if (_selectedMapType == null) ...[
              Container(
                height:
                    MediaQuery.of(context).size.height *
                    0.4, // 40% of screen height
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    s?.offline_maps_select_map_type_to_start ??
                        'Select a map type to start',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              Text(
                s?.offline_maps_select_area_to_download ??
                    'Select Area to Download:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.5, // 50% of screen height for the map
                child: MapAreaSelector(
                  mapType: _selectedMapType!,
                  onAreaSelected: _onAreaSelected,
                  onClearSelection: _onClearSelection,
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedArea != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s?.offline_maps_selected_area ?? 'Selected Area:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s?.offline_maps_coordinates_sw(
                                    _selectedArea!.southWest.latitude
                                        .toStringAsFixed(4),
                                    _selectedArea!.southWest.longitude
                                        .toStringAsFixed(4),
                                  ) ??
                                  'SW: ${_selectedArea!.southWest.latitude.toStringAsFixed(4)}, ${_selectedArea!.southWest.longitude.toStringAsFixed(4)}',
                            ),
                            Text(
                              s?.offline_maps_coordinates_ne(
                                    _selectedArea!.northEast.latitude
                                        .toStringAsFixed(4),
                                    _selectedArea!.northEast.longitude
                                        .toStringAsFixed(4),
                                  ) ??
                                  'NE: ${_selectedArea!.northEast.latitude.toStringAsFixed(4)}, ${_selectedArea!.northEast.longitude.toStringAsFixed(4)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: Text(
                        s?.offline_maps_download_button ?? 'Download',
                      ),
                      onPressed: () {
                        // TODO: Implement download logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              s?.offline_maps_download_not_implemented ??
                                  'Download not implemented yet.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
