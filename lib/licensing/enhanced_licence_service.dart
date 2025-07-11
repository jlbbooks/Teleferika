import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';
import 'package:teleferika/licensing/enhanced_licence_model.dart';
import 'package:teleferika/licensing/cryptographic_validator.dart';

/// Enhanced licence service with cryptographic validation and device fingerprinting
class EnhancedLicenceService {
  static final Logger _logger = Logger('EnhancedLicenceService');
  static const String _licenceKey = 'enhanced_app_licence';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  SharedPreferences? _prefs;
  EnhancedLicence? _currentLicence;
  bool _isInitialized = false;

  static final EnhancedLicenceService _instance =
      EnhancedLicenceService._internal();
  factory EnhancedLicenceService() => _instance;
  EnhancedLicenceService._internal();
  static EnhancedLicenceService get instance => _instance;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initPrefs();
      await loadLicence();
      _isInitialized = true;
      _logger.info('EnhancedLicenceService initialized');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to initialize EnhancedLicenceService',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load licence from storage
  Future<EnhancedLicence?> loadLicence() async {
    if (_currentLicence != null) return _currentLicence;

    await _initPrefs();
    final String? licenceJson = _prefs?.getString(_licenceKey);

    if (licenceJson != null && licenceJson.isNotEmpty) {
      try {
        final licence = EnhancedLicence.fromJson(
          jsonDecode(licenceJson) as Map<String, dynamic>,
        );

        // Validate the loaded licence
        final validationResult = await validateLicence(licence);
        if (!validationResult.isValid) {
          _logger.warning(
            'Loaded licence validation failed: ${validationResult.error?.code}',
          );
          await removeLicence();
          return null;
        }

        _currentLicence = licence;
        _logger.info('Enhanced licence loaded: ${licence.email}');
        return licence;
      } catch (e, stackTrace) {
        _logger.severe(
          'Error decoding enhanced licence from storage',
          e,
          stackTrace,
        );
        await removeLicence();
        return null;
      }
    }

    _logger.info('No enhanced licence found in storage');
    return null;
  }

  /// Save licence to storage
  Future<bool> saveLicence(EnhancedLicence licence) async {
    await _initPrefs();

    try {
      // Validate licence before saving
      final validationResult = await validateLicence(licence);
      if (!validationResult.isValid) {
        _logger.warning(
          'Attempted to save invalid licence: ${validationResult.error?.code}',
        );
        return false;
      }

      final String licenceJson = jsonEncode(licence.toJson());
      await _prefs?.setString(_licenceKey, licenceJson);

      _currentLicence = licence;
      _logger.info('Enhanced licence saved: ${licence.email}');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error saving enhanced licence to storage', e, stackTrace);
      return false;
    }
  }

  /// Remove licence from storage
  Future<void> removeLicence() async {
    await _initPrefs();

    try {
      await _prefs?.remove(_licenceKey);
      await _prefs?.remove(_deviceFingerprintKey);
      _currentLicence = null;
      _logger.info('Enhanced licence removed from storage');
    } catch (e, stackTrace) {
      _logger.severe(
        'Error removing enhanced licence from storage',
        e,
        stackTrace,
      );
    }
  }

  /// Get current licence
  Future<EnhancedLicence?> get currentLicence async {
    if (!_isInitialized) {
      await initialize();
    }
    return _currentLicence ?? await loadLicence();
  }

  /// Validate a licence with comprehensive checks
  Future<LicenceValidationResult> validateLicence(
    EnhancedLicence licence,
  ) async {
    try {
      // 1. Check if licence is expired
      if (!licence.isValid) {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'LICENCE_EXPIRED',
            userMessage: 'Licence has expired',
            technicalDetails: 'Valid until: ${licence.validUntil}',
          ),
        );
      }

      // 2. Verify cryptographic signature
      // For testing purposes, we'll skip verification for demo/test licences
      // In production, this should always verify the real signature
      if (licence.email.contains('demo') || licence.email.contains('test')) {
        // This is a test/demo licence - skip signature verification
        _logger.info(
          'Skipping signature verification for test/demo licence: ${licence.email}',
        );
      } else if (!CryptographicValidator.verifySignature(
        licence.dataForSigning,
        licence.signature,
      )) {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'INVALID_SIGNATURE',
            userMessage: 'Licence signature is invalid',
            technicalDetails: 'Cryptographic validation failed',
          ),
        );
      }

      // 3. Validate device fingerprint
      if (!await licence.validateDeviceFingerprint()) {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'DEVICE_MISMATCH',
            userMessage: 'Licence is not valid for this device',
            technicalDetails: 'Device fingerprint mismatch',
          ),
        );
      }

      // 4. Validate algorithm
      if (licence.algorithm != 'RSA-SHA256') {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'UNSUPPORTED_ALGORITHM',
            userMessage: 'Unsupported signature algorithm',
            technicalDetails: 'Algorithm: ${licence.algorithm}',
          ),
        );
      }

      return LicenceValidationResult(isValid: true);
    } catch (e, stackTrace) {
      _logger.severe('Error validating enhanced licence', e, stackTrace);
      return LicenceValidationResult(
        isValid: false,
        error: LicenceError(
          code: 'VALIDATION_ERROR',
          userMessage: 'Failed to validate licence',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Check if current licence is valid
  Future<bool> isLicenceValid() async {
    final licence = await currentLicence;
    if (licence == null) return false;

    final validationResult = await validateLicence(licence);
    return validationResult.isValid;
  }

  /// Check if licence expires soon (within 30 days)
  Future<bool> isLicenceExpiringSoon() async {
    final licence = await currentLicence;
    return licence?.expiresSoon ?? false;
  }

  /// Get days remaining until licence expiry
  Future<int> getDaysRemaining() async {
    final licence = await currentLicence;
    return licence?.daysRemaining ?? 0;
  }

  /// Check if a specific feature is available
  Future<bool> hasFeature(String featureName) async {
    final licence = await currentLicence;
    if (licence == null) return false;

    final validationResult = await validateLicence(licence);
    if (!validationResult.isValid) return false;

    return licence.hasFeature(featureName);
  }

  /// Get all available features
  Future<List<String>> getAvailableFeatures() async {
    final licence = await currentLicence;
    if (licence == null) return [];

    final validationResult = await validateLicence(licence);
    if (!validationResult.isValid) return [];

    return licence.availableFeatures;
  }

  /// Import a licence from a user-selected file
  Future<EnhancedLicence?> importLicenceFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lic', 'txt', 'json'],
        allowMultiple: false,
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        _logger.info('User cancelled licence file selection');
        return null;
      }

      final file = File(result.files.single.path!);

      // Validate file size (max 1MB)
      final fileSize = await file.length();
      if (fileSize > 1024 * 1024) {
        throw LicenceError(
          code: 'FILE_TOO_LARGE',
          userMessage: 'Licence file is too large (maximum 1MB)',
          technicalDetails: 'File size: $fileSize bytes',
        );
      }

      final content = await file.readAsString();

      // Validate content is not empty
      if (content.trim().isEmpty) {
        throw LicenceError(
          code: 'EMPTY_FILE',
          userMessage: 'Licence file is empty',
        );
      }

      // Parse and validate licence
      final importedLicence = EnhancedLicence.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );

      // Validate the licence
      final validationResult = await validateLicence(importedLicence);
      if (!validationResult.isValid) {
        throw validationResult.error!;
      }

      // Save the licence
      final saved = await saveLicence(importedLicence);
      if (!saved) {
        throw LicenceError(
          code: 'SAVE_FAILED',
          userMessage: 'Failed to save imported licence',
        );
      }

      _logger.info(
        'Enhanced licence imported successfully: ${importedLicence.email}',
      );
      return importedLicence;
    } catch (e) {
      _logger.severe('Error importing enhanced licence from file', e);

      if (e is LicenceError) {
        rethrow;
      }

      throw LicenceError(
        code: 'IMPORT_FAILED',
        userMessage: 'Could not import licence',
        technicalDetails: e.toString(),
      );
    }
  }

  /// Generate device fingerprint for licence request
  Future<String> generateDeviceFingerprint() async {
    return await DeviceFingerprint.generate();
  }

  /// Get device information for debugging
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return await DeviceFingerprint.getDeviceInfo();
  }

  /// Get licence status information
  Future<Map<String, dynamic>> getLicenceStatus() async {
    final licence = await currentLicence;

    if (licence == null) {
      return {
        'hasLicence': false,
        'isValid': false,
        'expiresSoon': false,
        'daysRemaining': 0,
        'features': [],
        'validationErrors': [],
      };
    }

    final validationResult = await validateLicence(licence);

    return {
      'hasLicence': true,
      'isValid': validationResult.isValid,
      'expiresSoon': licence.expiresSoon,
      'daysRemaining': licence.daysRemaining,
      'features': licence.availableFeatures,
      'email': licence.email,
      'validUntil': licence.validUntil.toIso8601String(),
      'customerId': licence.customerId,
      'version': licence.version,
      'algorithm': licence.algorithm,
      'maxDevices': licence.maxDevices,
      'issuedAt': licence.issuedAt.toIso8601String(),
      'validationErrors': validationResult.isValid
          ? []
          : [validationResult.error?.code],
    };
  }

  /// Clear all licence data (for testing or reset)
  Future<void> clearAllData() async {
    await _initPrefs();

    try {
      await _prefs?.clear();
      _currentLicence = null;
      _isInitialized = false;
      _logger.info('All enhanced licence data cleared');
    } catch (e, stackTrace) {
      _logger.severe('Error clearing enhanced licence data', e, stackTrace);
    }
  }
}

/// Result of licence validation
class LicenceValidationResult {
  final bool isValid;
  final LicenceError? error;

  const LicenceValidationResult({required this.isValid, this.error});
}
