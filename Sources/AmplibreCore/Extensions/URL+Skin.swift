import Foundation

extension URL {
    /// The Application Support directory for Amplibre skins.
    public static var skinsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Amplibre/Skins", isDirectory: true)
    }

    /// Ensure the skins directory exists.
    public static func ensureSkinsDirectory() throws {
        try FileManager.default.createDirectory(at: skinsDirectory, withIntermediateDirectories: true)
    }
}
