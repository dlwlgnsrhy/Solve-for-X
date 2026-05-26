import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing Ed25519 keypair generation, storage, and signing.
///
/// Generates a keypair on first launch. Private key stored in
/// [FlutterSecureStorage], public key as hex string in [SharedPreferences].
class Ed25519KeyManager {
  static const String _keyPublicKey = 'ed25519_public_key';
  static const String _keyPrivateKey = 'ed25519_private_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  List<int>? _cachedPublicKeyBytes;
  bool _initialized = false;
  late final Ed25519 _ed25519;

  /// Initialize the service with SharedPreferences instance.
  Future<Ed25519KeyManager> init() async {
    if (_initialized) return this;
    _prefs = await SharedPreferences.getInstance();
    _ed25519 = Ed25519();
    _cachedPublicKeyBytes = _loadPublicKey();
    _initialized = true;
    return this;
  }

  bool get hasKeys => _cachedPublicKeyBytes != null;

  List<int>? get publicKey => _cachedPublicKeyBytes;

  /// Returns the raw public key bytes as a [List<int>].
  List<int> getPublicKey() {
    final pubKey = _cachedPublicKeyBytes ?? _loadPublicKey();
    if (pubKey == null) return [];
    return pubKey;
  }

  /// Returns a deterministic device identifier.
  ///
  /// Uses a UUID stored in [SharedPreferences] or generates a new one.
  Future<String> getDeviceId() async {
    final keyDeviceId = 'device_id';
    var deviceId = _prefs?.getString(keyDeviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateUUID();
      await _prefs?.setString(keyDeviceId, deviceId);
    }
    return deviceId;
  }

  /// Generate a simple UUID v4.
  String _generateUUID() {
    final random = Random.secure();
    final uuidChars = <String>[
      'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx',
    ].first;
    return uuidChars.replaceAllMapped(
      RegExp('[xy]'),
      (match) => match.group(0)! == 'y'
          ? ['8', '9', 'a', 'b'][random.nextInt(4)]
          : random.nextInt(16).toRadixString(16),
    );
  }

  /// Sign stamp data using the stored Ed25519 private key.
  ///
  /// Concatenates [contentHash], [score], and [timestamp] as
  /// `contentHash:score:timestamp`, signs with the private key,
  /// and returns the signature as a base64-encoded string.
  ///
  /// Returns `null` if keys are not initialized.
  Future<String?> signStamp({
    required String contentHash,
    required double score,
    required String timestamp,
  }) async {
    final hasKeys = await _hasPrivateKey();
    if (!hasKeys) return null;

    try {
      final keyPair = await _loadKeyPair();
      if (keyPair == null) return null;

      final message = '$contentHash:$score:$timestamp';
      final signature = await _ed25519.signString(
        message,
        keyPair: keyPair,
      );

      return base64Encode(signature.bytes);
    } catch (e) {
      return null;
    }
  }

  /// Verify a stamp signature.
  ///
  /// Reconstructs `contentHash:score:timestamp`, verifies against
  /// [signature] using the stored public key, and returns whether the
  /// signature is valid.
  ///
  /// Returns `false` if verification fails or keys are not available.
  Future<bool> verifyStamp({
    required String contentHash,
    required double score,
    required String timestamp,
    required String signature,
  }) async {
    if (_cachedPublicKeyBytes == null) return false;

    try {
      final message = '$contentHash:$score:$timestamp';
      final signatureBytes = base64Decode(signature);
      final signatureObj = Signature(
        signatureBytes,
        publicKey: SimplePublicKey(_cachedPublicKeyBytes!, type: KeyPairType.ed25519),
      );

      return await _ed25519.verifyString(
        message,
        signature: signatureObj,
      );
    } catch (e) {
      return false;
    }
  }

  /// Generate a new Ed25519 keypair and store it securely.
  Future<void> generateKeypair() async {
    final keyPair = await _ed25519.newKeyPair();
    final keyPairData = await keyPair.extract();
    final publicKeyBytes =
        (await keyPair.extractPublicKey()).bytes;

    await _secureStorage.write(
      key: _keyPrivateKey,
      value: base64Encode(keyPairData.bytes),
    );

    final publicKeyHex = publicKeyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _cachedPublicKeyBytes = publicKeyBytes;
    await _cachePublicKeyHex(publicKeyHex);
  }

  List<int>? _loadPublicKey() {
    final hexString = _prefs?.getString(_keyPublicKey);
    if (hexString == null || hexString.isEmpty) return null;

    return List<int>.generate(
      hexString.length ~/ 2,
      (i) => int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16),
    );
  }

  Future<SimpleKeyPair?> _loadKeyPair() async {
    final privateKeyB64 = await _secureStorage.read(key: _keyPrivateKey);
    if (privateKeyB64 == null) return null;

    try {
      final privateKeyBytes = base64Decode(privateKeyB64);
      final keyPairData = SimpleKeyPairData(
        privateKeyBytes,
        publicKey: SimplePublicKey(
          _cachedPublicKeyBytes ?? _loadPublicKey() ?? [],
          type: KeyPairType.ed25519,
        ),
        type: KeyPairType.ed25519,
      );
      return keyPairData;
    } catch (e) {
      return null;
    }
  }

  /// Sign [data] using the stored Ed25519 private key.
  Future<String?> signData(String data) async {
    final hasKeys = await _hasPrivateKey();
    if (!hasKeys) return null;

    try {
      final keyPair = await _loadKeyPair();
      if (keyPair == null) return null;

      final signature = await _ed25519.signString(
        data,
        keyPair: keyPair,
      );

      return base64Encode(signature.bytes);
    } catch (e) {
      return null;
    }
  }

  Future<bool> _hasPrivateKey() async {
    final key = await _secureStorage.read(key: _keyPrivateKey);
    return key != null && key.isNotEmpty;
  }

  Future<void> _cachePublicKeyHex(String publicKeyHex) async {
    await _prefs?.setString(_keyPublicKey, publicKeyHex);
  }

  Future<String?> getPublicKeyHex() async {
    final bytes = _cachedPublicKeyBytes;
    if (bytes != null) {
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    }
    return _prefs?.getString(_keyPublicKey);
  }

  Future<void> reset() async {
    await _secureStorage.delete(key: _keyPrivateKey);
    await _prefs?.remove(_keyPublicKey);
    _cachedPublicKeyBytes = null;
    _initialized = false;
  }

  Future<String?> getPublicKeyBase64() async {
    final hex = await getPublicKeyHex();
    if (hex == null) return null;
    final bytes = List.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    );
    return base64Encode(bytes);
  }

  /// Verify a signature against a message using the public key.
  Future<bool?> verifySignature({
    required List<int> messageBytes,
    required List<int> signatureBytes,
  }) async {
    if (_cachedPublicKeyBytes == null) return null;

    try {
      final signatureObj = Signature(
        signatureBytes,
        publicKey: SimplePublicKey(
          _cachedPublicKeyBytes!,
          type: KeyPairType.ed25519,
        ),
      );

      return await _ed25519.verify(
        messageBytes,
        signature: signatureObj,
      );
    } catch (e) {
      return null;
    }
  }
}

final globalEd25519KeyManager = Ed25519KeyManager();
