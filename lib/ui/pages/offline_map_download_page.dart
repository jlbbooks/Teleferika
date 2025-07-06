import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';
import 'package:teleferika/ui/widgets/map_area_selector.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class OfflineMapDownloadPage extends StatefulWidget {
  const OfflineMapDownloadPage({Key? key}) : super(key: key);

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
      appBar: AppBar(title: const Text('Download Offline Maps')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<MapType?>(
              value: _selectedMapType,
              items: [
                const DropdownMenuItem<MapType?>(
                  value: null,
                  child: Text('Select Map Type'),
                ),
                ...MapType.values.map((type) {
                  return DropdownMenuItem<MapType?>(
                    value: type,
                    child: Text(type.getUiName(null)),
                  );
                }).toList(),
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
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Select a map type to start',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Select Area to Download:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              MapAreaSelector(
                mapType: _selectedMapType!,
                onAreaSelected: _onAreaSelected,
                onClearSelection: _onClearSelection,
              ),
              const SizedBox(height: 24),
              if (_selectedArea != null) ...[
                Container(
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
                      const Text(
                        'Selected Area:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SW: ${_selectedArea!.southWest.latitude.toStringAsFixed(4)}, ${_selectedArea!.southWest.longitude.toStringAsFixed(4)}',
                      ),
                      Text(
                        'NE: ${_selectedArea!.northEast.latitude.toStringAsFixed(4)}, ${_selectedArea!.northEast.longitude.toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                onPressed: _selectedArea != null
                    ? () {
                        // TODO: Implement download logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download not implemented yet.'),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
