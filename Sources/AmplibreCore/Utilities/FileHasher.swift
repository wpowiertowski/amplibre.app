import Foundation
import Crypto

/// SHA-256 file hashing for export verification.
public struct FileHasher: Sendable {
    /// Compute the SHA-256 hash of a file at the given URL.
    public nonisolated static func sha256(of url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Verify that a file matches an expected SHA-256 hash.
    public nonisolated static func verify(_ url: URL, expectedHash: String) throws -> Bool {
        let actual = try sha256(of: url)
        return actual == expectedHash
    }
}
