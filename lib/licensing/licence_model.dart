// lib/models/licence_model.dart
import 'dart:convert';

import '../logger.dart'; // For @required if using older Flutter, or just for clarity

class Licence {
  final String email;
  final int
  maxDays; // Max duration of the licence in days from a reference point (e.g., purchase date)
  final DateTime validUntil; // Specific date until which the licence is valid
  final DateTime? importedDate; // When the licence file was imported

  Licence({
    required this.email,
    required this.maxDays,
    required this.validUntil,
    this.importedDate,
  });

  // Method to check if the licence is currently valid
  bool get isValid {
    final now = DateTime.now();
    // Check if current date is before or same as validUntil
    // And also consider importedDate if you want to limit based on maxDays from import
    // For simplicity, let's primarily focus on validUntil for now.
    // You could add logic: now.isBefore(importedDate.add(Duration(days: maxDays)))
    return now.isBefore(validUntil) || now.isAtSameMomentAs(validUntil);
  }

  // Convert Licence to a Map (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'maxDays': maxDays,
      'validUntil': validUntil
          .toIso8601String(), // Store dates as ISO8601 strings
      'importedDate': importedDate?.toIso8601String(),
    };
  }

  // Create Licence from a Map (from SharedPreferences)
  factory Licence.fromJson(Map<String, dynamic> json) {
    return Licence(
      email: json['email'] as String,
      maxDays: json['maxDays'] as int,
      validUntil: DateTime.parse(json['validUntil'] as String),
      importedDate: json['importedDate'] != null
          ? DateTime.parse(json['importedDate'] as String)
          : null,
    );
  }

  // Example: Create Licence from a simple licence file content (e.g., JSON string)
  // This is a placeholder; your actual licence file format might be different (e.g., encrypted, signed JWT)
  factory Licence.fromLicenceFileContent(String fileContent) {
    // Assuming the licence file is a simple JSON for this example
    // In a real app, this would be more complex and secure (e.g. parsing a signed JWT or encrypted data)
    try {
      final Map<String, dynamic> jsonMap =
          jsonDecode(fileContent) as Map<String, dynamic>;
      if (jsonMap.containsKey('email') &&
          jsonMap.containsKey('maxDays') &&
          jsonMap.containsKey('validUntil')) {
        return Licence(
          email: jsonMap['email'] as String,
          maxDays: jsonMap['maxDays'] is int
              ? jsonMap['maxDays'] as int
              : int.parse(jsonMap['maxDays'].toString()),
          validUntil: DateTime.parse(jsonMap['validUntil'] as String),
          importedDate:
              DateTime.now(), // Set importedDate when parsing from file
        );
      } else {
        throw const FormatException(
          "Licence file content is missing required fields.",
        );
      }
    } catch (e) {
      logger.severe("Error parsing licence file content: $e");
      throw FormatException("Invalid licence file format: $e");
    }
  }

  @override
  String toString() {
    return 'Licence(email: $email, maxDays: $maxDays, validUntil: ${validUntil.toLocal()}, isValid: $isValid, imported: $importedDate)';
  }
}
