import SwiftData
import Foundation

/// Provenance of a library item — where it came from.
public enum LibraryItemProvenance: String, Codable {
    case local        // manually added local file
    case purchased    // iTunes Store purchase (DRM-free)
    case matched      // iTunes Match upgraded
    case ripped       // CD rip
    case appleMusic   // Apple Music streaming (DRM)
    case bandcamp     // Bandcamp purchase/streaming
}

/// Unified music library item merging ITunesLibrary and MusicKit sources.
@Model
public final class LibraryItem {
    var title: String
    var artist: String
    var album: String
    var genre: String
    var trackNumber: Int
    var discNumber: Int
    var duration: TimeInterval
    var year: Int
    var playCount: Int
    var rating: Int
    var dateAdded: Date
    var dateLastPlayed: Date?
    var fileURL: URL?
    var provenance: LibraryItemProvenance
    var isExportable: Bool

    public init(
        title: String,
        artist: String = "",
        album: String = "",
        genre: String = "",
        trackNumber: Int = 0,
        discNumber: Int = 1,
        duration: TimeInterval = 0,
        year: Int = 0,
        playCount: Int = 0,
        rating: Int = 0,
        dateAdded: Date = .now,
        dateLastPlayed: Date? = nil,
        fileURL: URL? = nil,
        provenance: LibraryItemProvenance = .local,
        isExportable: Bool = true
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.duration = duration
        self.year = year
        self.playCount = playCount
        self.rating = rating
        self.dateAdded = dateAdded
        self.dateLastPlayed = dateLastPlayed
        self.fileURL = fileURL
        self.provenance = provenance
        self.isExportable = isExportable
    }
}
