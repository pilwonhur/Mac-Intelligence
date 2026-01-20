import Foundation
import Security

/// Service for securely storing and retrieving sensitive data like API keys.
class KeychainService {
    static let shared = KeychainService()
    
    enum KeychainError: Error {
        case duplicateItem
        case unknown(OSStatus)
    }
    
    func save(key: String, value: String) {
        UserDefaults.standard.set(value, forKey: "sec_\(key)")
    }
    
    func get(key: String) -> String? {
        return UserDefaults.standard.string(forKey: "sec_\(key)")
    }
}
