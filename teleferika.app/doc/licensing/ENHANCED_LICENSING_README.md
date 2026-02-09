# Enhanced TeleferiKa Licensing System

This document describes the enhanced licensing system for TeleferiKa, which provides cryptographic validation, device fingerprinting, and improved security features.

## Overview

The enhanced licensing system replaces the simple hash-based validation with a robust cryptographic approach that includes:

- **RSA-SHA256 Digital Signatures**: Prevents licence tampering
- **Device Fingerprinting**: Prevents licence sharing across devices
- **Comprehensive Validation**: Multiple layers of security checks
- **Structured Error Handling**: Clear user-friendly error messages
- **Offline Capability**: Works without internet connection

## Architecture

### Core Components

1. **DeviceFingerprint** (`device_fingerprint.dart`)
   - Generates unique device identifiers
   - Platform-specific fingerprinting (Android/iOS)
   - SHA-256 hashing for consistency

2. **EnhancedLicence** (`enhanced_licence_model.dart`)
   - New licence data model with cryptographic support
   - Device fingerprint binding
   - Comprehensive validation methods

3. **CryptographicValidator** (`cryptographic_validator.dart`)
   - RSA signature verification
   - Embedded public key for validation
   - ASN.1 parsing for key management

4. **EnhancedLicenceService** (`enhanced_licence_service.dart`)
   - Main service for licence management
   - Comprehensive validation workflow
   - Storage and retrieval operations

5. **LicenceGeneratorUtility** (`licence_generator_utility.dart`)
   - Testing and demonstration utilities
   - Licence generation examples
   - Device information debugging

## Security Features

### 1. Cryptographic Signatures

```dart
// Licence data is signed with RSA-SHA256
final signature = CryptographicValidator.verifySignature(
  licence.dataForSigning,
  licence.signature,
);
```

**Benefits:**
- Prevents licence modification
- Ensures authenticity
- Industry-standard security

### 2. Device Fingerprinting

```dart
// Each licence is bound to a specific device
final deviceFingerprint = await DeviceFingerprint.generate();
final isValid = await licence.validateDeviceFingerprint();
```

**Benefits:**
- Prevents licence sharing
- Device-specific validation
- Stable across app restarts

### 3. Multi-Layer Validation

```dart
final validationResult = await EnhancedLicenceService.instance.validateLicence(licence);
if (!validationResult.isValid) {
  // Handle specific error types
  switch (validationResult.error?.code) {
    case 'LICENCE_EXPIRED':
      // Handle expiry
      break;
    case 'DEVICE_MISMATCH':
      // Handle device mismatch
      break;
    case 'INVALID_SIGNATURE':
      // Handle tampering
      break;
  }
}
```

## Usage Examples

### 1. Basic Licence Validation

```dart
import 'package:teleferika/licensing/enhanced_licence_service.dart';

// Initialize the service
await EnhancedLicenceService.instance.initialize();

// Check if licence is valid
final isValid = await EnhancedLicenceService.instance.isLicenceValid();
if (isValid) {
  print('Licence is valid');
} else {
  print('Licence is invalid or missing');
}
```

### 2. Feature Access Control

```dart
// Check if a specific feature is available
final hasExport = await EnhancedLicenceService.instance.hasFeature('advanced_export');
if (hasExport) {
  // Enable export functionality
  showExportDialog();
} else {
  // Show upgrade prompt
  showUpgradeDialog();
}
```

### 3. Licence Import

```dart
try {
  final licence = await EnhancedLicenceService.instance.importLicenceFromFile();
  if (licence != null) {
    print('Licence imported successfully: ${licence.email}');
  }
} on LicenceError catch (e) {
  // Handle specific licence errors
  showErrorDialog(e.userMessage);
}
```

### 4. Device Information

```dart
// Get device information for debugging
final deviceInfo = await EnhancedLicenceService.instance.getDeviceInfo();
print('Device: ${deviceInfo['model']}');
print('Platform: ${deviceInfo['platform']}');

// Generate device fingerprint for licence request
final fingerprint = await EnhancedLicenceService.instance.generateDeviceFingerprint();
print('Fingerprint: ${fingerprint.substring(0, 16)}...');
```

## Licence Format

### Enhanced Licence Structure

```json
{
  "data": {
    "email": "user@example.com",
    "deviceFingerprint": "a1b2c3d4e5f6...",
    "validUntil": "2025-12-31T23:59:59Z",
    "features": ["advanced_export", "map_download"],
    "customerId": "CUST001",
    "maxDevices": 1,
    "issuedAt": "2024-01-01T00:00:00Z",
    "version": "2.0"
  },
  "signature": "base64_encoded_signature",
  "algorithm": "RSA-SHA256"
}
```

### Licence Generation (App Owner Side)

```bash
# Generate device fingerprint request
flutter run --dart-define=GENERATE_FINGERPRINT=true

# Use the fingerprint to create a signed licence
# (This requires the private key and signing tools)
```

## Error Handling

### Structured Error Types

```dart
class LicenceError extends Error {
  final String code;
  final String userMessage;
  final String? technicalDetails;
}

// Common error codes:
// - LICENCE_EXPIRED: Licence has expired
// - DEVICE_MISMATCH: Licence not valid for this device
// - INVALID_SIGNATURE: Cryptographic validation failed
// - UNSUPPORTED_ALGORITHM: Unknown signature algorithm
// - FILE_TOO_LARGE: Licence file exceeds size limit
// - EMPTY_FILE: Licence file is empty
// - IMPORT_FAILED: General import failure
```

### Error Handling Example

```dart
try {
  await EnhancedLicenceService.instance.importLicenceFromFile();
} on LicenceError catch (e) {
  switch (e.code) {
    case 'LICENCE_EXPIRED':
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Licence Expired'),
          content: Text('Your licence has expired. Please renew to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      break;
      
    case 'DEVICE_MISMATCH':
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Device Mismatch'),
          content: Text('This licence is not valid for this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      break;
      
    default:
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Licence Error'),
          content: Text(e.userMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
  }
}
```

## Testing and Development

### Generate Test Licence

```dart
import 'package:teleferika/licensing/licence_generator_utility.dart';

// Generate a demo licence
final licenceJson = await LicenceGeneratorUtility.createDemoLicence(
  email: 'test@example.com',
  validUntil: DateTime.now().add(Duration(days: 365)),
);

// Save to file
await LicenceGeneratorUtility.saveLicenceToFile(
  licenceJson,
  'test_licence.lic',
);
```

### Device Information Debugging

```dart
// Print device information
await LicenceGeneratorUtility.printDeviceInfo();

// Validate licence file
final isValid = await LicenceGeneratorUtility.validateLicenceFile('test_licence.lic');
print('Licence valid: $isValid');
```

## Migration from Old System

### Backward Compatibility

The enhanced system is designed to work alongside the existing system:

```dart
// Check if enhanced licence is available
final enhancedLicence = await EnhancedLicenceService.instance.currentLicence;
if (enhancedLicence != null) {
  // Use enhanced system
  final isValid = await EnhancedLicenceService.instance.isLicenceValid();
} else {
  // Fall back to old system
  final oldLicence = await LicenceService.instance.currentLicence;
}
```

### Migration Strategy

1. **Phase 1**: Deploy enhanced system alongside existing
2. **Phase 2**: Migrate users to new licence format
3. **Phase 3**: Deprecate old system

## Security Considerations

### Private Key Management

- Keep private keys secure and separate from app code
- Use hardware security modules (HSM) for production
- Implement key rotation procedures
- Monitor for key compromise

### Device Fingerprinting

- Fingerprints may change on device upgrades
- Provide recovery mechanisms for legitimate device changes
- Consider multiple device support for enterprise customers

### Offline Validation

- System works without internet connection
- Periodic online validation recommended
- Implement grace periods for offline usage

## Dependencies

```yaml
dependencies:
  crypto: ^3.0.3
  device_info_plus: ^11.5.0
  package_info_plus: ^8.3.0
  pointycastle: ^4.0.0
  file_picker: ^8.0.0
  shared_preferences: ^2.2.0
```

## Troubleshooting

### Common Issues

1. **Device Fingerprint Mismatch**
   - Check if device has been upgraded
   - Verify app version hasn't changed
   - Regenerate fingerprint if needed

2. **Signature Validation Failed**
   - Verify licence file integrity
   - Check if licence was modified
   - Ensure correct public key is embedded

3. **Import Failures**
   - Check file format and size
   - Verify JSON structure
   - Ensure all required fields are present

### Debug Information

```dart
// Enable debug logging
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  print('${record.level.name}: ${record.time}: ${record.message}');
});

// Get detailed device information
final deviceInfo = await EnhancedLicenceService.instance.getDeviceInfo();
print('Device Info: $deviceInfo');

// Get licence status
final status = await EnhancedLicenceService.instance.getLicenceStatus();
print('Licence Status: $status');
```

## Future Enhancements

### Planned Features

1. **Multi-Device Support**
   - Allow licences for multiple devices
   - Device management interface
   - Usage tracking per device

2. **Online Validation**
   - Server-side licence verification
   - Real-time revocation
   - Usage analytics

3. **Advanced Security**
   - Hardware-backed key storage
   - Anti-tampering measures
   - Audit logging

4. **Enterprise Features**
   - Bulk licence management
   - Integration with identity providers
   - Advanced reporting

## Conclusion

The enhanced licensing system provides:

- **Strong Security**: Cryptographic validation prevents tampering
- **Device Binding**: Prevents licence sharing
- **Excellent UX**: Simple import process with clear error messages
- **Scalability**: Supports enterprise deployment
- **Future-Proof**: Extensible architecture for new features

This system represents a significant improvement over the previous hash-based approach while maintaining ease of use for end users. 