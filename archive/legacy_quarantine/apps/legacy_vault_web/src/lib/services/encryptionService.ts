import { encryptData, decryptData } from '@/lib/crypto/aes-gcm';

export class EncryptionService {
  static async encrypt(
    plaintext: string,
    passphrase: string,
  ): Promise<{ ciphertext: Uint8Array; nonce: Uint8Array }> {
    return encryptData(plaintext, passphrase);
  }

  static async decrypt(
    payload: { ciphertext: Uint8Array; nonce: Uint8Array },
    passphrase: string,
  ): Promise<string> {
    return decryptData(payload, passphrase);
  }
}
