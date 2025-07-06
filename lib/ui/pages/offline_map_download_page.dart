import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';
import 'package:teleferika/ui/tabs/map/services/map_download_service.dart';
import 'package:teleferika/ui/widgets/map_area_selector.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class OfflineMapDownloadPage extends StatefulWidget {
  const OfflineMapDownloadPage({super.key});

  @override
  State<OfflineMapDownloadPage> createState() => _OfflineMapDownloadPageState();
}

class _OfflineMapDownloadPageState extends State<OfflineMapDownloadPage>
    with StatusMixin {
  MapType? _selectedMapType;
  LatLngBounds? _selectedArea;

  // Download state
  bool _isDownloading = false;
  int _downloadedTiles = 0;
  int _totalTiles = 0;
  double _downloadProgress = 0.0;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _selectedMapType = null; // Start with no map type selected
  }

  void _onAreaSelected(LatLngBounds bounds) {
    setState(() {
      _selectedArea = bounds;
      _downloadError = null; // Clear any previous errors
    });
  }

  void _onClearSelection() {
    setState(() {
      _selectedArea = null;
      _downloadError = null;
    });
  }

  Future<void> _startDownload() async {
    if (_selectedArea == null || _selectedMapType == null) return;

    setState(() {
      _isDownloading = true;
      _downloadedTiles = 0;
      _totalTiles = 0;
      _downloadProgress = 0.0;
      _downloadError = null;
    });

    try {
      await MapDownloadService.downloadMapArea(
        bounds: _selectedArea!,
        mapType: _selectedMapType!,
        minZoom: 9, // Start with zoom level 10
        maxZoom: 16, // End with zoom level 16
        onProgress: (downloaded, total, percentage) {
          if (mounted) {
            setState(() {
              _downloadedTiles = downloaded;
              _totalTiles = total;
              _downloadProgress = percentage;
            });
          }
        },
        onComplete: (success, error) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              if (!success) {
                _downloadError = error;
              }
            });

            // Show completion message using StatusIndicator
            final s = S.of(context);
            if (success) {
              showSuccessStatus(
                s?.offline_maps_download_completed ??
                    'Download completed successfully!',
              );
            } else {
              showErrorStatus(
                s?.offline_maps_download_failed(error ?? 'Unknown error') ??
                    'Download failed: ${error ?? 'Unknown error'}',
              );
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadError = e.toString();
        });

        final s = S.of(context);
        showErrorStatus(
          s?.offline_maps_download_failed(e.toString()) ??
              'Download failed: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.offline_maps_download_title ?? 'Download Offline Maps'),
      ),
      body: Stack(
        children: [
          Padding(
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
                    child: Stack(
                      children: [
                        MapAreaSelector(
                          mapType: _selectedMapType!,
                          onAreaSelected: _onAreaSelected,
                          onClearSelection: _onClearSelection,
                        ),
                        if (!_selectedMapType!.allowsBulkDownload)
                          Positioned.fill(
                            child: Container(
                              color: Colors.red.withValues(alpha: 0.1),
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        s?.offline_maps_bulk_download_not_allowed ??
                                            'Bulk Download Not Allowed',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        s?.offline_maps_bulk_download_restriction_message ??
                                            'This map type does not allow bulk download operations due to licensing restrictions.',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
                                  s?.offline_maps_selected_area ??
                                      'Selected Area:',
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
                                if (_isDownloading) ...[
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: _downloadProgress / 100,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_downloadedTiles}/${_totalTiles} tiles (${_downloadProgress.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                                if (_downloadError != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _downloadError!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: Text(
                            _isDownloading
                                ? (s?.offline_maps_downloading ??
                                      'Downloading...')
                                : (s?.offline_maps_download_button ??
                                      'Download'),
                          ),
                          onPressed:
                              (_isDownloading ||
                                  !_selectedMapType!.allowsBulkDownload)
                              ? null
                              : _startDownload,
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Status indicator positioned at the top right
          Positioned(
            top: 24,
            right: 24,
            child: StatusIndicator(
              status: currentStatus,
              onDismiss: hideStatus,
            ),
          ),
        ],
      ),
    );
  }
}
