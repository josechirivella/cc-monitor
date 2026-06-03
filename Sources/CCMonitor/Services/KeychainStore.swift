import Foundation
import Security

/// Secure wrapper around macOS Keychain APIs for storing/retrieving the session key.
struct KeychainStore {
    private static let service = "com.ccmonitor.app"
    private static let account = "sessionKey"

    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case itemNotFound

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                "Failed to save session key to Keychain (status: \(status))"
            case .loadFailed(let status):
                "Failed to load session key from Keychain (status: \(status))"
            case .deleteFailed(let status):
                "Failed to delete session key from Keychain (status: \(status))"
            case .itemNotFound:
                "Session key not found in Keychain"
            }
        }
    }

    /// Save (or update) the session key to Keychain.
    /// Deletes any existing entry first to avoid duplicate item errors.
    func save(_ key: String) throws {
        // Delete existing entry to avoid SecItemAdd errors on duplicate items
        _ = try? delete()

        let data = key.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Load the session key from Keychain.
    func load() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.loadFailed(status)
        }

        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.loadFailed(status)
        }

        return key
    }

    /// Delete the session key from Keychain.
    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
