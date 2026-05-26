import Foundation
import Security

final class KeychainHelper {
  static let shared = KeychainHelper()
  static let service = "com.sfx.legacyvault"
  static let encryptionKey = "encryption_passphrase"
  static let userSession = "user_auth_token"
  static let firstLaunchFlag = "first_launch_done"

  private func addItem(key: String, value: String) -> Bool {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]
    SecItemDelete(query as CFDictionary)
    return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
  }

  private func getItem(key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var result: AnyObject?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
          let data = result as? Data,
          let value = String(data: data, encoding: .utf8) else {
      return nil
    }
    return value
  }

  private func removeItem(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: key
    ]
    return SecItemDelete(query as CFDictionary) == errSecSuccess
  }

  func save(key: String, value: String) -> Bool { return addItem(key: key, value: value) }
  func load(key: String) -> String? { return getItem(key: key) }
  func remove(key: String) -> Bool { return removeItem(key: key) }

  var isAuthenticated: Bool { return load(key: KeychainHelper.userSession) != nil }
  var isFirstLaunch: Bool { return load(key: KeychainHelper.firstLaunchFlag) == nil }
  func markFirstLaunchComplete() { save(key: KeychainHelper.firstLaunchFlag, value: "true") }
  func clearAll() {
    for key in [KeychainHelper.encryptionKey, KeychainHelper.userSession, KeychainHelper.firstLaunchFlag] {
      remove(key: key)
    }
  }
}
