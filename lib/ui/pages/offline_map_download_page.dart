import 'package:flutter/material.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class OfflineMapDownloadPage extends StatefulWidget {
  const OfflineMapDownloadPage({Key? key}) : super(key: key);

  @override
  State<OfflineMapDownloadPage> createState() => _OfflineMapDownloadPageState();
}

class _OfflineMapDownloadPageState extends State<OfflineMapDownloadPage> {
  MapType? _selectedMapType;

  @override
  void initState() {
    super.initState();
    _selectedMapType = null; // Start with no map type selected
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
                });
              },
            ),
            const SizedBox(height: 24),
            if (_selectedMapType == null) ...[
              Container(
                height: 200,
                color: Colors.grey,
                child: const Center(
                  child: Text(
                    'Map preview will appear here...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Select Area to Download:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                color: Colors.grey,
                child: const Center(
                  child: Text(
                    'Area selector coming soon...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                onPressed: () {
                  // TODO: Implement download logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Download not implemented yet.'),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
