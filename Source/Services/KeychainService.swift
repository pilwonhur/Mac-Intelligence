import Foundation
import Security

/// Stores API keys in the login keychain.
///
/// Earlier builds wrote keys to UserDefaults in plain text under a `sec_` prefix; `get`
/// still reads those and migrates them into the keychain on first access, so upgrading
/// does not silently lose a key the user already entered.
class KeychainService {
    static let shared = KeychainService()

    private let service = "com.pilwonhur.MacIntelligence"

    func save(key: String, value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        guard !value.isEmpty else {
            SecItemDelete(query as CFDictionary)
            legacyClear(key)
            return
        }

        let data = Data(value.utf8)
        let status = SecItemUpdate(query as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(insert as CFDictionary, nil)
        }
        legacyClear(key)
    }

    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        // Migrate a key written by an earlier plain-text build.
        if let legacy = UserDefaults.standard.string(forKey: "sec_\(key)"), !legacy.isEmpty {
            save(key: key, value: legacy)
            return legacy
        }
        return nil
    }

    private func legacyClear(_ key: String) {
        UserDefaults.standard.removeObject(forKey: "sec_\(key)")
    }
}
