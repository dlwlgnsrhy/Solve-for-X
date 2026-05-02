import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Utility service for generating SHA-256 hashes.
///
/// Wraps the `crypto` package to provide a simple static interface
/// for hashing string content.
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
}
