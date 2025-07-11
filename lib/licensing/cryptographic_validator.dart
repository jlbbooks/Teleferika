import 'dart:convert';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Cryptographic validator for licence signatures
class CryptographicValidator {
  static final Logger _logger = Logger('CryptographicValidator');

  // Embedded public key for signature verification
  static const String _publicKeyPem = '''
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
  static bool verifySignature(String data, String base64Signature) {
    try {
      final publicKey = _parsePublicKeyFromPem(_publicKeyPem);
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
