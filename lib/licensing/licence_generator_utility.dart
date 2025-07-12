import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';
import 'package:teleferika/licensing/licence_model.dart';

/// Utility for generating test licences
/// This is for demonstration and testing purposes only
class LicenceGeneratorUtility {
  static final Logger _logger = Logger('LicenceGeneratorUtility');

  /// Generate a test licence for the current device
  /// This demonstrates the complete licence generation flow
  static Future<String> generateTestLicence({
    required String email,
    required List<String> features,
    required DateTime validUntil,
    String? customerId,
    int maxDevices = 1,
  }) async {
    try {
      // 1. Generate device fingerprint
      final deviceFingerprint = await DeviceFingerprint.generate();
      _logger.info(
        'Generated device fingerprint: ${deviceFingerprint.substring(0, 8)}...',
      );

      // 2. Create licence data
      final licenceData = {
        'email': email,
        'deviceFingerprint': deviceFingerprint,
        'validUntil': validUntil.toIso8601String(),
        'features': features,
        'customerId': customerId,
        'maxDevices': maxDevices,
        'issuedAt': DateTime.now().toIso8601String(),
        'version': '2.0',
      };

      // 3. Convert to JSON for signing
      final jsonData = jsonEncode(licenceData);

      // 4. Create a mock signature (in real implementation, this would be signed with private key)
      final mockSignature = _generateMockSignature(jsonData);

      // 5. Create final licence structure
      final licence = {
        'data': licenceData,
        'signature': mockSignature,
        'algorithm': 'RSA-SHA256',
      };

      final licenceJson = jsonEncode(licence);
      _logger.info('Generated test licence for: $email');

      return licenceJson;
    } catch (e, stackTrace) {
      _logger.severe('Error generating test licence', e, stackTrace);
      rethrow;
    }
  }

  /// Generate a mock signature for testing
  /// In production, this would be replaced with actual RSA signing
  static String _generateMockSignature(String data) {
    // This is a placeholder - in real implementation, you would:
    // 1. Load the private key
    // 2. Sign the data with RSA-SHA256
    // 3. Return base64-encoded signature

    // For testing, we'll create a simple hash-based signature
    // that looks like a real signature but won't verify
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    final mockSignature = base64Encode(hash.bytes);

    // Make it look more like a real RSA signature (longer)
    return mockSignature + 'A' * 50; // Add padding to make it longer
  }

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

  /// Generate and save a test licence
  static Future<String> generateAndSaveTestLicence({
    required String email,
    required List<String> features,
    required DateTime validUntil,
    String? customerId,
    int maxDevices = 1,
    String? outputPath,
  }) async {
    final licenceJson = await generateTestLicence(
      email: email,
      features: features,
      validUntil: validUntil,
      customerId: customerId,
      maxDevices: maxDevices,
    );

    if (outputPath != null) {
      await saveLicenceToFile(licenceJson, outputPath);
    }

    return licenceJson;
  }

  /// Create a demo licence with common features
  static Future<String> createDemoLicence({
    String email = 'demo@example.com',
    DateTime? validUntil,
  }) async {
    final features = [
      'advanced_export',
      'map_download',
      'batch_operations',
      'cloud_sync',
      'custom_themes',
    ];

    return await generateTestLicence(
      email: email,
      features: features,
      validUntil: validUntil ?? DateTime.now().add(const Duration(days: 365)),
      customerId: 'DEMO001',
      maxDevices: 1,
    );
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
