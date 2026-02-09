# Enhanced Security & Validation Proposal

## Overview

This document outlines an enhanced security scheme for TeleferiKa licensing that uses asymmetric cryptography while maintaining excellent user experience.

## Proposed Security Scheme

### **Core Concept: Device-Bound Digital Signatures**

Instead of requiring users to manage private keys, we use **device fingerprinting** combined with **digital signatures** to create secure, tamper-proof licences.

### **Flow Diagram**

```
┌─────────────┐    Request Licence    ┌─────────────┐
│    User     │ ────────────────────► │ App Owner   │
│             │                       │             │
│ Device      │                       │ Private Key │
│ Fingerprint │                       │ (Licence    │
│ + Email     │                       │  Signer)    │
└─────────────┘                       └─────────────┘
         │                                     │
         │                                     │
         │                                     ▼
         │                            ┌─────────────┐
         │                            │   Licence   │
         │                            │ Generation  │
         │                            │             │
         │                            │ 1. Create   │
         │                            │    licence  │
         │                            │ 2. Add      │
         │                            │    device   │
         │                            │    fingerprint
         │                            │ 3. Sign     │
         │                            │    with     │
         │                            │    private  │
         │                            │    key      │
         │                            └─────────────┘
         │                                     │
         │                                     ▼
         │                            ┌─────────────┐
         │                            │ Signed      │
         │                            │ Licence     │
         │                            │ File        │
         │                            └─────────────┘
         │                                     │
         │                                     │
         ▼                                     │
┌─────────────┐    Import Licence     ┌─────────────┐
│    App      │ ◄──────────────────── │    User     │
│             │                       │             │
│ Public Key  │                       │             │
│ (Embedded)  │                       │             │
│             │                       │             │
│ Validation  │                       │             │
│ Logic       │                       │             │
└─────────────┘                       └─────────────┘
```

## Detailed Implementation

### **1. Device Fingerprinting**

```dart
class DeviceFingerprint {
  static Future<String> generate() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    String fingerprint = '';
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      fingerprint = _generateAndroidFingerprint(androidInfo, packageInfo);
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      fingerprint = _generateIOSFingerprint(iosInfo, packageInfo);
    }
    
    return _hashFingerprint(fingerprint);
  }
  
  static String _generateAndroidFingerprint(AndroidDeviceInfo info, PackageInfo packageInfo) {
    return [
      info.model,
      info.brand,
      info.device,
      info.product,
      info.fingerprint,
      packageInfo.packageName,
      packageInfo.version,
    ].join('|');
  }
  
  static String _generateIOSFingerprint(IosDeviceInfo info, PackageInfo packageInfo) {
    return [
      info.model,
      info.name,
      info.systemName,
      info.systemVersion,
      info.identifierForVendor,
      packageInfo.packageName,
      packageInfo.version,
    ].join('|');
  }
  
  static String _hashFingerprint(String fingerprint) {
    // Use SHA-256 for consistent, secure hashing
    final bytes = utf8.encode(fingerprint);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

### **2. Licence Generation (App Owner Side)**

```dart
class LicenceGenerator {
  static const String _privateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
-----END PRIVATE KEY-----
''';
  
  static String generateLicence({
    required String email,
    required String deviceFingerprint,
    required DateTime validUntil,
    required List<String> features,
    String? customerId,
    int maxDevices = 1,
  }) {
    // Create licence data
    final licenceData = {
      'email': email,
      'deviceFingerprint': deviceFingerprint,
      'validUntil': validUntil.toIso8601String(),
      'features': features,
      'customerId': customerId,
      'maxDevices': maxDevices,
      'issuedAt': DateTime.now().toIso8601String(),
      'version': '2.0',
    };
    
    // Convert to JSON
    final jsonData = jsonEncode(licenceData);
    
    // Sign the data
    final signature = _signData(jsonData);
    
    // Create final licence
    final licence = {
      'data': licenceData,
      'signature': signature,
      'algorithm': 'RSA-SHA256',
    };
    
    return jsonEncode(licence);
  }
  
  static String _signData(String data) {
    // Use RSA-SHA256 for signing
    final privateKey = _loadPrivateKey();
    final signer = RSASigner(privateKey);
    final signature = signer.sign(utf8.encode(data));
    return base64Encode(signature);
  }
  
  static RSAPrivateKey _loadPrivateKey() {
    // Load private key from PEM format
    // Implementation depends on crypto library used
    throw UnimplementedError('Implement private key loading');
  }
}
```

### **3. Licence Validation (App Side)**

```dart
class EnhancedLicenceValidator {
  static const String _publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----
''';
  
  static bool validateLicence(String licenceJson) {
    try {
      final licence = jsonDecode(licenceJson) as Map<String, dynamic>;
      
      // Extract components
      final data = licence['data'] as Map<String, dynamic>;
      final signature = licence['signature'] as String;
      final algorithm = licence['algorithm'] as String;
      
      // Validate algorithm
      if (algorithm != 'RSA-SHA256') {
        throw LicenceError(
          code: 'UNSUPPORTED_ALGORITHM',
          userMessage: 'Unsupported signature algorithm',
        );
      }
      
      // Verify signature
      final dataJson = jsonEncode(data);
      if (!_verifySignature(dataJson, signature)) {
        throw LicenceError(
          code: 'INVALID_SIGNATURE',
          userMessage: 'Licence signature is invalid',
        );
      }
      
      // Validate device fingerprint
      final currentFingerprint = await DeviceFingerprint.generate();
      final licenceFingerprint = data['deviceFingerprint'] as String;
      
      if (currentFingerprint != licenceFingerprint) {
        throw LicenceError(
          code: 'DEVICE_MISMATCH',
          userMessage: 'Licence is not valid for this device',
        );
      }
      
      // Validate expiry
      final validUntil = DateTime.parse(data['validUntil'] as String);
      if (DateTime.now().isAfter(validUntil)) {
        throw LicenceError(
          code: 'LICENCE_EXPIRED',
          userMessage: 'Licence has expired',
        );
      }
      
      return true;
    } catch (e) {
      if (e is LicenceError) rethrow;
      
      throw LicenceError(
        code: 'VALIDATION_FAILED',
        userMessage: 'Failed to validate licence',
        technicalDetails: e.toString(),
      );
    }
  }
  
  static bool _verifySignature(String data, String signature) {
    // Use RSA-SHA256 for verification
    final publicKey = _loadPublicKey();
    final verifier = RSAVerifier(publicKey);
    final signatureBytes = base64Decode(signature);
    return verifier.verify(utf8.encode(data), signatureBytes);
  }
  
  static RSAPublicKey _loadPublicKey() {
    // Load public key from PEM format
    // Implementation depends on crypto library used
    throw UnimplementedError('Implement public key loading');
  }
}
```

### **4. Enhanced Licence Model**

```dart
class EnhancedLicence {
  final String email;
  final String deviceFingerprint;
  final DateTime validUntil;
  final List<String> features;
  final String? customerId;
  final int maxDevices;
  final DateTime issuedAt;
  final String version;
  final String signature;
  
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
  });
  
  factory EnhancedLicence.fromJson(Map<String, dynamic> json) {
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
    );
  }
  
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
      'algorithm': 'RSA-SHA256',
    };
  }
  
  bool get isValid {
    return DateTime.now().isBefore(validUntil);
  }
  
  bool hasFeature(String featureName) {
    return features.contains(featureName);
  }
}
```

## Security Benefits

### **1. Tamper Resistance**
- Digital signatures prevent licence modification
- Device fingerprinting prevents licence sharing
- Cryptographic validation ensures authenticity

### **2. User Experience**
- No private key management required
- Simple licence file import
- Clear error messages for validation failures

### **3. Scalability**
- Supports multiple devices per licence
- Easy to revoke or update licences
- Centralized licence management

## Implementation Steps

### **Phase 1: Core Implementation**
1. Implement device fingerprinting
2. Create licence generation tools (for app owner)
3. Implement licence validation in app
4. Add enhanced error handling

### **Phase 2: Advanced Features**
1. Multi-device support
2. Licence revocation
3. Offline validation
4. Usage analytics

### **Phase 3: Security Hardening**
1. Key rotation mechanisms
2. Advanced device fingerprinting
3. Anti-tampering measures
4. Audit logging

## Dependencies

```yaml
dependencies:
  crypto: ^3.0.3
  device_info_plus: ^11.5.0
  package_info_plus: ^8.3.0
```

## Migration Strategy

1. **Backward Compatibility**: Support both old and new licence formats
2. **Gradual Rollout**: Introduce new system alongside existing one
3. **User Communication**: Clear instructions for licence upgrade process
4. **Support Tools**: Utilities to convert old licences to new format

## Risk Mitigation

1. **Key Management**: Secure storage of private keys
2. **Device Changes**: Handle device upgrades/replacements
3. **Network Issues**: Offline validation capabilities
4. **User Errors**: Clear error messages and recovery procedures

## Conclusion

This enhanced scheme provides:
- **Strong security** through asymmetric cryptography
- **Excellent UX** without private key management
- **Scalability** for enterprise deployment
- **Flexibility** for future enhancements

The approach balances security requirements with practical usability concerns, making it suitable for both individual users and enterprise customers. 