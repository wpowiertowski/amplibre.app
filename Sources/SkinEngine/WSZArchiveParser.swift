import Foundation
import ZIPFoundation

/// Parses Winamp Skin ZIP (.wsz) archives.
///
/// Handles case-insensitive filename matching and skins with files
/// at the archive root or within a single subdirectory.
struct WSZArchiveParser {
    enum ParseError: Error {
        case cannotOpenArchive
        case fileNotFound(String)
        case invalidSkin(String)
    }

    /// All known skin filenames (lowercase).
    static let requiredFiles = [
        "main.bmp", "titlebar.bmp", "cbuttons.bmp", "shufrep.bmp",
        "volume.bmp", "posbar.bmp", "monoster.bmp", "playpaus.bmp",
        "numbers.bmp", "text.bmp"
    ]

    static let optionalFiles = [
        "balance.bmp", "eqmain.bmp", "eq_ex.bmp", "pledit.bmp",
        "pledit.txt", "viscolor.txt", "region.txt"
    ]

    /// Extract all skin files from a .wsz archive.
    /// Returns a dictionary mapping lowercase filenames to their data.
    static func parse(at url: URL) throws -> [String: Data] {
        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ParseError.cannotOpenArchive
        }

        // Build a case-insensitive lookup of all entries
        var entryMap: [String: Entry] = [:]
        var subdirectoryPrefix: String?

        for entry in archive {
            let path = entry.path
            let components = path.split(separator: "/")

            if components.count == 1 {
                entryMap[path.lowercased()] = entry
            } else if components.count == 2 {
                // File inside a single subdirectory
                let filename = String(components[1]).lowercased()
                entryMap[filename] = entry
                if subdirectoryPrefix == nil {
                    subdirectoryPrefix = String(components[0])
                }
            }
        }

        // Extract files
        var result: [String: Data] = [:]
        let allKnownFiles = requiredFiles + optionalFiles

        for filename in allKnownFiles {
            if let entry = entryMap[filename] {
                var data = Data()
                _ = try archive.extract(entry) { chunk in
                    data.append(chunk)
                }
                result[filename] = data
            }
        }

        // Verify minimum required files
        let missingRequired = requiredFiles.filter { result[$0] == nil }
        if !missingRequired.isEmpty {
            throw ParseError.invalidSkin("Missing required files: \(missingRequired.joined(separator: ", "))")
        }

        return result
    }
}
