import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ble/nmea_parser.dart';
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
  SecureSocket? _secureSocket;
  NTRIPConnectionState _connectionState = NTRIPConnectionState.disconnected;
  String? _errorMessage;
  Timer? _keepAliveTimer;
  DateTime? _lastDataReceivedTime;
  int _rtcmMessageCount = 0;
  int _ggaSendCount = 0;
  bool _hasValidatedFirstRtcm = false;

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
      // Connection logging removed - state changes are logged instead

      // Create socket connection (plain or secure)
      if (useSsl) {
        // Use SecureSocket for SSL/TLS connections
        _secureSocket = await SecureSocket.connect(
          host,
          port,
          timeout: const Duration(seconds: 10),
        );
        _socket = _secureSocket;
      } else {
        // Use plain Socket for non-SSL connections
        _socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 10),
        );
      }

      // Build NTRIP request
      final authString = base64Encode(utf8.encode('$username:$password'));
      final ua = userAgent ?? 'NTRIP Teleferika/1.0';
      final request =
          'GET /$mountPoint HTTP/1.0\r\n'
          'User-Agent: $ua\r\n'
          'Authorization: Basic $authString\r\n'
          '\r\n';

      // Request logging removed - not needed for normal operation

      // Send request
      _socket!.add(utf8.encode(request));
      await _socket!.flush();

      // Wait for response using Completer
      final responseBuffer = <int>[];
      final responseCompleter = Completer<void>();
      bool responseComplete = false;
      bool isRtcmStreamMode = false;
      Timer? timeoutTimer;

      // Set up socket listener that handles both HTTP response and RTCM stream
      _rtcmStreamSubscription = _socket!.listen(
        (data) {
          if (isRtcmStreamMode) {
            // RTCM stream mode - forward data directly
            if (data.isNotEmpty) {
              _lastDataReceivedTime = DateTime.now();
              _rtcmMessageCount++;

              // Validate RTCM format (should start with 0xD3)
              final isValidRtcm = data[0] == 0xD3;

              // Critical: Validate first RTCM message - disconnect if invalid
              if (!_hasValidatedFirstRtcm) {
                _hasValidatedFirstRtcm = true;
                if (!isValidRtcm) {
                  // Check if RTCM sync byte appears anywhere in the data
                  final rtcmSyncIndex = data.indexOf(0xD3);
                  if (rtcmSyncIndex < 0) {
                    // No RTCM sync byte found - disconnect immediately
                    final firstFewBytes = data.sublist(
                      0,
                      data.length > 20 ? 20 : data.length,
                    );
                    final hexPattern = firstFewBytes
                        .map((b) => b.toRadixString(16).padLeft(2, '0'))
                        .join(' ');

                    // Try to decode as text to see if it's an error message
                    String? textPreview;
                    try {
                      final text = utf8.decode(
                        data.sublist(0, data.length > 100 ? 100 : data.length),
                      );
                      if (text.contains(RegExp(r'[a-zA-Z]{3,}'))) {
                        textPreview = text.split('\n').first.trim();
                      }
                    } catch (e) {
                      // Not text, ignore
                    }

                    _errorMessage =
                        'Invalid RTCM format: Data does not start with RTCM sync byte (0xD3). '
                        'First byte: 0x${data[0].toRadixString(16)}. '
                        '${textPreview != null ? "Server message: $textPreview. " : ""}'
                        'This mount point may not support RTCM 3.1 format. '
                        'Try a different mount point (e.g., IMAX3 instead of IMAX2).';

                    _logger.severe('NTRIP: $_errorMessage');
                    _logger.severe('NTRIP: First bytes (hex): $hexPattern');

                    _updateConnectionState(NTRIPConnectionState.error);
                    _errorController.add(_errorMessage!);

                    // Disconnect immediately
                    _disconnectInternal();

                    if (!responseCompleter.isCompleted) {
                      responseCompleter.completeError(Exception(_errorMessage));
                    }
                    return;
                  } else {
                    // RTCM sync byte found but not at start - log warning but continue
                    _logger.warning(
                      'NTRIP: RTCM sync byte found at index $rtcmSyncIndex, not at start. '
                      'This may indicate a protocol issue.',
                    );
                  }
                }
                // Valid RTCM format - no logging needed
              }

              if (!isValidRtcm &&
                  const bool.fromEnvironment('dart.vm.product') == false) {
                // Check if RTCM message might be embedded later in the data
                final rtcmIndex = data.indexOf(0xD3);
                if (rtcmIndex > 0) {
                  _logger.warning(
                    'NTRIP: Data does not start with RTCM sync byte (0xD3). '
                    'First byte: 0x${data[0].toRadixString(16)}, '
                    'RTCM sync found at index: $rtcmIndex. '
                    'This might indicate a protocol issue or data corruption.',
                  );
                } else {
                  // Check if RTCM sync byte appears anywhere in the data (might be embedded)
                  final rtcmSyncIndex = data.indexOf(0xD3);
                  final hasRtcmSync = rtcmSyncIndex >= 0;

                  // Count how many RTCM sync bytes appear in the data
                  int rtcmSyncCount = 0;
                  for (int i = 0; i < data.length; i++) {
                    if (data[i] == 0xD3) rtcmSyncCount++;
                  }

                  // Try to decode as text to see if it's an error message
                  String? textPreview;
                  try {
                    final text = utf8.decode(
                      data.sublist(0, data.length > 100 ? 100 : data.length),
                    );
                    if (text.contains(RegExp(r'[a-zA-Z]{3,}'))) {
                      textPreview = text.split('\n').first.trim();
                    }
                  } catch (e) {
                    // Not text, ignore
                  }

                  // Log warning only once per 10 messages to reduce noise
                  if (_rtcmMessageCount % 10 == 1) {
                    final firstFewBytes = data.sublist(
                      0,
                      data.length > 10 ? 10 : data.length,
                    );
                    final hexPattern = firstFewBytes
                        .map((b) => b.toRadixString(16).padLeft(2, '0'))
                        .join(' ');

                    _logger.warning(
                      'NTRIP: Data does not start with RTCM sync byte (0xD3). '
                      'First byte: 0x${data[0].toRadixString(16)}, length: ${data.length} bytes. '
                      '${hasRtcmSync ? "Found $rtcmSyncCount RTCM sync byte(s) at index(es) starting at: $rtcmSyncIndex. " : "No RTCM sync bytes found. "}'
                      '${textPreview != null ? "Text preview: $textPreview. " : ""}'
                      'Hex: $hexPattern. '
                      'IMAX2 server may be using encoded/compressed RTCM or different protocol.',
                    );
                  }
                }
              }

              _rtcmDataController.add(data);
              _rtcmMessageCount++;
              // Logging removed - RTCM data is flowing correctly
            }
          } else {
            // HTTP response mode - accumulate and parse headers
            responseBuffer.addAll(data);

            // Check if we have received HTTP response headers
            // Also check if we've received enough data to determine response type
            String? responseText;
            bool hasHttpHeaders = false;
            bool looksLikeRtcm = false;

            try {
              responseText = utf8.decode(responseBuffer);
              hasHttpHeaders =
                  responseText.contains('\r\n\r\n') ||
                  responseText.contains('\n\n');
            } catch (e) {
              // If UTF-8 decode fails, it's likely binary RTCM data - no logging needed
            }

            // Check if data looks like RTCM (starts with 0xD3) - some servers send RTCM directly
            looksLikeRtcm =
                responseBuffer.isNotEmpty && responseBuffer[0] == 0xD3;

            // Also check if we have enough data that it's likely a response
            // (some servers send RTCM immediately without headers)
            final hasEnoughData =
                responseBuffer.length >=
                3; // RTCM messages are at least 3 bytes

            if (hasHttpHeaders || (looksLikeRtcm && hasEnoughData)) {
              if (!responseComplete) {
                responseComplete = true;
                timeoutTimer?.cancel();

                // Response logging removed - only log errors

                // Handle RTCM data sent directly (without HTTP headers)
                if (looksLikeRtcm && !hasHttpHeaders) {
                  // Validate RTCM format before accepting connection
                  final isValidRtcm = responseBuffer[0] == 0xD3;
                  if (!isValidRtcm) {
                    final rtcmSyncIndex = responseBuffer.indexOf(0xD3);
                    if (rtcmSyncIndex < 0) {
                      // No RTCM sync byte - disconnect immediately
                      final firstFewBytes = responseBuffer.sublist(
                        0,
                        responseBuffer.length > 20 ? 20 : responseBuffer.length,
                      );
                      final hexPattern = firstFewBytes
                          .map((b) => b.toRadixString(16).padLeft(2, '0'))
                          .join(' ');

                      _errorMessage =
                          'Invalid RTCM format: Direct RTCM data does not start with RTCM sync byte (0xD3). '
                          'First byte: 0x${responseBuffer[0].toRadixString(16)}. '
                          'This mount point may not support RTCM 3.1 format. '
                          'Try a different mount point (e.g., IMAX3 instead of IMAX2).';

                      _logger.severe('NTRIP: $_errorMessage');
                      _logger.severe('NTRIP: First bytes (hex): $hexPattern');

                      _updateConnectionState(NTRIPConnectionState.error);
                      _errorController.add(_errorMessage!);

                      // Disconnect immediately
                      _disconnectInternal();

                      if (!responseCompleter.isCompleted) {
                        responseCompleter.completeError(
                          Exception(_errorMessage),
                        );
                      }
                      return;
                    }
                  } else {
                    _hasValidatedFirstRtcm = true;
                  }

                  // Treat as successful connection
                  _updateConnectionState(NTRIPConnectionState.connected);
                  isRtcmStreamMode = true;
                  _lastDataReceivedTime = DateTime.now();
                  // Logging removed - connection successful
                  _rtcmMessageCount++;
                  _rtcmDataController.add(responseBuffer);
                  responseBuffer.clear();

                  if (!responseCompleter.isCompleted) {
                    responseCompleter.complete();
                  }

                  // Start monitoring for data reception
                  _startDataMonitoring();
                  return; // Exit early, we're done
                }

                // Parse HTTP response (only if we have HTTP headers)
                if (!hasHttpHeaders || responseText == null) {
                  // Should have been handled above (RTCM direct mode)
                  // If we get here, something went wrong
                  _errorMessage =
                      'NTRIP error: No HTTP headers and not RTCM data';
                  _updateConnectionState(NTRIPConnectionState.error);
                  _errorController.add(_errorMessage!);
                  _socket?.close();
                  _secureSocket?.close();

                  if (!responseCompleter.isCompleted) {
                    responseCompleter.complete();
                  }
                  return;
                }

                // We have HTTP headers, so responseText is non-null
                final responseTextNonNull = responseText;
                final lines = responseTextNonNull.split('\n');
                if (lines.isNotEmpty) {
                  final statusLine = lines[0].trim();
                  // NTRIP servers may use "HTTP/" or "ICY" (streaming protocol) in response
                  if (statusLine.startsWith('HTTP/') ||
                      statusLine.startsWith('ICY')) {
                    final statusCode = _parseStatusCode(statusLine);

                    if (const bool.fromEnvironment('dart.vm.product') ==
                        false) {
                      final protocol = statusLine.startsWith('ICY')
                          ? 'ICY'
                          : 'HTTP';
                      _logger.info(
                        'NTRIP: Status Code: $statusCode ($protocol)',
                      );
                    }

                    if (statusCode == 200) {
                      // Success - RTCM stream follows
                      _updateConnectionState(NTRIPConnectionState.connected);

                      // Find where headers end and RTCM data begins
                      final headerEnd = responseTextNonNull.indexOf('\r\n\r\n');
                      int rtcmStartIndex;
                      if (headerEnd == -1) {
                        final altHeaderEnd = responseTextNonNull.indexOf(
                          '\n\n',
                        );
                        rtcmStartIndex = altHeaderEnd != -1
                            ? altHeaderEnd + 2
                            : 0;
                      } else {
                        rtcmStartIndex = headerEnd + 4;
                      }

                      // Send any initial RTCM data that came with the response
                      if (responseBuffer.length > rtcmStartIndex) {
                        final rtcmData = responseBuffer.sublist(rtcmStartIndex);
                        if (rtcmData.isNotEmpty) {
                          // Validate initial RTCM data format
                          final isValidRtcm = rtcmData[0] == 0xD3;
                          if (!isValidRtcm) {
                            // Check if RTCM sync byte appears anywhere
                            final rtcmSyncIndex = rtcmData.indexOf(0xD3);
                            if (rtcmSyncIndex < 0) {
                              // No RTCM sync byte - disconnect immediately
                              final firstFewBytes = rtcmData.sublist(
                                0,
                                rtcmData.length > 20 ? 20 : rtcmData.length,
                              );
                              final hexPattern = firstFewBytes
                                  .map(
                                    (b) => b.toRadixString(16).padLeft(2, '0'),
                                  )
                                  .join(' ');

                              // Try to decode as text
                              String? textPreview;
                              try {
                                final text = utf8.decode(
                                  rtcmData.sublist(
                                    0,
                                    rtcmData.length > 100
                                        ? 100
                                        : rtcmData.length,
                                  ),
                                );
                                if (text.contains(RegExp(r'[a-zA-Z]{3,}'))) {
                                  textPreview = text.split('\n').first.trim();
                                }
                              } catch (e) {
                                // Not text, ignore
                              }

                              _errorMessage =
                                  'Invalid RTCM format: Initial data does not start with RTCM sync byte (0xD3). '
                                  'First byte: 0x${rtcmData[0].toRadixString(16)}. '
                                  '${textPreview != null ? "Server message: $textPreview. " : ""}'
                                  'This mount point may not support RTCM 3.1 format. '
                                  'Try a different mount point (e.g., IMAX3 instead of IMAX2).';

                              _logger.severe('NTRIP: $_errorMessage');
                              _logger.severe(
                                'NTRIP: First bytes (hex): $hexPattern',
                              );

                              _updateConnectionState(
                                NTRIPConnectionState.error,
                              );
                              _errorController.add(_errorMessage!);

                              // Disconnect immediately
                              _disconnectInternal();

                              if (!responseCompleter.isCompleted) {
                                responseCompleter.completeError(
                                  Exception(_errorMessage),
                                );
                              }
                              return;
                            }
                          } else {
                            _hasValidatedFirstRtcm = true;
                            // Valid RTCM format - no logging needed
                          }
                          // Logging removed - initial RTCM data is valid
                          _rtcmDataController.add(rtcmData);
                        }
                      }
                      // Logging removed - no initial RTCM data is normal

                      // Switch to RTCM stream mode
                      isRtcmStreamMode = true;
                      responseBuffer.clear(); // Clear buffer to free memory
                      _lastDataReceivedTime = DateTime.now();

                      // For i-Max services, some servers require an initial GGA sentence
                      // immediately after connection. We'll send it once we have position data.
                      // This is handled by the GGA sending setup in BLEService.

                      // Complete the completer to signal response received
                      if (!responseCompleter.isCompleted) {
                        responseCompleter.complete();
                      }

                      // Start monitoring for data reception
                      _startDataMonitoring();
                    } else {
                      // Error response
                      final errorMsg = _parseErrorResponse(responseTextNonNull);
                      _errorMessage = 'NTRIP error $statusCode: $errorMsg';
                      _updateConnectionState(NTRIPConnectionState.error);
                      _errorController.add(_errorMessage!);
                      _socket?.close();
                      _secureSocket?.close();

                      // Complete the completer to signal response received (with error)
                      if (!responseCompleter.isCompleted) {
                        responseCompleter.complete();
                      }
                    }
                  } else {
                    // Response doesn't start with HTTP/ - handle error case
                    // Logging removed - error message is set below
                    final errorPreview = responseTextNonNull.substring(
                      0,
                      responseTextNonNull.length > 200
                          ? 200
                          : responseTextNonNull.length,
                    );
                    _errorMessage =
                        'NTRIP error: Invalid response format. Response: $errorPreview';
                    _updateConnectionState(NTRIPConnectionState.error);
                    _errorController.add(_errorMessage!);
                    _socket?.close();
                    _secureSocket?.close();

                    if (!responseCompleter.isCompleted) {
                      responseCompleter.complete();
                    }
                  }
                } else {
                  // Empty response - error
                  _errorMessage = 'NTRIP error: Empty response from server';
                  _updateConnectionState(NTRIPConnectionState.error);
                  _errorController.add(_errorMessage!);
                  _socket?.close();
                  _secureSocket?.close();

                  if (!responseCompleter.isCompleted) {
                    responseCompleter.complete();
                  }
                }
              }
            }
          }
        },
        onError: (error) {
          timeoutTimer?.cancel();
          _errorMessage = 'NTRIP connection error: $error';
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            _logger.severe('NTRIP: Socket error: $error');
          }
          _updateConnectionState(NTRIPConnectionState.error);
          _errorController.add(_errorMessage!);
          _socket?.close();
          _secureSocket?.close();
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(error);
          }
        },
        onDone: () {
          timeoutTimer?.cancel();
          if (_connectionState == NTRIPConnectionState.connected) {
            if (const bool.fromEnvironment('dart.vm.product') == false) {
              _logger.warning('NTRIP: Connection closed by server');
              _logger.info(
                'NTRIP: Connection was active, server closed the connection',
              );
            }
          } else if (_connectionState == NTRIPConnectionState.connecting) {
            // Connection closed before response received
            _errorMessage = 'NTRIP connection closed before response';
            _updateConnectionState(NTRIPConnectionState.error);
            _errorController.add(_errorMessage!);
            if (const bool.fromEnvironment('dart.vm.product') == false) {
              _logger.warning(
                'NTRIP: Connection closed before receiving response',
              );
            }
          }
          _updateConnectionState(NTRIPConnectionState.disconnected);
          _socket = null;
          _secureSocket = null;
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete();
          }
        },
        cancelOnError: false,
      );

      // Timeout if no response received (increased to 30 seconds for slow servers)
      timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!responseComplete &&
            _connectionState == NTRIPConnectionState.connecting) {
          // Timeout logging removed - error message is set and emitted
          _rtcmStreamSubscription?.cancel();
          _errorMessage =
              'NTRIP connection timeout (no response after 30 seconds)';
          _updateConnectionState(NTRIPConnectionState.error);
          _errorController.add(_errorMessage!);
          _socket?.close();
          _secureSocket?.close();
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(
              TimeoutException('NTRIP connection timeout'),
            );
          }
        }
      });

      // Wait for response or timeout
      try {
        await responseCompleter.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            if (!responseCompleter.isCompleted) {
              _errorMessage = 'NTRIP connection timeout';
              _updateConnectionState(NTRIPConnectionState.error);
              _errorController.add(_errorMessage!);
              _socket?.close();
              throw TimeoutException('NTRIP connection timeout');
            }
          },
        );

        // Verify connection state after waiting
        if (_connectionState != NTRIPConnectionState.connected &&
            _connectionState != NTRIPConnectionState.error) {
          // If we got here but state isn't set, something went wrong
          _errorMessage = 'NTRIP connection failed: Unexpected state';
          _updateConnectionState(NTRIPConnectionState.error);
          _errorController.add(_errorMessage!);
        }
      } catch (e) {
        // Error already handled in listeners, but ensure state is set
        if (_connectionState == NTRIPConnectionState.connecting) {
          _errorMessage ??= 'NTRIP connection failed: $e';
          _updateConnectionState(NTRIPConnectionState.error);
          _errorController.add(_errorMessage!);
        }
        _socket?.close();
        _secureSocket?.close();
        _socket = null;
        _secureSocket = null;
        rethrow;
      }
    } catch (e) {
      if (_connectionState != NTRIPConnectionState.error) {
        _errorMessage = 'Failed to connect to NTRIP caster: $e';
        _updateConnectionState(NTRIPConnectionState.error);
        _errorController.add(_errorMessage!);
      }
      // Error logging removed - error message is set and emitted above
      _socket?.close();
      _secureSocket?.close();
      _socket = null;
      _secureSocket = null;
      rethrow;
    }
  }

  StreamSubscription<List<int>>? _rtcmStreamSubscription;

  /// Sends an NMEA GGA sentence to the NTRIP server.
  /// Many NTRIP servers require periodic GGA sentences to know the rover position
  /// and send appropriate RTCM corrections.
  void sendGgaSentence(Position position, [NMEAData? nmeaData]) {
    if (_connectionState != NTRIPConnectionState.connected || _socket == null) {
      return;
    }

    try {
      // Format: $GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh
      // Convert decimal degrees to degrees and minutes
      final latDegrees = position.latitude.abs().floor();
      final latMinutes = (position.latitude.abs() - latDegrees) * 60.0;
      final latDir = position.latitude >= 0 ? 'N' : 'S';
      final latStr =
          '${latDegrees.toString().padLeft(2, '0')}${latMinutes.toStringAsFixed(4).padLeft(7, '0')}';

      final lonDegrees = position.longitude.abs().floor();
      final lonMinutes = (position.longitude.abs() - lonDegrees) * 60.0;
      final lonDir = position.longitude >= 0 ? 'E' : 'W';
      final lonStr =
          '${lonDegrees.toString().padLeft(3, '0')}${lonMinutes.toStringAsFixed(4).padLeft(7, '0')}';

      // Get current time
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}.'
          '${(now.millisecond ~/ 100).toString().padLeft(1, '0')}';

      // Fix quality: 0=no fix, 1=GPS fix, 2=DGPS fix, 4=RTK fix, 5=RTK float
      int fixQuality = 1;
      int numSatellites = 12;
      String hdop = '1.0';
      String altitude = position.altitude.toStringAsFixed(1);
      String geoidHeight = '0.0';

      // Use NMEA data if available for more accurate values
      if (nmeaData != null) {
        fixQuality = nmeaData.fixQuality;
        numSatellites = nmeaData.satellites ?? 12;
        hdop = (nmeaData.hdop ?? 1.0).toStringAsFixed(1);
        if (nmeaData.altitude != null) {
          altitude = nmeaData.altitude!.toStringAsFixed(1);
        }
        if (nmeaData.geoidHeight != null) {
          geoidHeight = nmeaData.geoidHeight!.toStringAsFixed(1);
        }
      }

      // Build GGA sentence (without $ and checksum)
      final ggaData =
          'GPGGA,$timeStr,$latStr,$latDir,$lonStr,$lonDir,'
          '$fixQuality,$numSatellites,$hdop,$altitude,M,$geoidHeight,M,,';

      // Calculate checksum
      int checksum = 0;
      for (int i = 0; i < ggaData.length; i++) {
        checksum ^= ggaData.codeUnitAt(i);
      }
      final checksumStr = checksum
          .toRadixString(16)
          .toUpperCase()
          .padLeft(2, '0');

      final fullSentence = '\$$ggaData*$checksumStr\r\n';

      // Send to NTRIP server
      _socket?.add(fullSentence.codeUnits);

      // Only log GGA sending occasionally to reduce log noise
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // Log first GGA and then every 10th one
        if (_ggaSendCount == 0 || _ggaSendCount % 10 == 0) {
          _logger.info(
            'NTRIP: Sent GGA sentence #$_ggaSendCount: $fullSentence',
          );
        }
        _ggaSendCount++;
      }
    } catch (e) {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // GGA error logging removed - non-critical
      }
    }
  }

  /// Starts monitoring for data reception to detect idle connections
  void _startDataMonitoring() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectionState == NTRIPConnectionState.connected) {
        final now = DateTime.now();
        if (_lastDataReceivedTime != null) {
          final timeSinceLastData = now.difference(_lastDataReceivedTime!);
          // Only log warnings if no data for >60 seconds
          if (timeSinceLastData.inSeconds > 60 &&
              const bool.fromEnvironment('dart.vm.product') == false) {
            _logger.warning(
              'NTRIP: No data received for ${timeSinceLastData.inSeconds} seconds',
            );
          }
        }
      }
    });
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
      // State change logging removed - UI shows state changes
    }
  }

  /// Internal disconnect method (closes sockets and subscriptions)
  Future<void> _disconnectInternal() async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    await _rtcmStreamSubscription?.cancel();
    _rtcmStreamSubscription = null;

    if (_secureSocket != null) {
      try {
        await _secureSocket!.close();
      } catch (e) {
        // Ignore errors during disconnect
      }
      _secureSocket = null;
    }
    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (e) {
        // Ignore errors during disconnect
      }
      _socket = null;
    }
  }

  /// Disconnects from the NTRIP caster.
  Future<void> disconnect() async {
    await _disconnectInternal();
    _updateConnectionState(NTRIPConnectionState.disconnected);
    _errorMessage = null;
    _rtcmMessageCount = 0;
    _ggaSendCount = 0;
    _hasValidatedFirstRtcm = false;
    _lastDataReceivedTime = null;

    // Disconnect logging removed - not needed for normal operation
  }

  /// Requests the source table (list of available mount points) from the NTRIP caster.
  ///
  /// Returns a list of mount point identifiers.
  Future<List<String>> requestSourceTable({
    required String host,
    required int port,
    String? username,
    String? password,
    bool useSsl = false,
  }) async {
    Socket? socket;
    SecureSocket? secureSocket;
    try {
      if (useSsl) {
        secureSocket = await SecureSocket.connect(
          host,
          port,
          timeout: const Duration(seconds: 10),
        );
        socket = secureSocket;
      } else {
        socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 10),
        );
      }

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
      secureSocket?.close();
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
