// lib/services/licence_service.dart
import 'dart:convert'; // For jsonEncode/jsonDecode
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/logger.dart';

import 'licence_model.dart';

class LicenceService {
  static const String _licenceKey = 'app_licence_key';
  SharedPreferences? _prefs;

  Licence? _currentLicence;

  // Make it a singleton or provide via DI
  LicenceService._privateConstructor();
  static final LicenceService instance = LicenceService._privateConstructor();

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Licence?> loadLicence() async {
    if (_currentLicence != null) return _currentLicence;

    await _initPrefs();
    final String? licenceJson = _prefs?.getString(_licenceKey);
    if (licenceJson != null && licenceJson.isNotEmpty) {
      try {
        _currentLicence = Licence.fromJson(
          jsonDecode(licenceJson) as Map<String, dynamic>,
        );
        logger.info("Licence loaded: ${_currentLicence.toString()}");
        return _currentLicence;
      } catch (e) {
        logger.severe("Error decoding licence from SharedPreferences: $e");
        await removeLicence(); // Clear corrupted licence
        return null;
      }
    }
    logger.info("No licence found in SharedPreferences.");
    return null;
  }

  Future<bool> saveLicence(Licence licence) async {
    await _initPrefs();
    try {
      final String licenceJson = jsonEncode(licence.toJson());
      await _prefs?.setString(_licenceKey, licenceJson);
      _currentLicence = licence; // Update in-memory cache
      logger.info("Licence saved: ${licence.toString()}");
      return true;
    } catch (e) {
      logger.severe("Error saving licence to SharedPreferences: $e");
      return false;
    }
  }

  Future<void> removeLicence() async {
    await _initPrefs();
    await _prefs?.remove(_licenceKey);
    _currentLicence = null;
    logger.info("Licence removed from SharedPreferences.");
  }

  Future<Licence?> get currentLicence async {
    return _currentLicence ?? await loadLicence();
  }

  Future<bool> isLicenceValid() async {
    final licence = await currentLicence;
    return licence?.isValid ?? false;
  }

  /// Imports a licence from a user-selected file.
  /// Returns the imported Licence if successful, null otherwise.
  Future<Licence?> importLicenceFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'lic',
          'txt',
          'json',
        ], // Define your licence file extensions
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        // IMPORTANT: Add robust validation and error handling here
        // The Licence.fromLicenceFileContent should be secure if parsing signed/encrypted data.
        // For this example, it's parsing simple JSON.
        Licence importedLicence = Licence.fromLicenceFileContent(content);

        // Optionally, perform additional server-side validation here if needed

        bool saved = await saveLicence(importedLicence);
        if (saved) {
          logger.info(
            "Licence imported successfully: ${importedLicence.email}",
          );
          return importedLicence;
        } else {
          logger.warning("Failed to save the imported licence.");
          return null;
        }
      } else {
        logger.info("User cancelled licence file picking or no file selected.");
        return null;
      }
    } catch (e, s) {
      logger.severe("Error importing licence from file: $e\nStacktrace: $s");
      if (e is FormatException) {
        // Specific handling for format exception from parsing
        throw FormatException("Invalid licence file content: ${e.message}");
      }
      throw Exception("Could not import licence: $e"); // General exception
    }
  }
}
