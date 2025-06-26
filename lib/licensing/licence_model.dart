// lib/models/licence_model.dart
import 'dart:convert';
import 'dart:math';

import '../logger.dart'; // For @required if using older Flutter, or just for clarity

/// Represents a software licence with validation and security features
class Licence {
  final String email;
  final int maxDays;
  final DateTime validUntil;
  final DateTime? importedDate;
  final String? licenceKey;
  final List<String> features;
  final String? customerId;
  final String? version;

  Licence({
    required this.email,
    required this.maxDays,
    required this.validUntil,
    this.importedDate,
    this.licenceKey,
    this.features = const [],
    this.customerId,
    this.version,
  }) {
    _validateEmail(email);
    _validateMaxDays(maxDays);
  }

  /// Validate email format
  static void _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      throw FormatException('Invalid email format: $email');
    }
  }

  /// Validate max days
  static void _validateMaxDays(int maxDays) {
    if (maxDays <= 0) {
      throw FormatException('Max days must be positive: $maxDays');
    }
    if (maxDays > 36500) { // 100 years
      throw FormatException('Max days cannot exceed 36500: $maxDays');
    }
  }

  /// Check if the licence is currently valid
  bool get isValid {
    final now = DateTime.now();
    
    // Check if current date is before or same as validUntil
    if (now.isAfter(validUntil)) {
      return false;
    }
    
    // Check if importedDate + maxDays hasn't expired
    if (importedDate != null) {
      final maxExpiryDate = importedDate!.add(Duration(days: maxDays));
      if (now.isAfter(maxExpiryDate)) {
        return false;
      }
    }
    
    return true;
  }

  /// Check if licence expires soon (within 30 days)
  bool get expiresSoon {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    return validUntil.isBefore(thirtyDaysFromNow);
  }

  /// Get days remaining until expiry
  int get daysRemaining {
    final now = DateTime.now();
    return validUntil.difference(now).inDays;
  }

  /// Check if a specific feature is included in this licence
  bool hasFeature(String featureName) {
    return features.contains(featureName);
  }

  /// Get all features included in this licence
  List<String> get availableFeatures => List.unmodifiable(features);

  /// Generate a simple hash for licence validation
  String generateHash() {
    final data = '$email$maxDays${validUntil.toIso8601String()}';
    return _simpleHash(data);
  }

  /// Simple hash function for basic validation
  static String _simpleHash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      final char = input.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs().toString();
  }

  /// Convert Licence to a Map (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'maxDays': maxDays,
      'validUntil': validUntil.toIso8601String(),
      'importedDate': importedDate?.toIso8601String(),
      'licenceKey': licenceKey,
      'features': features,
      'customerId': customerId,
      'version': version,
      'hash': generateHash(), // Include hash for validation
    };
  }

  /// Create Licence from a Map (from SharedPreferences)
  factory Licence.fromJson(Map<String, dynamic> json) {
    try {
      final licence = Licence(
        email: json['email'] as String,
        maxDays: json['maxDays'] is int
            ? json['maxDays'] as int
            : int.parse(json['maxDays'].toString()),
        validUntil: DateTime.parse(json['validUntil'] as String),
        importedDate: json['importedDate'] != null
            ? DateTime.parse(json['importedDate'] as String)
            : null,
        licenceKey: json['licenceKey'] as String?,
        features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
        customerId: json['customerId'] as String?,
        version: json['version'] as String?,
      );

      // Validate hash if present
      final storedHash = json['hash'] as String?;
      if (storedHash != null && storedHash != licence.generateHash()) {
        throw FormatException('Licence hash validation failed');
      }

      return licence;
    } catch (e) {
      logger.severe('Error parsing licence from JSON: $e');
      rethrow;
    }
  }

  /// Create Licence from a licence file content
  factory Licence.fromLicenceFileContent(String fileContent) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(fileContent) as Map<String, dynamic>;
      
      // Validate required fields
      final requiredFields = ['email', 'maxDays', 'validUntil'];
      for (final field in requiredFields) {
        if (!jsonMap.containsKey(field)) {
          throw FormatException('Licence file missing required field: $field');
        }
      }

      // Parse and validate email
      final email = jsonMap['email'] as String;
      _validateEmail(email);

      // Parse and validate maxDays
      final maxDays = jsonMap['maxDays'] is int
          ? jsonMap['maxDays'] as int
          : int.parse(jsonMap['maxDays'].toString());
      _validateMaxDays(maxDays);

      // Parse and validate validUntil
      final validUntil = DateTime.parse(jsonMap['validUntil'] as String);
      if (validUntil.isBefore(DateTime.now())) {
        throw FormatException('Licence expiry date is in the past');
      }

      return Licence(
        email: email,
        maxDays: maxDays,
        validUntil: validUntil,
        importedDate: DateTime.now(),
        licenceKey: jsonMap['licenceKey'] as String?,
        features: (jsonMap['features'] as List<dynamic>?)?.cast<String>() ?? [],
        customerId: jsonMap['customerId'] as String?,
        version: jsonMap['version'] as String?,
      );
    } catch (e) {
      logger.severe('Error parsing licence file content: $e');
      if (e is FormatException) {
        rethrow;
      }
      throw FormatException('Invalid licence file format: $e');
    }
  }

  /// Create a demo licence for testing
  factory Licence.createDemo() {
    final now = DateTime.now();
    return Licence(
      email: 'demo@example.com',
      maxDays: 30,
      validUntil: now.add(const Duration(days: 30)),
      importedDate: now,
      features: ['export', 'advanced_mapping', 'cloud_sync'],
      customerId: 'DEMO001',
      version: '1.0.0',
    );
  }

  /// Create a copy of this licence with updated fields
  Licence copyWith({
    String? email,
    int? maxDays,
    DateTime? validUntil,
    DateTime? importedDate,
    String? licenceKey,
    List<String>? features,
    String? customerId,
    String? version,
  }) {
    return Licence(
      email: email ?? this.email,
      maxDays: maxDays ?? this.maxDays,
      validUntil: validUntil ?? this.validUntil,
      importedDate: importedDate ?? this.importedDate,
      licenceKey: licenceKey ?? this.licenceKey,
      features: features ?? this.features,
      customerId: customerId ?? this.customerId,
      version: version ?? this.version,
    );
  }

  @override
  String toString() {
    return 'Licence(email: $email, maxDays: $maxDays, validUntil: ${validUntil.toLocal()}, isValid: $isValid, features: $features)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Licence &&
        other.email == email &&
        other.maxDays == maxDays &&
        other.validUntil == validUntil &&
        other.licenceKey == licenceKey;
  }

  @override
  int get hashCode {
    return Object.hash(email, maxDays, validUntil, licenceKey);
  }
}
