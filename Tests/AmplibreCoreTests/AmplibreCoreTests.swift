import Testing
import Foundation
@testable import AmplibreCore

@Suite("AmplibreCore")
struct AmplibreCoreTests {
    @Test("FileHasher produces consistent SHA-256")
    func fileHasherConsistency() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-hash.txt")
        try "hello world".data(using: .utf8)!.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let hash1 = try FileHasher.sha256(of: tempURL)
        let hash2 = try FileHasher.sha256(of: tempURL)
        #expect(hash1 == hash2)
        #expect(hash1 == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9")
    }

    @Test("Preferences defaults")
    func preferencesDefaults() {
        #expect(Preferences.skinScale >= 1)
        #expect(Preferences.dockingSnapDistance > 0)
    }
}
