import 'dart:convert';
import 'dart:typed_data';

import 'dart:math' show Random;

import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';

/// AES-256 client-side encryption service.
///
/// Uses a user-provided passphrase to derive an AES-256 key.
/// The passphrase is **never** stored on the server.
class EncryptionService {
  EncryptionService._();

  /// Encrypts plaintext with AES-256-CBC using a passphrase-derived key.
  ///
  /// Returns a JSON string containing the salt, IV, and ciphertext.
  static Future<String> encrypt(String plaintext, String passphrase) async {
    if (plaintext.isEmpty) {
      return '';
    }

    final saltBytes = _secureRandomBytes(16);
    final key = _deriveKey(passphrase, saltBytes);
    final iv = encrypt_lib.IV.fromSecureRandom(16);
    final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return jsonEncode({
      'salt': base64.encode(saltBytes),
      'iv': base64.encode(iv.bytes),
      'data': encrypted.base64,
    });
  }

  /// Decrypts a previously encrypted JSON payload using the same passphrase.
  static Future<String> decrypt(
    String encryptedJson,
    String passphrase,
  ) async {
    if (encryptedJson.isEmpty) {
      return '';
    }

    final Map<String, dynamic> payload =
        jsonDecode(encryptedJson) as Map<String, dynamic>;
    final saltBytes = base64Decode(payload['salt'] as String);
    final key = _deriveKey(passphrase, saltBytes);
    final iv = encrypt_lib.IV.fromBase64(payload['iv'] as String);
    final encrypted =
        encrypt_lib.Encrypted.fromBase64(payload['data'] as String);
    final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Generates a random passphrase (24-char alphanumeric + symbols).
  static String generatePassphrase() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final r = Random.secure();
    return List.generate(
        24, (index) => chars[r.nextInt(chars.length)].toString()).join();
  }

  /// Derives a 256-bit AES key from passphrase + salt using PBKDF2 SHA-256.
  static encrypt_lib.Key _deriveKey(
      String passphrase, List<int> saltBytes) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(Uint8List.fromList(saltBytes), 10000, 32));
    final keyBytes = pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
    return encrypt_lib.Key(keyBytes);
  }

  static List<int> _secureRandomBytes(int length) {
    final r = Random.secure();
    return List.generate(length, (_) => r.nextInt(256));
  }
}
