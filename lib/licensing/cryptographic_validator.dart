import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Cryptographic validator for licence signatures
class CryptographicValidator {
  static final Logger _logger = Logger('CryptographicValidator');

  // Cache for the server's public key
  static String? _cachedPublicKeyPem;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // Fallback public key (the original hardcoded one)
  static const String _fallbackPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkb1SRPu4W7u8BuSc1tXG
J9pB8E8Zl59UB7THVU+2wtgtSAFFqGN9z2DZJ7V/qYFB88IZq1Yd65cz/uvOat8I
otZ/HpnTGyrqOvvsYsI9g6bgds+QHJnYD/H5fxNKtlqAKTcjzbUOd1Czpupfi2sl
TkMBP6i9H5QP+Y8g2VzqIDqRDGcLs+Qa7fKJWGiGsy6HMJrAHZvgWaklMZOeuPJf
S8B7FVcx0cPFF7jDHH2Th01gNYNV1MGjzxMXV8EMnB5DXbP+qU76WGPNMes5k0n2
Dm1pbHUUh4ahuS7g/eNlyIiLBEJq6zp5VcinJkQhxo58cH/dsaly+zkfd+I4BFYD
vwIDAQAB
-----END PUBLIC KEY-----
''';

  /// Verifies the RSA-SHA256 signature of the given data
  static Future<bool> verifySignature(
    String data,
    String base64Signature,
  ) async {
    try {
      final publicKeyPem = await _getPublicKeyPem();
      final publicKey = _parsePublicKeyFromPem(publicKeyPem);
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      final signatureBytes = base64Decode(base64Signature);
      final dataBytes = Uint8List.fromList(utf8.encode(data));

      final isValid = signer.verifySignature(
        dataBytes,
        RSASignature(signatureBytes),
      );
      if (!isValid) {
        _logger.warning('Signature verification failed');
      }
      return isValid;
    } catch (e, stackTrace) {
      _logger.severe('Error verifying signature', e, stackTrace);
      return false;
    }
  }

  /// Gets the public key PEM from server or cache
  static Future<String> _getPublicKeyPem() async {
    // Check if we have a valid cached key
    if (_cachedPublicKeyPem != null && _cacheTimestamp != null) {
      final now = DateTime.now();
      if (now.difference(_cacheTimestamp!).compareTo(_cacheExpiry) < 0) {
        _logger.info('Using cached public key');
        return _cachedPublicKeyPem!;
      }
    }

    try {
      _logger.info('Fetching public key from server...');

      // Try to fetch from server
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://192.168.0.178:8899/public-key'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final publicKey = jsonResponse['publicKey'] as String;

        // Cache the key
        _cachedPublicKeyPem = publicKey;
        _cacheTimestamp = DateTime.now();

        _logger.info('Successfully fetched and cached public key from server');
        return publicKey;
      } else {
        _logger.warning(
          'Failed to fetch public key from server, using fallback',
        );
        return _fallbackPublicKeyPem;
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Error fetching public key from server, using fallback',
        e,
        stackTrace,
      );
      return _fallbackPublicKeyPem;
    }
  }

  /// Parses an RSA public key from PEM format
  static RSAPublicKey _parsePublicKeyFromPem(String pem) {
    try {
      // Clean up the PEM format
      final lines = pem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      final asn1Bytes = base64Decode(lines);
      final asn1Parser = ASN1Parser(asn1Bytes);

      // Parse the top-level sequence
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      if (topLevelSeq.elements == null || topLevelSeq.elements!.length < 2) {
        throw FormatException('Invalid public key structure');
      }

      // Get the public key bit string
      final publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;
      if (publicKeyBitString.valueBytes == null) {
        throw FormatException('Invalid public key bit string');
      }

      // Parse the public key sequence
      final publicKeyAsn = ASN1Parser(publicKeyBitString.valueBytes);
      final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
      if (publicKeySeq.elements == null || publicKeySeq.elements!.length < 2) {
        throw FormatException('Invalid public key sequence');
      }

      // Extract modulus and exponent
      final modulus = publicKeySeq.elements![0] as ASN1Integer;
      final exponent = publicKeySeq.elements![1] as ASN1Integer;

      // Convert to BigInt using toString() method
      final modulusBigInt = BigInt.parse(modulus.toString());
      final exponentBigInt = BigInt.parse(exponent.toString());

      return RSAPublicKey(modulusBigInt, exponentBigInt);
    } catch (e, stackTrace) {
      _logger.severe('Error parsing public key from PEM', e, stackTrace);
      rethrow;
    }
  }
}
