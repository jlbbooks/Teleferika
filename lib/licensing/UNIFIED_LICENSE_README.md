# Unified License System

This document describes the unified license system that provides consistent license management across both the server and client applications.

## Overview

The unified license system replaces the previous `EnhancedLicence` and `LicenseRecord` classes with a single `License` class that contains all necessary fields for comprehensive license management.

## License Structure

The unified `License` class includes all fields from the server's `LicenseRecord`:

```dart
class License {
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
}
```

## Key Features

### 1. Status Tracking
- **active**: License is valid and can be used
- **expired**: License has passed its expiration date
- **revoked**: License has been manually revoked by admin

### 2. Usage Statistics
- **usageCount**: Number of times the license has been validated
- **lastUsed**: Timestamp of the last validation

### 3. Revocation Support
- **revokedAt**: When the license was revoked
- **revokedReason**: Why the license was revoked

### 4. Device Binding
- **deviceFingerprint**: Unique device identifier to prevent license sharing

## JSON Serialization

The `License` class supports both client and server JSON formats:

### Client Format (Nested)
```json
{
  "data": {
    "email": "user@example.com",
    "customerId": "CUST001",
    "deviceFingerprint": "device-123",
    "issuedAt": "2024-01-01T12:00:00.000Z",
    "validUntil": "2024-12-31T23:59:59.000Z",
    "features": ["export_basic"],
    "maxDevices": 1,
    "version": "2.0",
    "status": "active",
    "usageCount": 5,
    "lastUsed": "2024-01-15T10:30:00.000Z"
  },
  "signature": "base64-signature",
  "algorithm": "RSA-SHA256"
}
```

### Server Format (Flat)
```json
{
  "email": "user@example.com",
  "customerId": "CUST001",
  "deviceFingerprint": "device-123",
  "issuedAt": "2024-01-01T12:00:00.000Z",
  "validUntil": "2024-12-31T23:59:59.000Z",
      "features": ["export_basic"],
  "maxDevices": 1,
  "version": "2.0",
  "signature": "base64-signature",
  "algorithm": "RSA-SHA256",
  "status": "active",
  "usageCount": 5,
  "lastUsed": "2024-01-15T10:30:00.000Z"
}
```

## Usage Examples

### Creating a License
```dart
final license = License(
  email: 'user@example.com',
  customerId: 'CUST001',
  deviceFingerprint: 'device-123',
  issuedAt: DateTime.now(),
  validUntil: DateTime.now().add(const Duration(days: 365)),
  features: ['export_kml'],
  maxDevices: 1,
  version: '2.0',
  signature: 'signature',
  algorithm: 'RSA-SHA256',
  status: 'active',
  usageCount: 0,
  lastUsed: DateTime.now(),
);
```

### Validating a License
```dart
// Check if license is valid
if (license.isValid) {
  print('License is valid');
}

// Check if license expires soon
if (license.expiresSoon) {
  print('License expires in ${license.daysRemaining} days');
}

// Check for specific features
// (example: if (license.hasFeature('export_kml')) { ... })
```

### Updating Usage Statistics
```dart
// Increment usage count and update last used
final updatedLicense = license.withUsageUpdate();
```

### Revoking a License
```dart
// Revoke license with reason
final revokedLicense = license.withRevocation(
  reason: 'Terms violation'
);
```

## Service Integration

### Client Service
The `LicenseService` provides methods for:
- Loading/saving licenses from storage
- Validating licenses with cryptographic verification
- Checking feature availability
- Importing licenses from files
- Creating demo licenses for testing

### Server Integration
The server uses the same `License` structure for:
- Generating new licenses
- Storing licenses in CSV format
- Validating licenses
- Tracking usage statistics
- Managing license status

## Migration

Since we're still in development with no real licenses distributed, no migration is needed. The new unified system provides:

1. **Consistency**: Same data structure across server and client
2. **Completeness**: All necessary fields for comprehensive license management
3. **Flexibility**: Support for both client and server JSON formats
4. **Extensibility**: Easy to add new fields in the future

## Security Features

- **Cryptographic Signing**: RSA-SHA256 signatures for license integrity
- **Device Fingerprinting**: Prevents license sharing between devices
- **Status Validation**: Comprehensive validation including expiration and revocation
- **Usage Tracking**: Monitors license usage patterns

## Future Enhancements

The unified system is designed to support future enhancements such as:
- Multi-device licenses
- Feature-based pricing
- Usage analytics
- Automated renewal
- License transfer capabilities 