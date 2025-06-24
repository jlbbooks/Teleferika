// lib/utils/export_utils.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart'; // For saving locally
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // For storage permissions
import 'package:share_plus/share_plus.dart'; // For sharing
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

import '../logger.dart'; // Assuming you have a logger

enum ExportFormat {
  kml,
  csv,
  // Add more formats here in the future
}

extension ExportFormatExtension on ExportFormat {
  String get name {
    switch (this) {
      case ExportFormat.kml:
        return 'KML';
      case ExportFormat.csv:
        return 'CSV';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.kml:
        return 'kml';
      case ExportFormat.csv:
        return 'csv';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.kml:
        return 'application/vnd.google-earth.kml+xml';
      case ExportFormat.csv:
        return 'text/csv';
    }
  }
}

abstract class ExportStrategy {
  Future<String> generateContent(ProjectModel project, List<PointModel> points);
  ExportFormat get format;
}

// --- KML Export Strategy ---
class KmlExportStrategy implements ExportStrategy {
  @override
  ExportFormat get format => ExportFormat.kml;

  @override
  Future<String> generateContent(
    ProjectModel project,
    List<PointModel> points,
  ) async {
    StringBuffer kml = StringBuffer();
    kml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    kml.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    kml.writeln('  <Document>');
    kml.writeln('    <name>${_escapeXml(project.name)}</name>');
    if (project.note != null && project.note!.isNotEmpty) {
      kml.writeln(
        '    <description>${_escapeXml(project.note!)}</description>',
      );
    }

    // Project Details as a Placemark (optional, could be in description)
    kml.writeln('    <Placemark>');
    kml.writeln(
      '      <name>Project Details: ${_escapeXml(project.name)}</name>',
    );
    kml.writeln('      <description><![CDATA[');
    kml.writeln('        Project ID: ${project.id}');
    kml.writeln('        Date: ${project.date?.toIso8601String() ?? 'N/A'}');
    kml.writeln('        Azimuth: ${project.azimuth ?? 'N/A'}');
    // Add any other project details you want here
    kml.writeln('      ]]></description>');
    // No geometry for this meta-placemark
    kml.writeln('    </Placemark>');

    // Points
    for (var point in points) {
      kml.writeln('    <Placemark>');
      kml.writeln('      <name>P${point.ordinalNumber}</name>');
      kml.writeln('      <description><![CDATA[');
      kml.writeln('        Point ID: ${point.id}');
      kml.writeln('        Ordinal: ${point.ordinalNumber}');
      kml.writeln('        Latitude: ${point.latitude}');
      kml.writeln('        Longitude: ${point.longitude}');
      if (point.altitude != null) {
        kml.writeln('        Altitude: ${point.altitude} m');
      }
      if (point.heading != null) {
        kml.writeln('        Heading: ${point.heading?.toStringAsFixed(2)}°');
      }
      if (point.timestamp != null) {
        kml.writeln('        Timestamp: ${point.timestamp?.toIso8601String()}');
      }
      if (point.note != null && point.note!.isNotEmpty) {
        kml.writeln('        Note: ${_escapeXml(point.note!)}');
      }
      kml.writeln('      ]]></description>');
      kml.writeln('      <Point>');
      kml.write('        <coordinates>${point.longitude},${point.latitude}');
      if (point.altitude != null) {
        kml.write(',${point.altitude}');
      }
      kml.writeln('</coordinates>');
      kml.writeln('      </Point>');
      kml.writeln('    </Placemark>');
    }

    // Connecting Lines (Path)
    if (points.length > 1) {
      kml.writeln('    <Placemark>');
      kml.writeln(
        '      <name>Project Path: ${_escapeXml(project.name)}</name>',
      );
      kml.writeln('      <LineString>');
      kml.writeln('        <tessellate>1</tessellate>'); // Draw line on terrain
      kml.writeln('        <coordinates>');
      for (var point in points) {
        kml.write('          ${point.longitude},${point.latitude}');
        if (point.altitude != null) {
          kml.write(',${point.altitude}');
        }
        kml.writeln(); // Newline for each coordinate tuple
      }
      kml.writeln('        </coordinates>');
      kml.writeln('      </LineString>');
      // Style for the line (optional)
      kml.writeln('      <Style>');
      kml.writeln('        <LineStyle>');
      kml.writeln(
        '          <color>ff007eff</color>',
      ); // KML color is aabbggrr (blue)
      kml.writeln('          <width>2</width>');
      kml.writeln('        </LineStyle>');
      kml.writeln('      </Style>');
      kml.writeln('    </Placemark>');
    }

    kml.writeln('  </Document>');
    kml.writeln('</kml>');
    return kml.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

// --- CSV Export Strategy ---
class CsvExportStrategy implements ExportStrategy {
  @override
  ExportFormat get format => ExportFormat.csv;

  @override
  Future<String> generateContent(
    ProjectModel project,
    List<PointModel> points,
  ) async {
    StringBuffer csv = StringBuffer();

    // Header for Project Details (optional, can be separate or embedded)
    csv.writeln('Project Detail,Value');
    csv.writeln('Project Name,"${_escapeCsv(project.name)}"');
    csv.writeln('Project ID,"${project.id}"');
    csv.writeln('Project Note,"${_escapeCsv(project.note ?? '')}"');
    csv.writeln('Project Date,"${project.date?.toIso8601String() ?? ''}"');
    csv.writeln('Project Azimuth,"${project.azimuth?.toString() ?? ''}"');
    csv.writeln(''); // Blank line separator

    // Header for Points
    List<String> pointHeaders = [
      'Point ID',
      'Point Ordinal',
      'Latitude',
      'Longitude',
      'Altitude (m)',
      'Heading (deg)',
      'Timestamp',
      'Note',
    ];
    csv.writeln(pointHeaders.map((h) => '"${_escapeCsv(h)}"').join(','));

    // Point Data
    for (var point in points) {
      List<String?> pointData = [
        point.id,
        point.ordinalNumber.toString(),
        point.latitude.toString(),
        point.longitude.toString(),
        point.altitude?.toString(),
        point.heading?.toStringAsFixed(2),
        point.timestamp?.toIso8601String(),
        point.note,
      ];
      csv.writeln(pointData.map((d) => '"${_escapeCsv(d ?? '')}"').join(','));
    }
    return csv.toString();
  }

  String _escapeCsv(String text) {
    if (text.contains('"') || text.contains(',') || text.contains('\n')) {
      return text.replaceAll(
        '"',
        '""',
      ); // Escape double quotes by doubling them
    }
    return text;
  }
}

// --- Export Service to handle file operations ---
class ExportService {
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      PermissionStatus status;

      if (sdkInt >= 33) {
        // Android 13+
        // For Android 13+, traditional READ/WRITE_EXTERNAL_STORAGE are largely ineffective
        // for typical apps.
        // FilePicker.saveFile() uses Storage Access Framework (SAF), which doesn't
        // require these permissions for the user to select a location and for the app to write to it.
        // Share.shareXFiles() writes to a temporary cache location, usually app-specific or
        // a shared cache that doesn't require explicit broad storage permissions.

        // So, for saving general files (KML, CSV) using SAF, no explicit permission request
        // might be strictly needed here *for the save operation itself*.
        // However, if any underlying mechanism of file_picker or share_plus *still* checks
        // for manifest declarations or attempts to use older storage APIs as fallbacks
        // (less likely with modern plugin versions but possible), having some declaration
        // might prevent crashes, even if the runtime request for Permission.storage is denied.

        // The most robust way for general file system access if needed is MANAGE_EXTERNAL_STORAGE,
        // but this is a high-risk permission and generally NOT recommended or needed for this use case.
        logger.info(
          "Running on Android SDK $sdkInt (Android 13+). "
          "Storage permissions handled primarily by Storage Access Framework for saving. "
          "No explicit broad storage permission typically requested or granted for general file saving.",
        );
        return true; // Assume success as SAF will handle user interaction for saving.
        // Share should also work with its cache without this specific permission.
      } else if (sdkInt >= 30) {
        // Android 11 and 12
        // On Android 11 & 12, Scoped Storage is fully enforced.
        // While Permission.storage can be requested, its utility for accessing arbitrary
        // file paths is limited without MANAGE_EXTERNAL_STORAGE (which we want to avoid).
        // FilePicker.saveFile() with SAF is still the best approach.
        // Share_plus will use its cache.
        // We can still try to request Permission.storage as plugins might use it for specific cache access.
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        logger.info("Android SDK $sdkInt: Storage permission status: $status");
        // If denied, FilePicker and Share should still largely function via SAF / app cache.
        return status.isGranted ||
            status.isLimited; // isLimited is also acceptable for some cases
      } else {
        // Android 10 (SDK 29) and below
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        if (status.isPermanentlyDenied) {
          logger.warning(
            "Storage permission permanently denied on Android SDK $sdkInt.",
          );
          // Optionally, guide user to app settings:
          // await openAppSettings();
          return false;
        }
        logger.info("Android SDK $sdkInt: Storage permission status: $status");
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // On iOS, saving to files app or sharing doesn't typically require explicit
      // "storage" permission in the same way Android does. It's handled by UIDocumentPicker
      // or UIActivityViewController.
      // However, if you were saving to Photos library, Permission.photos would be needed.
      logger.info(
        "Running on iOS. Storage permissions handled by OS pickers/share sheets.",
      );
      return true;
    }
    // For other platforms (Desktop, Web)
    logger.info(
      "Running on ${Platform.operatingSystem}. Assuming file access is generally available or handled by system dialogs.",
    );
    return true;
  }

  /// Saves the given string [content] as a file on mobile (Android/iOS).
  ///
  /// Returns `true` if the file save operation was initiated successfully by the user,
  /// `false` otherwise (e.g., user cancelled, permission issues on older Android, or other errors).
  Future<bool> _saveFile(
    String content,
    String fileName,
    ExportFormat format,
  ) async {
    if (!await _requestStoragePermission()) {
      logger.warning(
        "Storage permission not adequately granted. File saving will likely fail (especially on older Android).",
      );
      // On older Android, if permissions were denied, it's a clear failure point.
      // On Android 13+, _requestStoragePermission should return true as SAF handles it.
      // If _requestStoragePermission itself has an issue and returns false, then fail.
      return false;
    }

    try {
      final Uint8List fileBytes = utf8.encode(content);

      // Use file_picker to let the user choose the save location.
      // On mobile, providing 'bytes' means file_picker handles the actual write.
      String? outputFileUriString = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${format.name} File As...',
        fileName: fileName,
        allowedExtensions: (format.fileExtension.isNotEmpty)
            ? [format.fileExtension]
            : null,
        type: FileType.custom,
        bytes: fileBytes, // Pass bytes directly for Android/iOS
      );

      if (outputFileUriString != null) {
        // If outputFileUriString is not null, it means the user completed the
        // save dialog and the platform (via file_picker) initiated the save.
        logger.info(
          "File save initiated successfully via system picker. Output URI/path: $outputFileUriString",
        );
        return true;
      } else {
        // User cancelled the file picker dialog.
        logger.info("User cancelled file saving.");
        return false;
      }
    } catch (e, s) {
      logger.severe("Error during _saveFile operation: $e\nStacktrace: $s");
      return false;
    }
  }

  Future<void> exportAndShare(
    ProjectModel project,
    List<PointModel> points,
    ExportStrategy strategy,
  ) async {
    try {
      final content = await strategy.generateContent(project, points);
      final fileName =
          '${_sanitizeFileName(project.name)}_${strategy.format.name.toLowerCase()}.${strategy.format.fileExtension}';

      // Share directly
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(content);

      logger.info("Sharing file: ${file.path}");
      await Share.shareXFiles([
        XFile(file.path, mimeType: strategy.format.mimeType),
      ], subject: 'Exported Data: ${project.name} (${strategy.format.name})');
    } catch (e) {
      logger.severe("Error during export and share: $e");
      // Handle error (e.g., show a SnackBar)
    }
  }

  Future<bool> exportAndSave(
    ProjectModel project,
    List<PointModel> points,
    ExportStrategy strategy,
  ) async {
    final content = await strategy.generateContent(project, points);
    final fileName =
        '${_sanitizeFileName(project.name)}_${strategy.format.name.toLowerCase()}.${strategy.format.fileExtension}';
    return await _saveFile(content, fileName, strategy.format);
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s.-]'), '_').replaceAll(' ', '_');
  }
}
