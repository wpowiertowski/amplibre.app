import SwiftData
import Foundation

/// A queued Last.fm scrobble entry, persisted for offline resilience.
@Model
final class ScrobbleEntry {
    var trackTitle: String
    var artist: String
    var album: String
    var duration: Int
    var timestamp: Date
    var isFlushed: Bool

    init(
        trackTitle: String,
        artist: String,
        album: String = "",
        duration: Int = 0,
        timestamp: Date = .now,
        isFlushed: Bool = false
    ) {
        self.trackTitle = trackTitle
        self.artist = artist
        self.album = album
        self.duration = duration
        self.timestamp = timestamp
        self.isFlushed = isFlushed
    }
}
