import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/db/drift_database_helper.dart';
import 'package:teleferika/db/models/image_model.dart';

/// Full-app backup / restore for migrating data across installs
/// (e.g. Play Store build → locally signed debug on the same device).
///
/// Archive layout (`teleferika_backup_*.zip`):
/// - `manifest.json`
/// - `data/Teleferika.db`
/// - `data/point_photos/...`
/// - `preferences.json`
class AppBackupService {
  AppBackupService._();
  static final AppBackupService instance = AppBackupService._();

  static const int formatVersion = 1;
  /// Must stay in sync with [TeleferikaDatabase.schemaVersion].
  static const int dbSchemaVersion = 8;
  static const String _dbFileName = 'Teleferika.db';
  static const String _photosDirName = 'point_photos';
  static const String _manifestName = 'manifest.json';
  static const String _prefsName = 'preferences.json';

  final Logger _logger = Logger('AppBackupService');

  /// Keys that are part of app state (settings, map, BLE/NTRIP UX, licence).
  static const Set<String> preferenceKeys = {
    'show_save_icon_always',
    'angle_to_red_threshold',
    'show_all_projects_on_map',
    'show_ble_satellite_button',
    'map_type',
    'last_location_lat',
    'last_location_lng',
    'last_location_timestamp',
    'app_licence',
    'device_fingerprint',
    'lastConnectedBleDeviceId',
    'lastUsedNtripHostId',
    'ntrip_last_selected_country',
    'ntrip_country_history',
  };

  /// Build a zip backup and present it via the system share sheet
  /// (and Downloads on Android when possible).
  Future<AppBackupExportResult> exportBackup() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, _dbFileName));
    final photosDir = Directory(p.join(docsDir.path, _photosDirName));

    await DriftDatabaseHelper.instance.close();

    try {
      final archive = Archive();
      final packageInfo = await PackageInfo.fromPlatform();
      final createdAt = DateTime.now().toUtc();

      final manifest = <String, dynamic>{
        'formatVersion': formatVersion,
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'dbSchemaVersion': dbSchemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'documentsPathMarker': _photosDirName,
      };
      final manifestBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(manifest),
      );
      archive.addFile(
        ArchiveFile(_manifestName, manifestBytes.length, manifestBytes),
      );

      if (!await dbFile.exists()) {
        throw StateError('Database file not found at ${dbFile.path}');
      }
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(
        ArchiveFile('data/$_dbFileName', dbBytes.length, dbBytes),
      );

      if (await photosDir.exists()) {
        await for (final entity in photosDir.list(recursive: true)) {
          if (entity is! File) continue;
          final relative = p.relative(entity.path, from: docsDir.path);
          final bytes = await entity.readAsBytes();
          archive.addFile(
            ArchiveFile('data/$relative', bytes.length, bytes),
          );
        }
      }

      final prefsPayload = await _exportPreferences();
      final prefsBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(prefsPayload),
      );
      archive.addFile(
        ArchiveFile(_prefsName, prefsBytes.length, prefsBytes),
      );

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes.isEmpty) {
        throw StateError('Failed to encode backup zip');
      }

      final stamp = _formatStamp(createdAt.toLocal());
      final fileName = 'teleferika_backup_$stamp.zip';

      final savedPath = await _writeAndShareBackup(
        Uint8List.fromList(zipBytes),
        fileName,
      );

      _logger.info('Backup exported: $savedPath');
      return AppBackupExportResult(fileName: fileName, savedPath: savedPath);
    } finally {
      // Re-open lazily on next DB access.
    }
  }

  /// Pick a backup zip and replace local app data.
  /// Caller should restart the app after a successful import.
  Future<AppBackupImportResult> importBackup() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    final path = picked?.path;
    if (path == null) {
      return const AppBackupImportResult.cancelled();
    }

    return importBackupFromFile(File(path));
  }

  /// Import from an already-selected zip [file].
  Future<AppBackupImportResult> importBackupFromFile(File file) async {
    if (!await file.exists()) {
      throw StateError('Backup file does not exist: ${file.path}');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile(_manifestName);
    if (manifestFile == null) {
      throw StateError('Invalid backup: missing $_manifestName');
    }
    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
    final version = manifest['formatVersion'] as int? ?? 0;
    if (version != formatVersion) {
      throw StateError(
        'Unsupported backup format version $version (expected $formatVersion)',
      );
    }

    final dbEntry = archive.findFile('data/$_dbFileName');
    if (dbEntry == null) {
      throw StateError('Invalid backup: missing data/$_dbFileName');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbFileName);
    final photosPath = p.join(docsDir.path, _photosDirName);

    await DriftDatabaseHelper.instance.close();

    // Replace database
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    await dbFile.writeAsBytes(dbEntry.content as List<int>, flush: true);

    // Replace photos
    final photosDir = Directory(photosPath);
    if (await photosDir.exists()) {
      await photosDir.delete(recursive: true);
    }
    await photosDir.create(recursive: true);

    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final name = entry.name.replaceAll('\\', '/');
      if (!name.startsWith('data/$_photosDirName/')) continue;
      final relative = name.substring('data/'.length);
      final outFile = File(p.join(docsDir.path, relative));
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(entry.content as List<int>, flush: true);
    }

    await _rewriteImagePaths(docsDir.path);

    final prefsEntry = archive.findFile(_prefsName);
    if (prefsEntry != null) {
      final prefsJson =
          jsonDecode(utf8.decode(prefsEntry.content as List<int>))
              as Map<String, dynamic>;
      await _importPreferences(prefsJson);
    }

    _logger.info('Backup imported from ${file.path}');
    return AppBackupImportResult.success(
      appVersion: manifest['appVersion']?.toString(),
      createdAt: manifest['createdAt']?.toString(),
    );
  }

  Future<void> _rewriteImagePaths(String docsDirPath) async {
    final db = await DriftDatabaseHelper.instance.database;
    final rows = await db.select(db.images).get();
    for (final row in rows) {
      final rewritten = _rewritePathToDocuments(row.imagePath, docsDirPath);
      if (rewritten == row.imagePath) continue;
      await DriftDatabaseHelper.instance.updateImage(
        ImageModel(
          id: row.id,
          pointId: row.pointId,
          ordinalNumber: row.ordinalNumber,
          imagePath: rewritten,
          note: row.note,
        ),
      );
    }
  }

  String _rewritePathToDocuments(String oldPath, String docsDirPath) {
    final normalized = oldPath.replaceAll('\\', '/');
    final marker = '/$_photosDirName/';
    final idx = normalized.indexOf(marker);
    if (idx >= 0) {
      final relative = normalized.substring(idx + 1); // point_photos/...
      return p.join(docsDirPath, relative);
    }
    if (normalized.startsWith('$_photosDirName/')) {
      return p.join(docsDirPath, normalized);
    }
    return oldPath;
  }

  Future<Map<String, dynamic>> _exportPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final bools = <String, bool>{};
    final ints = <String, int>{};
    final doubles = <String, double>{};
    final strings = <String, String>{};
    final stringLists = <String, List<String>>{};

    for (final key in preferenceKeys) {
      if (!prefs.containsKey(key)) continue;
      final value = prefs.get(key);
      if (value is bool) {
        bools[key] = value;
      } else if (value is int) {
        ints[key] = value;
      } else if (value is double) {
        doubles[key] = value;
      } else if (value is String) {
        strings[key] = value;
      } else if (value is List<String>) {
        stringLists[key] = value;
      }
    }

    return {
      'bool': bools,
      'int': ints,
      'double': doubles,
      'string': strings,
      'stringList': stringLists,
    };
  }

  Future<void> _importPreferences(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();

    final bools = (payload['bool'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final e in bools.entries) {
      if (e.value is bool) await prefs.setBool(e.key, e.value as bool);
    }

    final ints = (payload['int'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final e in ints.entries) {
      if (e.value is int) {
        await prefs.setInt(e.key, e.value as int);
      } else if (e.value is num) {
        await prefs.setInt(e.key, (e.value as num).toInt());
      }
    }

    final doubles = (payload['double'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final e in doubles.entries) {
      if (e.value is num) {
        await prefs.setDouble(e.key, (e.value as num).toDouble());
      }
    }

    final strings = (payload['string'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final e in strings.entries) {
      if (e.value is String) await prefs.setString(e.key, e.value as String);
    }

    final stringLists =
        (payload['stringList'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final e in stringLists.entries) {
      final list = e.value;
      if (list is List) {
        await prefs.setStringList(
          e.key,
          list.map((item) => item.toString()).toList(),
        );
      }
    }
  }

  Future<String> _writeAndShareBackup(
    Uint8List zipBytes,
    String fileName,
  ) async {
    String? primaryPath;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloads = Directory('/storage/emulated/0/Download');
        if (await downloads.exists()) {
          final out = File(p.join(downloads.path, fileName));
          await out.writeAsBytes(zipBytes, flush: true);
          primaryPath = out.path;
        }
      } catch (e, st) {
        _logger.warning('Could not write backup to Downloads', e, st);
      }
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, fileName));
    await tempFile.writeAsBytes(zipBytes, flush: true);
    primaryPath ??= tempFile.path;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(primaryPath, mimeType: 'application/zip')],
        text: 'Teleferika backup: $fileName',
        subject: 'Teleferika Backup',
      ),
    );

    return primaryPath;
  }

  String _formatStamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}_'
        '${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }
}

class AppBackupExportResult {
  final String fileName;
  final String savedPath;

  const AppBackupExportResult({
    required this.fileName,
    required this.savedPath,
  });
}

class AppBackupImportResult {
  final bool cancelled;
  final bool ok;
  final String? appVersion;
  final String? createdAt;

  const AppBackupImportResult._({
    required this.cancelled,
    required this.ok,
    this.appVersion,
    this.createdAt,
  });

  const AppBackupImportResult.cancelled()
    : this._(cancelled: true, ok: false);

  const AppBackupImportResult.success({
    String? appVersion,
    String? createdAt,
  }) : this._(
         cancelled: false,
         ok: true,
         appVersion: appVersion,
         createdAt: createdAt,
       );
}
