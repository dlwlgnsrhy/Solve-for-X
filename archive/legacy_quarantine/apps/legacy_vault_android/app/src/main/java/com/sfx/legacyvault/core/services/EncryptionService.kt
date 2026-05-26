package com.sfx.legacyvault.core.services

import com.sfx.legacyvault.core.util.Constants
import java.nio.ByteBuffer
import java.security.Key
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

class EncryptionService {

    fun deriveKey(passphrase: String): Key {
        val data = passphrase.toByteArray(Charsets.UTF_8)
        return SecretKeySpec(data, "AES")
    }

    fun encrypt(
        plaintext: ByteArray,
        passphrase: String
    ): EncryptedPayload {
        val key = deriveKey(passphrase)
        val cipher = Cipher.getInstance(Constants.ENCRYPTION_KEY_ALGORITHM)
        cipher.init(Cipher.ENCRYPT_MODE, key)

        val nonce = cipher.iv
        val ciphertext = cipher.doFinal(plaintext)

        return EncryptedPayload(
            ciphertext = ciphertext,
            nonce = nonce,
            tag = cipher.iv.copyOfRange(0, 12)
        )
    }

    fun decrypt(payload: EncryptedPayload, passphrase: String): ByteArray {
        val key = deriveKey(passphrase)
        val cipher = Cipher.getInstance(Constants.ENCRYPTION_KEY_ALGORITHM)
        val spec = GCMParameterSpec(
            Constants.ENCRYPTION_KEY_SIZE,
            payload.nonce
        )
        cipher.init(Cipher.DECRYPT_MODE, key, spec)
        return cipher.doFinal(payload.ciphertext)
    }

    fun saveKey(passphrase: String) {
        // AndroidKeystore integration placeholder.
        // In production: store via KeyStore with WHEN_UNLOCKED accessibility.
    }

    fun loadKey(): String {
        // AndroidKeystore integration placeholder.
        // In production: retrieve via KeyStore.
        throw IllegalStateException("Key not available in keystore")
    }

    data class EncryptedPayload(
        val ciphertext: ByteArray,
        val nonce: ByteArray,
        val tag: ByteArray
    )
}
