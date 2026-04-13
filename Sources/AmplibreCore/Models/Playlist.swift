import SwiftData
import Foundation

/// A user-created or imported playlist.
@Model
final class Playlist {
    var name: String
    var items: [LibraryItem]
    var dateCreated: Date
    var dateModified: Date

    init(
        name: String,
        items: [LibraryItem] = [],
        dateCreated: Date = .now,
        dateModified: Date = .now
    ) {
        self.name = name
        self.items = items
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
}
