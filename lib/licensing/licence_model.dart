import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';

/// Enhanced licence model with cryptographic validation and device fingerprinting
class EnhancedLicence {
  static final Logger _logger = Logger('EnhancedLicence');

  final String email;
  final String deviceFingerprint;
  final DateTime validUntil;
  final List<String> features;
  final String? customerId;
  final int maxDevices;
  final DateTime issuedAt;
  final String version;
  final String signature;
  final String algorithm;

  const EnhancedLicence({
    required this.email,
    required this.deviceFingerprint,
    required this.validUntil,
    required this.features,
    this.customerId,
    required this.maxDevices,
    required this.issuedAt,
    required this.version,
    required this.signature,
    required this.algorithm,
  });

  /// Create licence from JSON data
  factory EnhancedLicence.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'] as Map<String, dynamic>;

      return EnhancedLicence(
        email: data['email'] as String,
        deviceFingerprint: data['deviceFingerprint'] as String,
        validUntil: DateTime.parse(data['validUntil'] as String),
        features: (data['features'] as List<dynamic>).cast<String>(),
        customerId: data['customerId'] as String?,
        maxDevices: data['maxDevices'] as int,
        issuedAt: DateTime.parse(data['issuedAt'] as String),
        version: data['version'] as String,
        signature: json['signature'] as String,
        algorithm: json['algorithm'] as String,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error parsing enhanced licence from JSON', e, stackTrace);
      rethrow;
    }
  }

  /// Convert licence to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'email': email,
        'deviceFingerprint': deviceFingerprint,
        'validUntil': validUntil.toIso8601String(),
        'features': features,
        'customerId': customerId,
        'maxDevices': maxDevices,
        'issuedAt': issuedAt.toIso8601String(),
        'version': version,
      },
      'signature': signature,
      'algorithm': algorithm,
    };
  }

  /// Check if licence is currently valid
  bool get isValid {
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
      'deviceFingerprint': deviceFingerprint,
      'validUntil': validUntil.toIso8601String(),
      'features': features,
      'customerId': customerId,
      'maxDevices': maxDevices,
      'issuedAt': issuedAt.toIso8601String(),
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
  EnhancedLicence copyWith({
    String? email,
    String? deviceFingerprint,
    DateTime? validUntil,
    List<String>? features,
    String? customerId,
    int? maxDevices,
    DateTime? issuedAt,
    String? version,
    String? signature,
    String? algorithm,
  }) {
    return EnhancedLicence(
      email: email ?? this.email,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      validUntil: validUntil ?? this.validUntil,
      features: features ?? this.features,
      customerId: customerId ?? this.customerId,
      maxDevices: maxDevices ?? this.maxDevices,
      issuedAt: issuedAt ?? this.issuedAt,
      version: version ?? this.version,
      signature: signature ?? this.signature,
      algorithm: algorithm ?? this.algorithm,
    );
  }

  @override
  String toString() {
    return 'EnhancedLicence(email: $email, validUntil: ${validUntil.toLocal()}, isValid: $isValid, features: $features)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnhancedLicence &&
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
