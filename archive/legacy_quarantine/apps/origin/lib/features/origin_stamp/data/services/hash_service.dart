import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../core/services/ed25519_key_manager.dart';

/// Utility service for generating SHA-256 hashes and Ed25519 signatures.
///
/// Wraps the `crypto` package for hashing and uses [Ed25519KeyManager]
/// for cryptographic signing of stamp data.
class HashService {
  /// Generate a SHA-256 hex digest for [input].
  ///
  /// Returns the 64-character lowercase hex string representing
  /// the hash of the UTF-8 encoded input.
  static String generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign [data] using the stored Ed25519 private key.
  ///
  /// Returns the signature as a lowercase hex string, or [null] if
  /// the key manager has not been initialized or keys are missing.
  static Future<String?> sign(String data) {
    return globalEd25519KeyManager.signData(data);
  }

  /// Get the cached public key as a hex string.
  static Future<String?> getPublicKeyHex() {
    return globalEd25519KeyManager.getPublicKeyHex();
  }
}
