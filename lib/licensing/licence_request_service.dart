import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';
import 'package:teleferika/licensing/licence_model.dart';

/// Service for handling license requests to the server
class LicenceRequestService {
  static final Logger _logger = Logger('LicenceRequestService');
  static final LicenceRequestService _instance =
      LicenceRequestService._internal();

  factory LicenceRequestService() => _instance;
  LicenceRequestService._internal();

  /// Request a new license from the server
  ///
  /// ## Parameters
  /// - `email`: User's email address
  /// - `requestedFeatures`: List of features the user wants
  /// - `maxDevices`: Number of devices needed (1-5)
  ///
  /// ## Returns
  /// The created license with status "requested"
  Future<Licence> requestLicence({
    required String email,
    required List<String> requestedFeatures,
    required int maxDevices,
  }) async {
    try {
      _logger.info(
        'Requesting license for $email with ${requestedFeatures.length} features',
      );

      // Generate device fingerprint
      final deviceFingerprint = await DeviceFingerprint.generate();

      // Prepare request data
      final requestData = {
        'email': email,
        'deviceFingerprint': deviceFingerprint,
        'requestedFeatures': requestedFeatures,
        'maxDevices': maxDevices.clamp(1, 5), // Ensure between 1-5
        'version': '2.0',
      };

      // Make API call to server
      final url = '${AppConfig.licenseServerUrl}/license/requestLicence';
      _logger.info('Making license request to: $url');
      _logger.info('Request data: ${jsonEncode(requestData)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final licence = Licence.fromJson(responseData);

        _logger.info(
          'License request successful: ${licence.email} (${licence.status})',
        );
        return licence;
      } else {
        final errorMessage = response.body.isNotEmpty
            ? jsonDecode(response.body)['message'] ?? 'Unknown error'
            : 'Server error: ${response.statusCode}';

        _logger.warning('License request failed: $errorMessage');
        throw LicenceError(
          code: 'REQUEST_FAILED',
          userMessage: 'Failed to request license: $errorMessage',
          technicalDetails: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Error requesting license', e, stackTrace);

      if (e is LicenceError) {
        rethrow;
      }

      throw LicenceError(
        code: 'NETWORK_ERROR',
        userMessage:
            'Network error while requesting license. Please check your connection.',
        technicalDetails: e.toString(),
      );
    }
  }

  /// Check license status with the server
  ///
  /// ## Parameters
  /// - `licence`: The license to check
  ///
  /// ## Returns
  /// Updated license with current status from server
  Future<Licence> checkLicenceStatus(Licence licence) async {
    try {
      // Don't check development licenses
      if (!Licence.requiresServerValidation(licence.status)) {
        _logger.info('Skipping server check for development license');
        return licence;
      }

      _logger.info('Checking license status for ${licence.email}');

      final url =
          '${AppConfig.licenseServerUrl}/license/status/${licence.email}';
      _logger.info('Making status check request to: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      _logger.info('Status check response status: ${response.statusCode}');
      _logger.info('Status check response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final updatedLicence = Licence.fromJson(responseData);

        _logger.info(
          'License status check successful: ${updatedLicence.status}',
        );
        return updatedLicence;
      } else if (response.statusCode == 404) {
        // License not found on server - mark as revoked
        _logger.warning(
          'License not found on server (404), marking as revoked',
        );

        // Create a revoked version of the license
        final revokedLicence = Licence(
          email: licence.email,
          customerId: licence.customerId,
          deviceFingerprint: licence.deviceFingerprint,
          issuedAt: licence.issuedAt,
          validUntil: licence.validUntil,
          features: licence.features,
          maxDevices: licence.maxDevices,
          version: licence.version,
          signature: licence.signature,
          algorithm: licence.algorithm,
          status: Licence.statusRevoked,
          revokedAt: DateTime.now(),
          revokedReason: 'License deleted from server',
          usageCount: licence.usageCount,
          lastUsed: licence.lastUsed,
        );

        return revokedLicence;
      } else {
        _logger.warning('License status check failed: ${response.statusCode}');
        // Return original license if check fails for other reasons
        return licence;
      }
    } catch (e, stackTrace) {
      _logger.severe('Error checking license status', e, stackTrace);
      // Return original license if check fails
      return licence;
    }
  }

  /// Get status message for user display
  String getStatusMessage(String status) {
    switch (status) {
      case Licence.statusActive:
        return 'License is active and valid';
      case Licence.statusExpired:
        return 'License has expired';
      case Licence.statusRevoked:
        return 'License has been revoked';
      case Licence.statusRequested:
        return 'License request is pending approval';
      case Licence.statusDenied:
        return 'License request was denied';
      case Licence.statusDevelopment:
        return 'Development license (no server validation required)';
      default:
        return 'Unknown license status: $status';
    }
  }

  /// Check if status indicates the license needs admin action
  bool needsAdminAction(String status) {
    return status == Licence.statusRequested;
  }

  /// Check if status indicates the license is permanently invalid
  bool isPermanentlyInvalid(String status) {
    return status == Licence.statusDenied || status == Licence.statusRevoked;
  }
}
