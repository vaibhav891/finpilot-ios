//
//  KeychainHelper.swift
//  FinPilot
//

import Foundation
import Security

public enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item was not found in the Keychain."
        case .duplicateItem:
            return "Item already exists in the Keychain."
        case .unexpectedData:
            return "Keychain returned unexpected data format."
        case .unhandledError(let status):
            return "Keychain error with OSStatus: \(status)."
        }
    }
}

public final class KeychainHelper {
    public static let shared = KeychainHelper()
    private let serviceName = "com.finpilot.app.auth"

    private init() {}

    public func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func save(key: String, string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        try save(key: key, data: data)
    }

    public func readData(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unhandledError(status: status)
        }
        return data
    }

    public func readString(key: String) throws -> String {
        let data = try readData(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }

    public func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    public func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(query as CFDictionary)
    }
}
