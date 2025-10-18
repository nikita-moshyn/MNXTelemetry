//
//  TelemetryIdentity.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 02/10/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation
import Security

/// Stores and manages a persistent, anonymous user identifier in the Keychain.
public enum TelemetryIdentity {
    // In-memory cache to avoid repeated Keychain hops.
    nonisolated(unsafe) private static var cachedID: String?

    // Keychain record identifiers
    private static let service: String = Bundle.main.bundleIdentifier ?? "com.MNXTelemetry.framework"
    private static let account: String = "mnx.telemetry.user_id"

    /// Returns the current user id, creating + storing a new one in the Keychain if missing.
    @discardableResult
    public static func setUser() -> String {
        if let cachedID { return cachedID }
        if let existing = try? readFromKeychain() {
            cachedID = existing
            // Optionally inform analytics crash providers:
            Telemetry.shared.setUser(id: existing)
            return existing
        }
        let fresh = UUID().uuidString
        do {
            try saveToKeychain(fresh)
            cachedID = fresh
            Telemetry.shared.setUser(id: fresh)
            return fresh
        } catch {
            // As a fallback, keep it in memory for this run only.
            cachedID = fresh
            Telemetry.shared.setUser(id: fresh, properties: ["persisted_in_keychain": false])
            return fresh
        }
    }

    /// Deletes the stored id from the Keychain. Returns the *new* generated id.
    /// Call this for your "Delete ID" button action.
    @discardableResult
    public static func reset() -> String {
        _ = try? deleteFromKeychain()
        cachedID = nil
        return setUser() // Auto-generate and store a new id, and set it on Telemetry.
    }

    // MARK: - Keychain primitives

    /// Save the id into the Keychain (overwrites if exists).
    private static func saveToKeychain(_ id: String) throws {
        let data = Data(id.utf8)

        // Attempt add
        var add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            // Not synced to iCloud Keychain; survives app reinstalls on the same device.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
            kSecValueData as String: data
        ]

        let addStatus = SecItemAdd(add as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            // If exists, update
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            let update: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if addStatus != errSecSuccess {
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }

    /// Read the id from the Keychain (nil if not found).
    private static func readFromKeychain() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data, let id = String(data: data, encoding: .utf8) else {
            if status == errSecSuccess { return nil } // Decoding issue
            throw KeychainError.unexpectedStatus(status)
        }
        return id
    }

    /// Delete the id from the Keychain (no error if missing).
    @discardableResult
    private static func deleteFromKeychain() throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound { return false }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        return true
    }

    private enum KeychainError: Error {
        case unexpectedStatus(OSStatus)
    }
}
