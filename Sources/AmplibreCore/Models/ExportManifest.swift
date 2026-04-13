import SwiftData
import Foundation

/// Record of an export operation to an external volume.
@Model
final class ExportManifest {
    var volumeUUID: String
    var volumeName: String
    var lastSyncDate: Date
    var trackCount: Int
    var totalSizeBytes: Int64

    init(
        volumeUUID: String,
        volumeName: String,
        lastSyncDate: Date = .now,
        trackCount: Int = 0,
        totalSizeBytes: Int64 = 0
    ) {
        self.volumeUUID = volumeUUID
        self.volumeName = volumeName
        self.lastSyncDate = lastSyncDate
        self.trackCount = trackCount
        self.totalSizeBytes = totalSizeBytes
    }
}
