import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:pointycastle/pointycastle.dart'
    hide ASN1Parser, ASN1Sequence, ASN1Integer, ASN1BitString;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:teleferika/core/app_config.dart';

/// Cryptographic validator for license signatures
class CryptographicValidator {
  static final Logger _logger = Logger('CryptographicValidator');

  // Cache for public key to avoid repeated fetches
  static String? _cachedPublicKeyPem;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Verify a signature using RSA-SHA256
  ///
  /// ## Parameters
  /// - `data`: The data that was signed
  /// - `signature`: The signature to verify (base64 encoded)
  /// - `algorithm`: The signature algorithm (should be 'RSA-SHA256')
  ///
  /// ## Returns
  /// `true` if the signature is valid, `false` otherwise
  static Future<bool> verifySignature({
    required String data,
    required String signature,
    required String algorithm,
  }) async {
    try {
      _logger.info('Verifying signature with algorithm: $algorithm');

      if (algorithm != 'RSA-SHA256') {
        _logger.warning('Unsupported algorithm: $algorithm');
        return false;
      }

      // Get the public key
      final publicKeyPem = await _getPublicKeyPem();
      if (publicKeyPem == null) {
        _logger.severe('Could not get public key for verification');
        return false;
      }

      // Parse the public key
      final publicKey = _parsePublicKeyFromPem(publicKeyPem);
      if (publicKey == null) {
        _logger.severe('Could not parse public key');
        return false;
      }

      // Hash the data
      final dataBytes = utf8.encode(data);
      final hash = sha256.convert(dataBytes);

      // Verify the signature
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      final signatureBytes = base64Decode(signature);
      final sig = RSASignature(signatureBytes);

      final isValid = signer.verifySignature(
        Uint8List.fromList(hash.bytes),
        sig,
      );

      _logger.info('Signature verification result: $isValid');
      return isValid;
    } catch (e, stackTrace) {
      _logger.severe('Error verifying signature', e, stackTrace);
      return false;
    }
  }

  /// Get the public key PEM from server or local file
  static Future<String?> _getPublicKeyPem() async {
    // Check cache first
    if (_cachedPublicKeyPem != null && _cacheTimestamp != null) {
      final age = DateTime.now().difference(_cacheTimestamp!);
      if (age < _cacheDuration) {
        _logger.info('Using cached public key (age: ${age.inMinutes} minutes)');
        return _cachedPublicKeyPem;
      }
    }

    // Try to fetch from server
    try {
      _logger.info('Fetching public key from server...');
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('${AppConfig.licenseServerUrl}/public-key'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        _logger.info(
          'Got response from server (first 100 chars): ${responseBody.substring(0, 100)}...',
        );

        // Parse JSON response and extract public key
        final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final publicKeyPem = jsonResponse['publicKey'] as String;

        // Convert JSON escape sequences to actual newlines
        final cleanPublicKey = publicKeyPem.replaceAll('\\n', '\n');

        _logger.info(
          'Extracted public key PEM (first 50 chars): ${cleanPublicKey.substring(0, 50)}...',
        );

        // Cache the result
        _cachedPublicKeyPem = cleanPublicKey;
        _cacheTimestamp = DateTime.now();

        return cleanPublicKey;
      } else {
        _logger.warning('Server returned status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Error fetching public key from server, trying local file',
        e,
        stackTrace,
      );
    }

    // Fall back to local server key file
    try {
      _logger.info('Loading public key from local server key file...');
      final file = File(
        '/home/michael/StudioProjects/Teleferika/keys/public_key.pem',
      );
      if (await file.exists()) {
        final keyContent = await file.readAsString();
        _logger.info(
          'Loaded public key from local file (first 50 chars): ${keyContent.substring(0, 50)}...',
        );

        // Cache the result
        _cachedPublicKeyPem = keyContent;
        _cacheTimestamp = DateTime.now();

        return keyContent;
      } else {
        _logger.severe('Local server key file not found');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error reading local server key file', e, stackTrace);
    }

    return null;
  }

  /// Clear the cached public key
  static void clearCache() {
    _cachedPublicKeyPem = null;
    _cacheTimestamp = null;
    _logger.info('Public key cache cleared');
  }

  /// Parses an RSA public key from PEM format
  static RSAPublicKey? _parsePublicKeyFromPem(String pem) {
    try {
      _logger.info('Parsing public key from PEM...');

      // Clean up the PEM format
      final lines = pem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      final asn1Bytes = base64Decode(lines);
      _logger.info('Decoded ASN.1 bytes length: ${asn1Bytes.length}');

      // Try multiple parsing approaches
      return _tryParseX509Format(asn1Bytes) ?? _tryParsePKCS1Format(asn1Bytes);
    } catch (e, stackTrace) {
      _logger.severe('Error parsing public key from PEM', e, stackTrace);
      return null;
    }
  }

  /// Try to parse as X.509 SubjectPublicKeyInfo format
  static RSAPublicKey? _tryParseX509Format(Uint8List asn1Bytes) {
    try {
      final asn1Parser = ASN1Parser(asn1Bytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

      if (topLevelSeq.elements.length < 2) {
        return null;
      }

      // This should be SubjectPublicKeyInfo format
      final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;

      // Parse the BIT STRING content
      final bitStringBytes = publicKeyBitString.valueBytes();

      // Skip the first byte if it's a padding indicator (usually 0x00)
      final startIndex = bitStringBytes[0] == 0 ? 1 : 0;
      final actualKeyBytes = bitStringBytes.sublist(startIndex);

      final publicKeyAsn = ASN1Parser(actualKeyBytes);
      final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;

      if (publicKeySeq.elements.length < 2) {
        return null;
      }

      _logger.info(
        'X.509: Element 0 type: ${publicKeySeq.elements[0].runtimeType}',
      );
      _logger.info(
        'X.509: Element 1 type: ${publicKeySeq.elements[1].runtimeType}',
      );

      // Handle nested sequences if present
      final modulusElement = publicKeySeq.elements[0];
      final exponentElement = publicKeySeq.elements[1];

      final modulus = modulusElement is ASN1Integer
          ? modulusElement
          : (modulusElement as ASN1Sequence).elements[0] as ASN1Integer;
      final exponent = exponentElement is ASN1Integer
          ? exponentElement
          : (exponentElement as ASN1Sequence).elements[0] as ASN1Integer;

      _logger.info('Modulus: ${modulus.valueAsBigInteger.toString()}');
      _logger.info('Exponent: ${exponent.valueAsBigInteger.toString()}');

      _logger.info('Successfully parsed using X.509 format');
      return RSAPublicKey(
        modulus.valueAsBigInteger,
        exponent.valueAsBigInteger,
      );
    } catch (e) {
      _logger.warning('X.509 parsing failed: $e');
      return null;
    }
  }

  /// Try to parse as PKCS#1 format
  static RSAPublicKey? _tryParsePKCS1Format(Uint8List asn1Bytes) {
    try {
      final asn1Parser = ASN1Parser(asn1Bytes);
      final publicKeySeq = asn1Parser.nextObject() as ASN1Sequence;

      if (publicKeySeq.elements.length < 2) {
        return null;
      }

      _logger.info(
        'PKCS#1: Element 0 type: ${publicKeySeq.elements[0].runtimeType}',
      );
      _logger.info(
        'PKCS#1: Element 1 type: ${publicKeySeq.elements[1].runtimeType}',
      );

      // Handle nested sequences if present
      final modulusElement = publicKeySeq.elements[0];
      final exponentElement = publicKeySeq.elements[1];

      final modulus = modulusElement is ASN1Integer
          ? modulusElement
          : (modulusElement as ASN1Sequence).elements[0] as ASN1Integer;
      final exponent = exponentElement is ASN1Integer
          ? exponentElement
          : (exponentElement as ASN1Sequence).elements[0] as ASN1Integer;

      _logger.info('Successfully parsed using PKCS#1 format');
      return RSAPublicKey(
        modulus.valueAsBigInteger,
        exponent.valueAsBigInteger,
      );
    } catch (e) {
      _logger.warning('PKCS#1 parsing failed: $e');
      return null;
    }
  }
}
