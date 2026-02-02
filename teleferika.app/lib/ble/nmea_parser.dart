
/// NMEA sentence parser for RTK GPS receivers.
///
/// Parses NMEA sentences (GPGGA, GPRMC, etc.) from RTK GPS devices
/// and extracts GPS position data including coordinates, altitude, and accuracy.
class NMEAParser {
  /// Parses a complete NMEA sentence and extracts GPS data.
  ///
  /// Returns a [NMEAData] object if parsing is successful, null otherwise.
  /// Supports GPGGA (Global Positioning System Fix Data) and GPRMC (Recommended Minimum) sentences.
  static NMEAData? parseSentence(String sentence) {
    if (!_isValidSentence(sentence)) {
      return null;
    }

    final fields = sentence.split(',');
    if (fields.isEmpty) {
      return null;
    }

    final sentenceType = fields[0];

    switch (sentenceType) {
      case '\$GPGGA':
      case '\$GNGGA':
        return _parseGPGGA(fields);
      case '\$GPRMC':
      case '\$GNRMC':
        return _parseGPRMC(fields);
      default:
        return null;
    }
  }

  /// Validates NMEA sentence format and checksum.
  static bool _isValidSentence(String sentence) {
    if (!sentence.startsWith('\$')) {
      return false;
    }

    // Check for checksum (format: $...*XX)
    final checksumIndex = sentence.indexOf('*');
    if (checksumIndex == -1 || checksumIndex >= sentence.length - 2) {
      return false;
    }

    // Verify checksum
    final data = sentence.substring(1, checksumIndex);
    final checksum = sentence.substring(checksumIndex + 1).trim();

    int calculatedChecksum = 0;
    for (int i = 0; i < data.length; i++) {
      calculatedChecksum ^= data.codeUnitAt(i);
    }

    final expectedChecksum = calculatedChecksum
        .toRadixString(16)
        .toUpperCase()
        .padLeft(2, '0');
    return checksum.toUpperCase() == expectedChecksum;
  }

  /// Parses GPGGA sentence (Global Positioning System Fix Data).
  ///
  /// Format: $GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh
  static NMEAData? _parseGPGGA(List<String> fields) {
    if (fields.length < 15) {
      return null;
    }

    try {
      // Time (field 1) - hhmmss.ss
      final timeStr = fields[1];
      final time = _parseTime(timeStr);

      // Latitude (fields 2-3) - ddmm.mmmm,a
      final latStr = fields[2];
      final latDir = fields[3];
      final latitude = _parseLatitude(latStr, latDir);
      if (latitude == null) return null;

      // Longitude (fields 4-5) - dddmm.mmmm,a
      final lonStr = fields[4];
      final lonDir = fields[5];
      final longitude = _parseLongitude(lonStr, lonDir);
      if (longitude == null) return null;

      // Fix quality (field 6)
      final fixQuality = int.tryParse(fields[6]) ?? 0;

      // Number of satellites (field 7)
      final satellites = int.tryParse(fields[7]) ?? 0;

      // HDOP (field 8) - Horizontal Dilution of Precision
      final hdop = double.tryParse(fields[8]) ?? 0.0;

      // Altitude (fields 9-10) - altitude,M
      final altitude = double.tryParse(fields[9]) ?? 0.0;

      // Geoid height (fields 11-12) - geoid height,M
      final geoidHeight = double.tryParse(fields[11]) ?? 0.0;

      // Time since last DGPS update (field 13)
      final dgpsAge = fields.length > 13 ? fields[13] : '';

      // DGPS station ID (field 14)
      final dgpsStationId = fields.length > 14 ? fields[14].split('*')[0] : '';

      // Calculate accuracy from HDOP (rough approximation)
      // HDOP * 3-5 meters is typical for GPS accuracy
      final accuracy = hdop * 3.0;

      return NMEAData(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        accuracy: accuracy,
        satellites: satellites,
        fixQuality: fixQuality,
        hdop: hdop,
        time: time,
        geoidHeight: geoidHeight,
        sentenceType: 'GPGGA',
      );
    } catch (e) {
      return null;
    }
  }

  /// Parses GPRMC sentence (Recommended Minimum).
  ///
  /// Format: $GPRMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,x.x,x.x,ddmmyy,x.x,a*hh
  static NMEAData? _parseGPRMC(List<String> fields) {
    if (fields.length < 12) {
      return null;
    }

    try {
      // Time (field 1)
      final timeStr = fields[1];
      final time = _parseTime(timeStr);

      // Status (field 2) - A = valid, V = invalid
      final status = fields[2];
      if (status != 'A') {
        return null; // Invalid fix
      }

      // Latitude (fields 3-4)
      final latStr = fields[3];
      final latDir = fields[4];
      final latitude = _parseLatitude(latStr, latDir);
      if (latitude == null) return null;

      // Longitude (fields 5-6)
      final lonStr = fields[5];
      final lonDir = fields[6];
      final longitude = _parseLongitude(lonStr, lonDir);
      if (longitude == null) return null;

      // Speed over ground (field 7) - knots
      final speedKnots = double.tryParse(fields[7]) ?? 0.0;

      // Course over ground (field 8) - degrees
      final course = double.tryParse(fields[8]) ?? 0.0;

      // Date (field 9) - ddmmyy
      final dateStr = fields[9];
      final date = _parseDate(dateStr);

      // Magnetic variation (fields 10-11)
      final magVar = double.tryParse(fields[10]) ?? 0.0;

      return NMEAData(
        latitude: latitude,
        longitude: longitude,
        altitude: null, // GPRMC doesn't include altitude
        accuracy: null, // GPRMC doesn't include accuracy
        satellites: null, // GPRMC doesn't include satellite count
        fixQuality: status == 'A' ? 1 : 0,
        hdop: null,
        time: time,
        speed: speedKnots * 1.852, // Convert knots to km/h
        course: course,
        date: date,
        sentenceType: 'GPRMC',
      );
    } catch (e) {
      return null;
    }
  }

  /// Parses latitude from NMEA format (ddmm.mmmm) to decimal degrees.
  static double? _parseLatitude(String latStr, String direction) {
    if (latStr.isEmpty || direction.isEmpty) return null;

    final lat = double.tryParse(latStr);
    if (lat == null) return null;

    final degrees = (lat / 100).floor();
    final minutes = lat - (degrees * 100);
    final decimal = degrees + (minutes / 60);

    return direction.toUpperCase() == 'N' ? decimal : -decimal;
  }

  /// Parses longitude from NMEA format (dddmm.mmmm) to decimal degrees.
  static double? _parseLongitude(String lonStr, String direction) {
    if (lonStr.isEmpty || direction.isEmpty) return null;

    final lon = double.tryParse(lonStr);
    if (lon == null) return null;

    final degrees = (lon / 100).floor();
    final minutes = lon - (degrees * 100);
    final decimal = degrees + (minutes / 60);

    return direction.toUpperCase() == 'E' ? decimal : -decimal;
  }

  /// Parses time from NMEA format (hhmmss.ss) to DateTime.
  static DateTime? _parseTime(String timeStr) {
    if (timeStr.length < 6) return null;

    try {
      final hour = int.parse(timeStr.substring(0, 2));
      final minute = int.parse(timeStr.substring(2, 4));
      final second = int.parse(timeStr.substring(4, 6));

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (e) {
      return null;
    }
  }

  /// Parses date from NMEA format (ddmmyy) to DateTime.
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.length < 6) return null;

    try {
      final day = int.parse(dateStr.substring(0, 2));
      final month = int.parse(dateStr.substring(2, 4));
      final year = 2000 + int.parse(dateStr.substring(4, 6));

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}

/// Represents parsed NMEA GPS data.
class NMEAData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy; // in meters
  final int? satellites;
  final int fixQuality; // 0 = invalid, 1 = GPS fix, 2 = DGPS fix, etc.
  final double? hdop; // Horizontal Dilution of Precision
  final DateTime? time;
  final double? geoidHeight;
  final double? speed; // in km/h
  final double? course; // in degrees
  final DateTime? date;
  final String sentenceType;

  NMEAData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.satellites,
    required this.fixQuality,
    this.hdop,
    this.time,
    this.geoidHeight,
    this.speed,
    this.course,
    this.date,
    required this.sentenceType,
  });

  /// Returns true if the GPS fix is valid.
  bool get isValid => fixQuality > 0;

  @override
  String toString() {
    return 'NMEAData(lat: $latitude, lon: $longitude, alt: $altitude, '
        'accuracy: $accuracy, satellites: $satellites, fix: $fixQuality)';
  }
}
