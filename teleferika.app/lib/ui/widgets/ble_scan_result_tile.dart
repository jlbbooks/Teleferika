import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class BleScanResultTile extends StatelessWidget {
  final ScanResult result;
  final bool isConnected;
  final bool wasPreviouslyConnected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback? onTap;

  const BleScanResultTile({
    super.key,
    required this.result,
    required this.isConnected,
    this.wasPreviouslyConnected = false,
    required this.onConnect,
    required this.onDisconnect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final device = result.device;

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isConnected ? Colors.green : Colors.blue,
            ),
            title: Text(
              device.platformName.isEmpty
                  ? (s?.bleUnknownDevice ?? 'Unknown Device')
                  : device.platformName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.remoteId}'),
            Text('RSSI: ${result.rssi} dBm'),
            if (result.advertisementData.advName.isNotEmpty)
              Text('Name: ${result.advertisementData.advName}'),
            if (result.advertisementData.serviceUuids.isNotEmpty)
              Text(
                'Services: ${result.advertisementData.serviceUuids.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDisconnect,
                tooltip: s?.bleButtonDisconnect ?? 'Disconnect',
              )
            : IconButton(
                icon: const Icon(Icons.link),
                onPressed: onConnect,
                tooltip: s?.bleButtonConnect ?? 'Connect',
              ),
            onTap: onTap,
          ),
        ),
        if (wasPreviouslyConnected && !isConnected)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.only(top: 8.0, right: 16.0),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
