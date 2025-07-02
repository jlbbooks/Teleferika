// lib/services/licence_service.dart
import 'dart:convert'; // For jsonEncode/jsonDecode
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/licensing/licence_model.dart';

/// Service for managing software licences
class LicenceService {
  final Logger logger = Logger('LicenceService');
  static const String _licenceKey = 'app_licence_key';
  static const String _licenceHashKey = 'app_licence_hash';

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
      logger.info('LicenceService: LicenceService initialized');
    } catch (e, stackTrace) {
      logger.severe(
        'LicenceService: Failed to initialize LicenceService',
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
  Future<Licence?> loadLicence() async {
    if (_currentLicence != null) return _currentLicence;

    await _initPrefs();
    final String? licenceJson = _prefs?.getString(_licenceKey);

    if (licenceJson != null && licenceJson.isNotEmpty) {
      try {
        _currentLicence = Licence.fromJson(
          jsonDecode(licenceJson) as Map<String, dynamic>,
        );

        // Validate the loaded licence
        if (!_currentLicence!.isValid) {
          logger.warning('Loaded licence is expired or invalid');
          await removeLicence();
          return null;
        }

        logger.info('Licence loaded: ${_currentLicence!.email}');
        return _currentLicence;
      } catch (e, stackTrace) {
        logger.severe('Error decoding licence from storage', e, stackTrace);
        await removeLicence(); // Clear corrupted licence
        return null;
      }
    }

    logger.info('No licence found in storage');
    return null;
  }

  /// Save licence to storage
  Future<bool> saveLicence(Licence licence) async {
    await _initPrefs();

    try {
      // Validate licence before saving
      if (!licence.isValid) {
        logger.warning('Attempted to save invalid licence');
        return false;
      }

      final String licenceJson = jsonEncode(licence.toJson());
      await _prefs?.setString(_licenceKey, licenceJson);

      _currentLicence = licence;
      logger.info('Licence saved: ${licence.email}');
      return true;
    } catch (e, stackTrace) {
      logger.severe('Error saving licence to storage', e, stackTrace);
      return false;
    }
  }

  /// Remove licence from storage
  Future<void> removeLicence() async {
    await _initPrefs();

    try {
      await _prefs?.remove(_licenceKey);
      await _prefs?.remove(_licenceHashKey);
      _currentLicence = null;
      logger.info('Licence removed from storage');
    } catch (e, stackTrace) {
      logger.severe('Error removing licence from storage', e, stackTrace);
    }
  }

  /// Get current licence
  Future<Licence?> get currentLicence async {
    if (!_isInitialized) {
      await initialize();
    }
    return _currentLicence ?? await loadLicence();
  }

  /// Check if current licence is valid
  Future<bool> isLicenceValid() async {
    final licence = await currentLicence;
    return licence?.isValid ?? false;
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
    return licence?.hasFeature(featureName) ?? false;
  }

  /// Get all available features
  Future<List<String>> getAvailableFeatures() async {
    final licence = await currentLicence;
    return licence?.availableFeatures ?? [];
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
        logger.info('User cancelled licence file selection');
        return null;
      }

      final file = File(result.files.single.path!);

      // Validate file size (max 1MB)
      final fileSize = await file.length();
      if (fileSize > 1024 * 1024) {
        throw FormatException('Licence file too large (max 1MB)');
      }

      final content = await file.readAsString();

      // Validate content is not empty
      if (content.trim().isEmpty) {
        throw FormatException('Licence file is empty');
      }

      // Parse and validate licence
      final importedLicence = Licence.fromLicenceFileContent(content);

      // Additional validation
      if (!importedLicence.isValid) {
        throw FormatException('Licence is expired or invalid');
      }

      // Save the licence
      final saved = await saveLicence(importedLicence);
      if (!saved) {
        throw Exception('Failed to save imported licence');
      }

      logger.info('Licence imported successfully: ${importedLicence.email}');
      return importedLicence;
    } catch (e, stackTrace) {
      logger.severe('Error importing licence from file', e, stackTrace);

      if (e is FormatException) {
        rethrow;
      }

      throw Exception('Could not import licence: $e');
    }
  }

  /// Create a demo licence for testing
  Future<Licence?> createDemoLicence() async {
    try {
      final demoLicence = Licence.createDemo();
      final saved = await saveLicence(demoLicence);

      if (saved) {
        logger.info('Demo licence created: ${demoLicence.email}');
        return demoLicence;
      } else {
        logger.warning('Failed to save demo licence');
        return null;
      }
    } catch (e, stackTrace) {
      logger.severe('Error creating demo licence', e, stackTrace);
      return null;
    }
  }

  /// Validate licence integrity
  Future<bool> validateLicenceIntegrity() async {
    final licence = await currentLicence;
    if (licence == null) return false;

    try {
      // Check if stored hash matches current hash
      final storedHash = _prefs?.getString(_licenceHashKey);
      final currentHash = licence.generateHash();

      if (storedHash != null && storedHash != currentHash) {
        logger.warning('Licence integrity check failed');
        return false;
      }

      return true;
    } catch (e) {
      logger.severe('Error validating licence integrity: $e');
      return false;
    }
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
      };
    }

    return {
      'hasLicence': true,
      'isValid': licence.isValid,
      'expiresSoon': licence.expiresSoon,
      'daysRemaining': licence.daysRemaining,
      'features': licence.availableFeatures,
      'email': licence.email,
      'validUntil': licence.validUntil.toIso8601String(),
      'customerId': licence.customerId,
      'version': licence.version,
    };
  }

  /// Clear all licence data (for testing or reset)
  Future<void> clearAllData() async {
    await _initPrefs();

    try {
      await _prefs?.clear();
      _currentLicence = null;
      _isInitialized = false;
      logger.info('All licence data cleared');
    } catch (e, stackTrace) {
      logger.severe('Error clearing licence data', e, stackTrace);
    }
  }
}
