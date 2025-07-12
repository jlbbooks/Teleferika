import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';
import 'package:teleferika/licensing/licence_model.dart';
import 'package:teleferika/licensing/cryptographic_validator.dart';

// Import status constants

/// Unified licence service with comprehensive validation, device fingerprinting, and status tracking
class LicenceService {
  static final Logger _logger = Logger('LicenceService');
  static const String _licenceKey = 'app_licence';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  SharedPreferences? _prefs;
  Licence? _currentLicence;
  bool _isInitialized = false;

  static final LicenceService _instance = LicenceService._internal();
  factory LicenceService() => _instance;
  LicenceService._internal();
  static LicenceService get instance => _instance;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initPrefs();
      await loadLicence();
      _isInitialized = true;
      _logger.info('LicenceService initialized');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize LicenceService', e, stackTrace);
      rethrow;
    }
  }

  /// Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load licence from storage
  Future<Licence?> loadLicence() async {
    if (_currentLicence != null) return _currentLicence;

    await _initPrefs();
    final String? licenceJson = _prefs?.getString(_licenceKey);

    if (licenceJson != null && licenceJson.isNotEmpty) {
      try {
        final licence = Licence.fromJson(
          jsonDecode(licenceJson) as Map<String, dynamic>,
        );

        // For requested licenses, load them without validation so UI can show status
        if (licence.status == Licence.statusRequested) {
          _currentLicence = licence;
          _logger.info(
            'Requested licence loaded: ${licence.email} (status: ${licence.status})',
          );
          return licence;
        }

        // Validate the loaded licence for non-requested licenses
        final validationResult = await validateLicence(licence);
        if (!validationResult.isValid) {
          _logger.warning(
            'Loaded licence validation failed: ${validationResult.error?.code} - ${validationResult.error?.userMessage}',
          );

          // Clear invalid license from cache and storage
          await removeLicence();

          // If it's a revoked/denied license, log it specifically
          if (licence.status == Licence.statusRevoked ||
              licence.status == Licence.statusDenied) {
            _logger.info(
              'Removed ${licence.status} license from cache: ${licence.email}',
            );
          }

          return null;
        }

        _currentLicence = licence;
        _logger.info('Licence loaded: ${licence.email}');
        return licence;
      } catch (e, stackTrace) {
        _logger.severe('Error decoding licence from storage', e, stackTrace);
        await removeLicence();
        return null;
      }
    }

    _logger.info('No licence found in storage');
    return null;
  }

  /// Save licence to storage
  Future<bool> saveLicence(Licence licence) async {
    await _initPrefs();

    try {
      // For requested licenses, we allow them to be saved so the UI can show their status
      // but we don't validate them as "valid" for feature access
      if (licence.status == Licence.statusRequested) {
        final String licenceJson = jsonEncode(licence.toJson());
        await _prefs?.setString(_licenceKey, licenceJson);

        _currentLicence = licence;
        _logger.info(
          'Requested licence saved: ${licence.email} (status: ${licence.status})',
        );
        return true;
      }

      // For other licenses, validate before saving
      final validationResult = await validateLicence(licence);
      if (!validationResult.isValid) {
        _logger.warning(
          'Attempted to save invalid licence: ${validationResult.error?.code} - ${validationResult.error?.userMessage}',
        );

        // Clear any existing invalid license from cache
        if (_currentLicence != null) {
          await removeLicence();
        }

        return false;
      }

      final String licenceJson = jsonEncode(licence.toJson());
      await _prefs?.setString(_licenceKey, licenceJson);

      _currentLicence = licence;
      _logger.info('Licence saved: ${licence.email}');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error saving licence to storage', e, stackTrace);
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
      _logger.info('Licence removed from storage');
    } catch (e, stackTrace) {
      _logger.severe('Error removing licence from storage', e, stackTrace);
    }
  }

  /// Get current licence
  Future<Licence?> get currentLicence async {
    if (!_isInitialized) {
      await initialize();
    }
    return _currentLicence ?? await loadLicence();
  }

  /// Validate a licence with comprehensive checks
  Future<LicenceValidationResult> validateLicence(Licence licence) async {
    try {
      // 1. Check license status first - this is the most important check
      if (licence.status == Licence.statusRevoked) {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'LICENCE_REVOKED',
            userMessage: 'Licence has been revoked',
            technicalDetails:
                'Revoked at: ${licence.revokedAt}, Reason: ${licence.revokedReason}',
          ),
        );
      }

      if (licence.status == Licence.statusDenied) {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'LICENCE_DENIED',
            userMessage: 'Licence request was denied',
            technicalDetails:
                'Denied at: ${licence.revokedAt}, Reason: ${licence.revokedReason}',
          ),
        );
      }

      // 2. Check if licence is expired (but allow requested licenses)
      if (licence.status != Licence.statusRequested && !licence.isValid) {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'LICENCE_EXPIRED',
            userMessage: 'Licence has expired',
            technicalDetails: 'Valid until: ${licence.validUntil}',
          ),
        );
      }

      // 3. Check if licence is active (reject requested, revoked, denied licenses)
      if (licence.status != Licence.statusActive &&
          licence.status != Licence.statusDevelopment) {
        return LicenceValidationResult(
          isValid: false,
          error: LicenceError(
            code: 'LICENCE_NOT_ACTIVE',
            userMessage: 'Licence is not active',
            technicalDetails: 'Status: ${licence.status}',
          ),
        );
      }

      // 4. Verify cryptographic signature for active licenses
      // Skip verification for demo/test licences and development licenses
      if (licence.email.contains('demo') ||
          licence.email.contains('test') ||
          licence.status == Licence.statusDevelopment) {
        // Skip signature verification for test/demo/development licences
        _logger.info(
          'Skipping signature verification for ${licence.status} licence: ${licence.email}',
        );
      } else {
        // Always verify signature for active licenses
        if (!await CryptographicValidator.verifySignature(
          data: licence.dataForSigning,
          signature: licence.signature,
          algorithm: licence.algorithm,
        )) {
          // Clear the public key cache if signature verification fails
          CryptographicValidator.clearCache();

          return LicenceValidationResult(
            isValid: false,
            error: LicenceError(
              code: 'INVALID_SIGNATURE',
              userMessage: 'Licence signature is invalid',
              technicalDetails: 'Cryptographic validation failed',
            ),
          );
        }
        _logger.info(
          'Signature verification successful for active licence: ${licence.email}',
        );
      }

      // 5. Validate device fingerprint
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

      // 6. Validate algorithm
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

      return LicenceValidationResult(isValid: true, licence: licence);
    } catch (e, stackTrace) {
      _logger.severe('Error validating licence', e, stackTrace);
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

    // For requested licenses, deny all features
    if (licence.status == Licence.statusRequested) {
      _logger.info(
        'Denying feature $featureName for requested licence: ${licence.email}',
      );
      return false;
    }

    // For development licenses, allow all features without validation
    if (licence.status == Licence.statusDevelopment) {
      _logger.info(
        'Allowing feature $featureName for development licence: ${licence.email}',
      );
      return licence.hasFeature(featureName);
    }

    // For other licenses, validate them
    final validationResult = await validateLicence(licence);
    if (!validationResult.isValid) return false;

    return licence.hasFeature(featureName);
  }

  /// Get all available features
  Future<List<String>> getAvailableFeatures() async {
    final licence = await currentLicence;
    if (licence == null) return [];

    // For requested licenses, return empty list
    if (licence.status == Licence.statusRequested) {
      _logger.info(
        'No features available for requested licence: ${licence.email}',
      );
      return [];
    }

    // For development licenses, return all features without validation
    if (licence.status == Licence.statusDevelopment) {
      _logger.info(
        'All features available for development licence: ${licence.email}',
      );
      return licence.availableFeatures;
    }

    // For other licenses, validate them
    final validationResult = await validateLicence(licence);
    if (!validationResult.isValid) return [];

    return licence.availableFeatures;
  }

  /// Import a licence from a user-selected file
  Future<Licence?> importLicenceFromFile() async {
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

      // Parse licence from file content
      final licence = Licence.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );

      // Validate the licence
      final validationResult = await validateLicence(licence);
      if (!validationResult.isValid) {
        throw validationResult.error!;
      }

      // Save the licence
      final saved = await saveLicence(licence);
      if (!saved) {
        throw LicenceError(
          code: 'SAVE_FAILED',
          userMessage: 'Failed to save licence',
        );
      }

      _logger.info('Licence imported successfully: ${licence.email}');
      return licence;
    } catch (e, stackTrace) {
      _logger.severe('Error importing licence from file', e, stackTrace);
      rethrow;
    }
  }

  /// Get licence status information
  Future<Map<String, dynamic>> getLicenceStatus() async {
    final licence = await currentLicence;
    if (licence == null) {
      return {
        'hasLicence': false,
        'status': 'none',
        'message': 'No licence found',
      };
    }

    final validationResult = await validateLicence(licence);
    if (!validationResult.isValid) {
      return {
        'hasLicence': true,
        'status': 'invalid',
        'message': validationResult.error?.userMessage ?? 'Licence is invalid',
        'error': validationResult.error?.code,
      };
    }

    return {
      'hasLicence': true,
      'status': 'valid',
      'email': licence.email,
      'validUntil': licence.validUntil.toIso8601String(),
      'daysRemaining': licence.daysRemaining,
      'expiresSoon': licence.expiresSoon,
      'features': licence.availableFeatures,
      'usageCount': licence.usageCount,
      'lastUsed': licence.lastUsed.toIso8601String(),
    };
  }

  /// Install a development license for testing purposes
  /// This bypasses normal validation and creates a fully valid license
  Future<bool> installDevelopmentLicense({
    required String email,
    List<String> features = const [
      'export_csv',
      'export_kml',
      'map_download',
      'advanced_export',
    ],
    int maxDevices = 1,
  }) async {
    await _initPrefs();

    try {
      _logger.info('Installing development license for: $email');

      // Create a development license that's always valid
      final developmentLicense = Licence(
        email: email,
        customerId: '',
        deviceFingerprint: await DeviceFingerprint.generate(),
        issuedAt: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 365)),
        features: features,
        maxDevices: maxDevices,
        version: '2.0',
        signature: 'development_signature_bypass',
        algorithm: 'RSA-SHA256',
        status: Licence.statusDevelopment, // Use development status
        revokedAt: null,
        revokedReason: null,
        usageCount: 0,
        lastUsed: DateTime.now(),
      );

      // Save the development license without validation
      final String licenceJson = jsonEncode(developmentLicense.toJson());
      await _prefs?.setString(_licenceKey, licenceJson);

      _currentLicence = developmentLicense;
      _logger.info('Development license installed successfully: $email');
      return true;
    } catch (e) {
      _logger.severe('Failed to install development license', e);
      return false;
    }
  }

  /// Check if current license is a development license
  bool get isDevelopmentLicense {
    final licence = _currentLicence;
    if (licence == null) return false;

    return licence.status == Licence.statusDevelopment ||
        licence.signature == 'development_signature_bypass';
  }

  /// Clear all licence data
  Future<void> clearAllData() async {
    await _initPrefs();
    await _prefs?.clear();
    _currentLicence = null;
    _isInitialized = false;
    _logger.info('All licence data cleared');
  }
}

/// Result of licence validation
class LicenceValidationResult {
  final bool isValid;
  final LicenceError? error;
  final Licence? licence;

  const LicenceValidationResult({
    required this.isValid,
    this.error,
    this.licence,
  });
}
