import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logging/logging.dart';

/// Utility for generating and validating device fingerprints
/// Used for licence validation to prevent licence sharing
class DeviceFingerprint {
  static final Logger _logger = Logger('DeviceFingerprint');
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Generate a unique device fingerprint
  ///
  /// This creates a hash based on device-specific information that
  /// remains consistent across app restarts but changes if the device
  /// is significantly modified or replaced.
  static Future<String> generate() async {
    try {
      String fingerprint = '';

      if (Platform.isAndroid) {
        fingerprint = await _generateAndroidFingerprint();
      } else if (Platform.isIOS) {
        fingerprint = await _generateIOSFingerprint();
      } else {
        // Fallback for other platforms
        fingerprint = await _generateGenericFingerprint();
      }

      final hashedFingerprint = _hashFingerprint(fingerprint);
      _logger.info(
        'Generated device fingerprint: ${hashedFingerprint.substring(0, 8)}...',
      );

      return hashedFingerprint;
    } catch (e, stackTrace) {
      _logger.severe('Failed to generate device fingerprint', e, stackTrace);
      rethrow;
    }
  }

  /// Generate fingerprint for Android devices
  static Future<String> _generateAndroidFingerprint() async {
    final androidInfo = await _deviceInfo.androidInfo;
    final packageInfo = await PackageInfo.fromPlatform();

    // Use stable identifiers that don't change frequently
    final components = [
      androidInfo.model, // Device model
      androidInfo.brand, // Device brand
      androidInfo.device, // Device name
      androidInfo.product, // Product name
      androidInfo.fingerprint, // Build fingerprint
      packageInfo.packageName, // App package name
      packageInfo.version, // App version
      androidInfo.version.sdkInt.toString(), // Android SDK version
    ];

    return components.join('|');
  }

  /// Generate fingerprint for iOS devices
  static Future<String> _generateIOSFingerprint() async {
    final iosInfo = await _deviceInfo.iosInfo;
    final packageInfo = await PackageInfo.fromPlatform();

    // Use stable identifiers that don't change frequently
    final components = [
      iosInfo.model, // Device model
      iosInfo.name, // Device name
      iosInfo.systemName, // iOS
      iosInfo.systemVersion, // iOS version
      iosInfo.identifierForVendor, // Vendor identifier (stable per app)
      packageInfo.packageName, // App bundle ID
      packageInfo.version, // App version
    ];

    return components.join('|');
  }

  /// Generate generic fingerprint for other platforms
  static Future<String> _generateGenericFingerprint() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final components = [
      Platform.operatingSystem,
      Platform.operatingSystemVersion,
      packageInfo.packageName,
      packageInfo.version,
      DateTime.now().millisecondsSinceEpoch.toString(), // Fallback
    ];

    return components.join('|');
  }

  /// Hash the fingerprint using SHA-256
  static String _hashFingerprint(String fingerprint) {
    final bytes = utf8.encode(fingerprint);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate if a stored fingerprint matches the current device
  static Future<bool> validateFingerprint(String storedFingerprint) async {
    try {
      final currentFingerprint = await generate();
      final isValid = currentFingerprint == storedFingerprint;

      if (!isValid) {
        _logger.warning(
          'Device fingerprint mismatch. Expected: ${storedFingerprint.substring(0, 8)}..., Got: ${currentFingerprint.substring(0, 8)}...',
        );
      }

      return isValid;
    } catch (e, stackTrace) {
      _logger.severe('Failed to validate device fingerprint', e, stackTrace);
      return false;
    }
  }

  /// Get device information for debugging
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'fingerprint': androidInfo.fingerprint,
          'sdkVersion': androidInfo.version.sdkInt,
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
        };
      } else {
        return {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
        };
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to get device info', e, stackTrace);
      return {'error': e.toString()};
    }
  }
}
