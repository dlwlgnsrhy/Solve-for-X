export async function encryptData(
  data: string,
  passphrase: string,
): Promise<{ ciphertext: Uint8Array; nonce: Uint8Array }> {
  const key = await deriveKey(passphrase);
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: nonce },
    key,
    new TextEncoder().encode(data),
  );
  return { ciphertext: new Uint8Array(ciphertext), nonce };
}

export async function decryptData(
  payload: { ciphertext: Uint8Array; nonce: Uint8Array },
  passphrase: string,
): Promise<string> {
  const key = await deriveKey(passphrase);
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: payload.nonce as BufferSource },
    key,
    payload.ciphertext as BufferSource,
  );
  return new TextDecoder().decode(decrypted);
}

async function deriveKey(passphrase: string): Promise<CryptoKey> {
  const material = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(passphrase),
    { name: 'PBKDF2' },
    false,
    ['deriveKey'],
  );
  return crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      salt: new TextEncoder().encode('legacy-vault-salt'),
      iterations: 100000,
      hash: 'SHA-256',
    },
    material,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt'],
  );
}
