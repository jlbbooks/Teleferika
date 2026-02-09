/// Helpers for NMEA/PMTK commands sent to GNSS receivers.
///
/// Many receivers (u-blox, Mediatek, and compatible) accept PMTK sentences
/// to configure update rate. Sending a 5 Hz request on connect can make
/// position updates feel more responsive when the receiver supports it.

/// Builds a PMTK sentence with NMEA checksum: `$payload*XX`.
/// [payload] is the part between `$` and `*` (e.g. `PMTK220,200`).
String buildPmtkSentence(String payload) {
  int checksum = 0;
  for (var i = 0; i < payload.length; i++) {
    checksum ^= payload.codeUnitAt(i);
  }
  final hex = checksum.toRadixString(16).toUpperCase().padLeft(2, '0');
  return '\$$payload*$hex';
}

/// PMTK sentence to set NMEA update rate to 5 Hz (200 ms interval).
/// Many receivers accept this; others ignore unknown sentences.
/// Returns the sentence without trailing \\r\\n so caller can add if needed.
String getPmtk5HzUpdateRateSentence() {
  return buildPmtkSentence('PMTK220,200');
}
