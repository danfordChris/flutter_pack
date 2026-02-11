import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';

class StateException implements Exception {
  final String message;
  StateException(this.message);

  @override
  String toString() => 'StateException: $message';
}

class SignatureConfig {
  AsymmetricKey parse(String key) {
    final bytes = base64.decode(cleanedKey(key));
    final asn1 = ASN1Parser(bytes);
    final top = asn1.nextObject() as ASN1Sequence;

    if (top.elements.length == 9) {
      final modulus = (top.elements[1] as ASN1Integer).valueAsBigInteger!;
      final privateExponent = (top.elements[3] as ASN1Integer).valueAsBigInteger!;
      final p = (top.elements[4] as ASN1Integer).valueAsBigInteger!;
      final q = (top.elements[5] as ASN1Integer).valueAsBigInteger!;
      return RSAPrivateKey(modulus, privateExponent, p, q);
    }

    if (top.elements.length == 2 && top.elements[1] is ASN1BitString) {
      final pubBytes = (top.elements[1] as ASN1BitString).valueBytes();

      // FIX: Remove first padding byte from BIT STRING
      if (pubBytes.isEmpty) {
        throw ASN1Exception("Empty BIT STRING in public key");
      }
      final cleaned = Uint8List.fromList(pubBytes.sublist(1));

      final seq = ASN1Parser(cleaned).nextObject() as ASN1Sequence;

      final modulus = (seq.elements[0] as ASN1Integer).valueAsBigInteger!;
      final exponent = (seq.elements[1] as ASN1Integer).valueAsBigInteger!;

      return RSAPublicKey(modulus, exponent);
    }

    if (top.elements.length == 3 && top.elements[2] is ASN1OctetString) {
      final inner = ASN1Parser((top.elements[2] as ASN1OctetString).valueBytes()).nextObject() as ASN1Sequence;
      final modulus = (inner.elements[1] as ASN1Integer).valueAsBigInteger!;
      final privateExponent = (inner.elements[3] as ASN1Integer).valueAsBigInteger!;
      final p = (inner.elements[4] as ASN1Integer).valueAsBigInteger!;
      final q = (inner.elements[5] as ASN1Integer).valueAsBigInteger!;
      return RSAPrivateKey(modulus, privateExponent, p, q);
    }

    throw FormatException("Unsupported key format");
  }

  String cleanedKey(String key) {
    return key
        .replaceAll("-----BEGIN PUBLIC KEY-----", "")
        .replaceAll("-----END PUBLIC KEY-----", "")
        .replaceAll("-----BEGIN RSA PUBLIC KEY-----", "")
        .replaceAll("-----END RSA PUBLIC KEY-----", "")
        .replaceAll("-----BEGIN PRIVATE KEY-----", "")
        .replaceAll("-----END PRIVATE KEY-----", "")
        .replaceAll("-----BEGIN RSA PRIVATE KEY-----", "")
        .replaceAll("-----END RSA PRIVATE KEY-----", "")
        .replaceAll("\n", "")
        .replaceAll("\r", "");
  }
}

class DigitalSignature {
  final RSAPrivateKey? _privateKey;
  final RSAPublicKey? _publicKey;

  DigitalSignature({
    String? privateKeyPEM,
    String? publicKeyPEM,
  })  : _privateKey = privateKeyPEM != null ? SignatureConfig().parse(privateKeyPEM) as RSAPrivateKey : null,
        _publicKey = publicKeyPEM != null ? SignatureConfig().parse(publicKeyPEM) as RSAPublicKey : null;

  String sign(String data) {
    if (_privateKey == null) throw StateException("Cannot sign data: Private key not configured");
    final signer = Signer("SHA-256/RSA");
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey));
    final sig = signer.generateSignature(Uint8List.fromList(utf8.encode(data))) as RSASignature;
    return base64Encode(sig.bytes);
  }

  bool verify(String data, String signature) {
    if (_publicKey == null) throw StateException("Cannot verify signature: Public key not configured");
    final verifier = Signer("SHA-256/RSA");
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(_publicKey!));
    return verifier.verifySignature(
      Uint8List.fromList(utf8.encode(data)),
      RSASignature(base64Decode(signature)),
    );
  }
}
