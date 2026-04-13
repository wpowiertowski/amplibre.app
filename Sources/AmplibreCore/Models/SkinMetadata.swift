import SwiftData
import Foundation

/// Metadata for an installed Winamp skin (.wsz).
@Model
final class SkinMetadata {
    var name: String
    var fileName: String
    var fileURL: URL
    var dateInstalled: Date
    var isDefault: Bool

    init(
        name: String,
        fileName: String,
        fileURL: URL,
        dateInstalled: Date = .now,
        isDefault: Bool = false
    ) {
        self.name = name
        self.fileName = fileName
        self.fileURL = fileURL
        self.dateInstalled = dateInstalled
        self.isDefault = isDefault
    }
}
