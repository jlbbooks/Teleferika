import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';
import 'package:teleferika/licensing/licence_model.dart';

/// Utility for generating test licences
/// This is for demonstration and testing purposes only
class LicenceGeneratorUtility {
  static final Logger _logger = Logger('LicenceGeneratorUtility');

  /// Save licence to file
  static Future<void> saveLicenceToFile(
    String licenceJson,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(licenceJson);
      _logger.info('Licence saved to: $filePath');
    } catch (e, stackTrace) {
      _logger.severe('Error saving licence to file', e, stackTrace);
      rethrow;
    }
  }

  /// Print device information for debugging
  static Future<void> printDeviceInfo() async {
    try {
      final deviceInfo = await DeviceFingerprint.getDeviceInfo();
      final fingerprint = await DeviceFingerprint.generate();

      _logger.info('=== Device Information ===');
      deviceInfo.forEach((key, value) {
        _logger.info('$key: $value');
      });
      _logger.info('Device Fingerprint: ${fingerprint.substring(0, 16)}...');
      _logger.info('========================');
    } catch (e, stackTrace) {
      _logger.severe('Error printing device info', e, stackTrace);
    }
  }

  /// Validate a licence file
  static Future<bool> validateLicenceFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.warning('Licence file does not exist: $filePath');
        return false;
      }

      final content = await file.readAsString();
      final licence = Licence.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );

      _logger.info('=== Licence Validation ===');
      _logger.info('Email: ${licence.email}');
      _logger.info('Valid Until: ${licence.validUntil}');
      _logger.info('Features: ${licence.features}');
      _logger.info('Algorithm: ${licence.algorithm}');
      _logger.info('Is Valid: ${licence.isValid}');
      _logger.info('Days Remaining: ${licence.daysRemaining}');
      _logger.info('========================');

      return licence.isValid;
    } catch (e, stackTrace) {
      _logger.severe('Error validating licence file', e, stackTrace);
      return false;
    }
  }
}
