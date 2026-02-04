import 'package:flutter/material.dart';
import 'package:teleferika/ble/ntrip_client.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class NtripConfigurationWidget extends StatelessWidget {
  final NTRIPConnectionState connectionState;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController mountPointController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool useSsl;
  final bool isForwardingRtcm;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final ValueChanged<bool> onSslChanged;

  const NtripConfigurationWidget({
    super.key,
    required this.connectionState,
    required this.hostController,
    required this.portController,
    required this.mountPointController,
    required this.usernameController,
    required this.passwordController,
    required this.useSsl,
    required this.isForwardingRtcm,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSslChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isConnected = connectionState == NTRIPConnectionState.connected;
    final isConnecting = connectionState == NTRIPConnectionState.connecting;
    final isError = connectionState == NTRIPConnectionState.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ExpansionTile(
        leading: Icon(
          isConnected ? Icons.satellite_alt : Icons.satellite,
          color: isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(s?.bleNtripTitle ?? 'NTRIP Corrections'),
        subtitle: Text(
          isConnected
              ? (s?.bleNtripConnected ?? 'Connected')
              : isConnecting
              ? (s?.bleNtripConnecting ?? 'Connecting...')
              : isError
              ? (s?.bleNtripError ?? 'Error')
              : (s?.bleNtripDisconnected ?? 'Disconnected'),
          style: TextStyle(
            color: isConnected
                ? Colors.green
                : isError
                ? Colors.red
                : Colors.grey,
          ),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: hostController,
                  decoration: InputDecoration(
                    labelText: s?.bleNtripHost ?? 'NTRIP Caster Host',
                    hintText: 'rtk2go.com',
                    border: const OutlineInputBorder(),
                  ),
                  enabled: !isConnected && !isConnecting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  decoration: InputDecoration(
                    labelText: s?.bleNtripPort ?? 'Port',
                    hintText: '2101',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isConnected && !isConnecting,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(s?.bleNtripUseSsl ?? 'Use SSL/TLS'),
                  value: useSsl,
                  onChanged: isConnected || isConnecting
                      ? null
                      : (value) => onSslChanged(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mountPointController,
                  decoration: InputDecoration(
                    labelText: s?.bleNtripMountPoint ?? 'Mount Point',
                    hintText: 'AUTO',
                    border: const OutlineInputBorder(),
                  ),
                  enabled: !isConnected && !isConnecting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: s?.bleNtripUsername ?? 'Username (Email)',
                    hintText: 'your-email@example.com',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isConnected && !isConnecting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: s?.bleNtripPassword ?? 'Password',
                    hintText: 'none',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: !isConnected && !isConnecting,
                ),
                const SizedBox(height: 16),
                if (isConnected)
                  ElevatedButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.close),
                    label: Text(s?.bleNtripDisconnect ?? 'Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: isConnecting ? null : onConnect,
                    icon: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.link),
                    label: Text(
                      isConnecting
                          ? (s?.bleNtripConnecting ?? 'Connecting...')
                          : (s?.bleNtripConnect ?? 'Connect to NTRIP'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (isForwardingRtcm) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        s?.bleNtripForwarding ?? 'Forwarding RTCM corrections',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
