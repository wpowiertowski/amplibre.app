import Foundation
@preconcurrency import KeychainAccess

/// Wrapper around KeychainAccess for storing OAuth tokens and session keys.
struct KeychainManager: Sendable {
    private nonisolated(unsafe) static let keychain = Keychain(service: "app.amplibre.Amplibre")

    static func set(_ value: String, for key: String) throws {
        try keychain.set(value, key: key)
    }

    static func get(_ key: String) throws -> String? {
        try keychain.get(key)
    }

    static func remove(_ key: String) throws {
        try keychain.remove(key)
    }
}
