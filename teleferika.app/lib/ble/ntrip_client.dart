import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:teleferika/core/logger.dart';

/// NTRIP connection state
enum NTRIPConnectionState { disconnected, connecting, connected, error }

/// NTRIP client for connecting to NTRIP casters and receiving RTCM correction data.
///
/// Implements the NTRIP protocol (Networked Transport of RTCM via Internet Protocol)
/// to connect to NTRIP casters like RTK2go and receive RTCM correction streams.
class NTRIPClient {
  static final Logger _logger = Logger('NTRIPClient');

  Socket? _socket;
  NTRIPConnectionState _connectionState = NTRIPConnectionState.disconnected;
  String? _errorMessage;

  final StreamController<NTRIPConnectionState> _connectionStateController =
      StreamController<NTRIPConnectionState>.broadcast();
  Stream<NTRIPConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  final StreamController<List<int>> _rtcmDataController =
      StreamController<List<int>>.broadcast();
  Stream<List<int>> get rtcmData => _rtcmDataController.stream;

  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  Stream<String> get errors => _errorController.stream;

  NTRIPConnectionState get connectionState => _connectionState;
  String? get errorMessage => _errorMessage;

  /// Connects to an NTRIP caster and requests a mount point stream.
  ///
  /// [host] - NTRIP caster hostname or IP address (e.g., "rtk2go.com" or "3.143.243.81")
  /// [port] - NTRIP caster port (default: 2101, SSL: 2102)
  /// [mountPoint] - Mount point identifier (e.g., "AUTO" or specific base station)
  /// [username] - Username (email address for RTK2go)
  /// [password] - Password (typically "none" for RTK2go)
  /// [useSsl] - Whether to use SSL/TLS connection
  /// [userAgent] - User agent string (optional, defaults to "NTRIP Teleferika/1.0")
  Future<void> connect({
    required String host,
    required int port,
    required String mountPoint,
    required String username,
    required String password,
    bool useSsl = false,
    String? userAgent,
  }) async {
    if (_connectionState == NTRIPConnectionState.connected ||
        _connectionState == NTRIPConnectionState.connecting) {
      await disconnect();
    }

    _updateConnectionState(NTRIPConnectionState.connecting);
    _errorMessage = null;

    try {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        _logger.info(
          'NTRIP: Connecting to $host:$port, mount point: $mountPoint',
        );
      }

      // Create socket connection
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );

      // Build NTRIP request
      final authString = base64Encode(utf8.encode('$username:$password'));
      final ua = userAgent ?? 'NTRIP Teleferika/1.0';
      final request =
          'GET /$mountPoint HTTP/1.0\r\n'
          'User-Agent: $ua\r\n'
          'Authorization: Basic $authString\r\n'
          '\r\n';

      if (const bool.fromEnvironment('dart.vm.product') == false) {
        _logger.fine('NTRIP: Sending request:\n$request');
      }

      // Send request
      _socket!.add(utf8.encode(request));
      await _socket!.flush();

      // Wait for response
      final responseBuffer = <int>[];
      bool responseComplete = false;
      final responseTimeout = const Duration(seconds: 5);

      _socket!.listen(
        (data) {
          responseBuffer.addAll(data);

          // Check if we have received HTTP response headers
          final responseText = utf8.decode(responseBuffer);
          if (responseText.contains('\r\n\r\n') ||
              responseText.contains('\n\n')) {
            responseComplete = true;

            // Parse HTTP response
            final lines = responseText.split('\n');
            if (lines.isNotEmpty) {
              final statusLine = lines[0].trim();
              if (statusLine.startsWith('HTTP/')) {
                final statusCode = _parseStatusCode(statusLine);

                if (statusCode == 200) {
                  // Success - RTCM stream follows
                  _updateConnectionState(NTRIPConnectionState.connected);

                  // Find where headers end and RTCM data begins
                  final headerEnd = responseText.indexOf('\r\n\r\n');
                  if (headerEnd == -1) {
                    final altHeaderEnd = responseText.indexOf('\n\n');
                    if (altHeaderEnd != -1) {
                      // Start streaming RTCM data
                      _startRtcmStream(responseBuffer, altHeaderEnd + 2);
                    } else {
                      // No header separator found, assume all data is RTCM
                      _startRtcmStream(responseBuffer, 0);
                    }
                  } else {
                    // Start streaming RTCM data
                    _startRtcmStream(responseBuffer, headerEnd + 4);
                  }
                } else {
                  // Error response
                  final errorMsg = _parseErrorResponse(responseText);
                  _errorMessage = 'NTRIP error $statusCode: $errorMsg';
                  _updateConnectionState(NTRIPConnectionState.error);
                  _errorController.add(_errorMessage!);
                  _socket?.close();
                }
              }
            }
          }
        },
        onError: (error) {
          _errorMessage = 'NTRIP connection error: $error';
          _updateConnectionState(NTRIPConnectionState.error);
          _errorController.add(_errorMessage!);
          _socket?.close();
        },
        onDone: () {
          if (_connectionState == NTRIPConnectionState.connected) {
            if (const bool.fromEnvironment('dart.vm.product') == false) {
              _logger.warning('NTRIP: Connection closed by server');
            }
          }
          _updateConnectionState(NTRIPConnectionState.disconnected);
          _socket = null;
        },
        cancelOnError: false,
      );

      // Timeout if no response received
      Timer(responseTimeout, () {
        if (!responseComplete &&
            _connectionState == NTRIPConnectionState.connecting) {
          _errorMessage = 'NTRIP connection timeout';
          _updateConnectionState(NTRIPConnectionState.error);
          _errorController.add(_errorMessage!);
          _socket?.close();
        }
      });
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to connect to NTRIP caster: $e';
      _updateConnectionState(NTRIPConnectionState.error);
      _errorController.add(_errorMessage!);
      logger.severe('NTRIP: Connection failed', e, stackTrace);
      _socket?.close();
      _socket = null;
    }
  }

  /// Starts streaming RTCM data after successful connection.
  void _startRtcmStream(List<int> initialData, int startIndex) {
    // Send any initial RTCM data that came with the response
    if (initialData.length > startIndex) {
      final rtcmData = initialData.sublist(startIndex);
      if (rtcmData.isNotEmpty) {
        _rtcmDataController.add(rtcmData);
      }
    }

    // Continue listening for RTCM data
    _socket!.listen(
      (data) {
        if (data.isNotEmpty) {
          _rtcmDataController.add(data);
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            _logger.fine('NTRIP: Received ${data.length} bytes of RTCM data');
          }
        }
      },
      onError: (error) {
        _errorMessage = 'NTRIP stream error: $error';
        _updateConnectionState(NTRIPConnectionState.error);
        _errorController.add(_errorMessage!);
        _socket?.close();
      },
      onDone: () {
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          _logger.info('NTRIP: RTCM stream ended');
        }
        _updateConnectionState(NTRIPConnectionState.disconnected);
        _socket = null;
      },
      cancelOnError: false,
    );
  }

  /// Parses HTTP status code from status line.
  int _parseStatusCode(String statusLine) {
    try {
      final parts = statusLine.split(' ');
      if (parts.length >= 2) {
        return int.parse(parts[1]);
      }
    } catch (e) {
      // Ignore parse errors
    }
    return 0;
  }

  /// Parses error message from HTTP response.
  String _parseErrorResponse(String response) {
    try {
      final lines = response.split('\n');
      for (final line in lines) {
        if (line.toLowerCase().contains('error') ||
            line.toLowerCase().contains('unauthorized') ||
            line.toLowerCase().contains('forbidden')) {
          return line.trim();
        }
      }
      // Return first non-empty line after status line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty && !line.startsWith('HTTP/')) {
          return line;
        }
      }
    } catch (e) {
      // Ignore parse errors
    }
    return 'Unknown error';
  }

  /// Updates connection state and notifies listeners.
  void _updateConnectionState(NTRIPConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        _logger.info('NTRIP: Connection state changed to $newState');
      }
    }
  }

  /// Disconnects from the NTRIP caster.
  Future<void> disconnect() async {
    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (e) {
        // Ignore errors during disconnect
      }
      _socket = null;
    }
    _updateConnectionState(NTRIPConnectionState.disconnected);
    _errorMessage = null;
  }

  /// Requests the source table (list of available mount points) from the NTRIP caster.
  ///
  /// Returns a list of mount point identifiers.
  Future<List<String>> requestSourceTable({
    required String host,
    required int port,
    String? username,
    String? password,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );

      // Build request for source table
      var request =
          'GET / HTTP/1.0\r\n'
          'User-Agent: NTRIP Teleferika/1.0\r\n';

      if (username != null && password != null) {
        final authString = base64Encode(utf8.encode('$username:$password'));
        request += 'Authorization: Basic $authString\r\n';
      }

      request += '\r\n';

      socket.add(utf8.encode(request));
      await socket.flush();

      // Read response
      final responseBuffer = <int>[];
      await for (final data in socket) {
        responseBuffer.addAll(data);
      }

      final responseText = utf8.decode(responseBuffer);
      return _parseSourceTable(responseText);
    } catch (e, stackTrace) {
      logger.severe('NTRIP: Failed to request source table', e, stackTrace);
      return [];
    } finally {
      socket?.close();
    }
  }

  /// Parses NTRIP source table (STR format) and extracts mount point identifiers.
  List<String> _parseSourceTable(String sourceTable) {
    final mountPoints = <String>[];

    try {
      final lines = sourceTable.split('\n');
      for (final line in lines) {
        // STR format: STR;MountPoint;Identifier;Format;FormatDetails;Carrier;NavSystem;Network;Country;Latitude;Longitude;NMEA;Solution;Generator;Compr-Encryption;Authentication;Fee;Bitrate;Misc
        if (line.startsWith('STR;')) {
          final fields = line.split(';');
          if (fields.length > 1) {
            final mountPoint = fields[1].trim();
            if (mountPoint.isNotEmpty) {
              mountPoints.add(mountPoint);
            }
          }
        }
      }
    } catch (e) {
      logger.warning('NTRIP: Error parsing source table: $e');
    }

    return mountPoints;
  }

  /// Disposes resources.
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _rtcmDataController.close();
    _errorController.close();
  }
}
