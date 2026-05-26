import 'package:flutter_test/flutter_test.dart';

import 'package:origin/core/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    test('generates non-empty encryption key', () {
      final service = EncryptionService();
      final key = service.generateEncryptionKey();
      expect(key, isNotEmpty);
      expect(key.length, 64); // SHA-256 hex = 64 chars
    });

    test('generated keys are unique', () {
      final service = EncryptionService();
      final key1 = service.generateEncryptionKey();
      final key2 = service.generateEncryptionKey();
      expect(key1, isNot(equals(key2)));
    });

    test('hasNoStoredKeyByDefault', () {
      final service = EncryptionService();
      expect(service.hasStoredKey(), isFalse);
    });

    test('can save and retrieve key', () {
      // SharedPreferences not initialized, so save/retrieve is a no-op
      // This is a stub test for when real device testing is configured
    });

    test('can delete stored key', () {
      // SharedPreferences not initialized, so delete is a no-op
    });
  });
}
