import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';

/// Unified licence model with comprehensive validation, device fingerprinting, and status tracking
class Licence {
  static final Logger _logger = Logger('Licence');

  /// License status constants
  static const String statusActive = 'active';
  static const String statusExpired = 'expired';
  static const String statusRevoked = 'revoked';
  static const String statusRequested = 'requested';
  static const String statusDenied = 'denied';
  static const String statusDevelopment = 'development';

  /// Check if a status requires server validation
  static bool requiresServerValidation(String status) {
    return status != statusDevelopment;
  }

  final String email;
  final String customerId;
  final String deviceFingerprint;
  final DateTime issuedAt;
  final DateTime validUntil;
  final List<String> features;
  final int maxDevices;
  final String version;
  final String signature;
  final String algorithm;
  final String status; // 'active', 'expired', 'revoked'
  final DateTime? revokedAt;
  final String? revokedReason;
  final int usageCount;
  final DateTime lastUsed;

  const Licence({
    required this.email,
    required this.customerId,
    required this.deviceFingerprint,
    required this.issuedAt,
    required this.validUntil,
    required this.features,
    required this.maxDevices,
    required this.version,
    required this.signature,
    required this.algorithm,
    required this.status,
    this.revokedAt,
    this.revokedReason,
    required this.usageCount,
    required this.lastUsed,
  });

  /// Create licence from JSON data (client-side format)
  factory Licence.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both server format (flat) and client format (nested data)
      Map<String, dynamic> data;
      String signature;
      String algorithm;

      if (json.containsKey('data')) {
        // Client format: nested data with separate signature
        data = json['data'] as Map<String, dynamic>;
        signature = json['signature'] as String;
        algorithm = json['algorithm'] as String;
      } else {
        // Server format: flat structure
        data = json;
        signature = json['signature'] as String;
        algorithm = json['algorithm'] as String;
      }

      return Licence(
        email: data['email'] as String,
        customerId: data['customerId'] as String,
        deviceFingerprint: data['deviceFingerprint'] as String,
        issuedAt: DateTime.parse(data['issuedAt'] as String),
        validUntil: DateTime.parse(data['validUntil'] as String),
        features: (data['features'] as List<dynamic>).cast<String>(),
        maxDevices: data['maxDevices'] as int,
        version: data['version'] as String,
        signature: signature,
        algorithm: algorithm,
        status: data['status'] as String? ?? 'active',
        revokedAt: data['revokedAt'] != null
            ? DateTime.parse(data['revokedAt'] as String)
            : null,
        revokedReason: data['revokedReason'] as String?,
        usageCount: data['usageCount'] as int? ?? 0,
        lastUsed: data['lastUsed'] != null
            ? DateTime.parse(data['lastUsed'] as String)
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.severe('Error parsing licence from JSON', e, stackTrace);
      rethrow;
    }
  }

  /// Convert licence to JSON (client-side format)
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'email': email,
        'customerId': customerId,
        'deviceFingerprint': deviceFingerprint,
        'issuedAt': issuedAt.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'features': features,
        'maxDevices': maxDevices,
        'version': version,
        'status': status,
        'revokedAt': revokedAt?.toIso8601String(),
        'revokedReason': revokedReason,
        'usageCount': usageCount,
        'lastUsed': lastUsed.toIso8601String(),
      },
      'signature': signature,
      'algorithm': algorithm,
    };
  }

  /// Convert licence to server JSON format (flat structure)
  Map<String, dynamic> toServerJson() {
    return {
      'email': email,
      'customerId': customerId,
      'deviceFingerprint': deviceFingerprint,
      'issuedAt': issuedAt.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'features': features,
      'maxDevices': maxDevices,
      'version': version,
      'signature': signature,
      'algorithm': algorithm,
      'status': status,
      'revokedAt': revokedAt?.toIso8601String(),
      'revokedReason': revokedReason,
      'usageCount': usageCount,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  /// Check if licence is currently valid
  bool get isValid {
    // Development licenses are always considered valid
    if (status == statusDevelopment) return true;

    // Only active licenses are valid
    if (status != statusActive) return false;

    return DateTime.now().isBefore(validUntil);
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

  /// Check if a specific feature is included
  bool hasFeature(String featureName) {
    return features.contains(featureName);
  }

  /// Get all available features
  List<String> get availableFeatures => List.unmodifiable(features);

  /// Get the licence data as a JSON string for signing
  String get dataForSigning {
    final data = {
      'email': email,
      'customerId': customerId,
      'deviceFingerprint': deviceFingerprint,
      'issuedAt': issuedAt.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'features': features,
      'maxDevices': maxDevices,
      'version': version,
    };
    return jsonEncode(data);
  }

  /// Generate hash of licence data for integrity checking
  String generateDataHash() {
    final dataString = dataForSigning;
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate device fingerprint
  Future<bool> validateDeviceFingerprint() async {
    return await DeviceFingerprint.validateFingerprint(deviceFingerprint);
  }

  /// Create a copy with updated fields
  Licence copyWith({
    String? email,
    String? customerId,
    String? deviceFingerprint,
    DateTime? issuedAt,
    DateTime? validUntil,
    List<String>? features,
    int? maxDevices,
    String? version,
    String? signature,
    String? algorithm,
    String? status,
    DateTime? revokedAt,
    String? revokedReason,
    int? usageCount,
    DateTime? lastUsed,
  }) {
    return Licence(
      email: email ?? this.email,
      customerId: customerId ?? this.customerId,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      issuedAt: issuedAt ?? this.issuedAt,
      validUntil: validUntil ?? this.validUntil,
      features: features ?? this.features,
      maxDevices: maxDevices ?? this.maxDevices,
      version: version ?? this.version,
      signature: signature ?? this.signature,
      algorithm: algorithm ?? this.algorithm,
      status: status ?? this.status,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedReason: revokedReason ?? this.revokedReason,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Create a copy with updated usage statistics
  Licence withUsageUpdate() {
    return copyWith(usageCount: usageCount + 1, lastUsed: DateTime.now());
  }

  /// Create a revoked copy
  Licence withRevocation({required String reason}) {
    return copyWith(
      status: 'revoked',
      revokedAt: DateTime.now(),
      revokedReason: reason,
    );
  }

  @override
  String toString() {
    return 'Licence(email: $email, status: $status, validUntil: ${validUntil.toLocal()}, isValid: $isValid, features: $features)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Licence &&
        other.email == email &&
        other.deviceFingerprint == deviceFingerprint &&
        other.validUntil == validUntil &&
        other.signature == signature;
  }

  @override
  int get hashCode {
    return Object.hash(email, deviceFingerprint, validUntil, signature);
  }
}

/// Error class for licence validation failures
class LicenceError extends Error {
  final String code;
  final String userMessage;
  final String? technicalDetails;

  LicenceError({
    required this.code,
    required this.userMessage,
    this.technicalDetails,
  });

  @override
  String toString() {
    return 'LicenceError(code: $code, message: $userMessage${technicalDetails != null ? ', details: $technicalDetails' : ''})';
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
