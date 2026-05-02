import Foundation
import CryptoKit
import Security

// MARK: - EncryptionService

/// AES-256-GCM encryption service using CryptoKit.
/// Stores encryption key in Keychain with whenUnlocked accessibility.

struct EncryptionService {
    private static let service = "com.sfx.legacyvault.encryption"
    
    /// Derives a SymmetricKey from a passphrase using CryptoKit.
        func deriveKey(passphrase: String) -> SymmetricKey {
        let data = passphrase.data(using: .utf8) ?? Data()
        return SymmetricKey(data: data)
    }
    
    /// Encrypts data using AES-256-GCM.
    /// - Parameter data: Plaintext data to encrypt.
    /// - Parameter passphrase: User passphrase for encryption.
    /// - Returns: EncryptedPayload containing ciphertext, nonce, and tag.
    func encrypt(_ data: Data, with passphrase: String) throws -> EncryptedPayload {
        let key = deriveKey(passphrase: passphrase)
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        // Convert SwiftData seal to serializable payload
        let ciphertextBytes: [UInt8] = sealedBox.ciphertext.map { $0 }
        let nonceBytes = nonce.withUnsafeBytes { Array($0) }
        let tagBytes: [UInt8] = sealedBox.tag.map { $0 }
        
        return EncryptedPayload(ciphertext: ciphertextBytes, nonce: nonceBytes, tag: tagBytes)
    }
    
    /// Decrypts an EncryptedPayload.
    /// - Parameter payload: The encrypted payload to decrypt.
    /// - Parameter passphrase: The user passphrase used for encryption.
    /// - Returns: The original plaintext data.
    func decrypt(_ payload: EncryptedPayload, with passphrase: String) throws -> Data {
        let key = deriveKey(passphrase: passphrase)
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: try AES.GCM.Nonce(data: Data(payload.nonce)),
            ciphertext: Data(payload.ciphertext),
            tag: Data(payload.tag)
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    /// Saves the encryption passphrase to Keychain.
    /// - Parameter passphrase: The passphrase to store.
    func saveEncryptionKey(passphrase: String) throws {
        let keyData = passphrase.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: "encryption_key"
        ]
        
        // Delete existing key if present
        SecItemDelete(query as CFDictionary)
        // Add new key
        try SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Loads the encryption passphrase from Keychain.
    func loadEncryptionKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: "encryption_key",
            kSecReturnData as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            throw EncryptionError.keyNotFound
        }
        
        guard let passphrase = String(data: data, encoding: .utf8) else {
            throw EncryptionError.keyDecryptionFailed
        }
        
        return passphrase
    }
}

// MARK: - EncryptedPayload

struct EncryptedPayload: Codable, Hashable {
    let ciphertext: [UInt8]
    let nonce: [UInt8]
    let tag: [UInt8]
}

// MARK: - EncryptionError

enum EncryptionError: LocalizedError {
    case keyNotFound
    case keyDecryptionFailed
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .keyNotFound: return "암호화 키를 찾을 수 없습니다"
        case .keyDecryptionFailed: return "키 복호화에 실패했습니다"
        case .encryptionFailed: return "암호화에 실패했습니다"
        case .decryptionFailed: return "복호화에 실패했습니다"
        }
    }
}
