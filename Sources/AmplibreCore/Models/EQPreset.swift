import SwiftData
import Foundation

/// A 10-band equalizer preset, compatible with Winamp .eqf format.
@Model
final class EQPreset {
    var name: String
    /// Gain values for each of the 10 bands in dB (-12 to +12).
    /// Bands: 70, 180, 320, 600, 1K, 3K, 6K, 12K, 14K, 16K Hz
    var bands: [Float]
    /// Preamp gain in dB (-12 to +12).
    var preamp: Float
    var isBuiltIn: Bool

    init(
        name: String,
        bands: [Float] = Array(repeating: 0, count: 10),
        preamp: Float = 0,
        isBuiltIn: Bool = false
    ) {
        self.name = name
        self.bands = bands
        self.preamp = preamp
        self.isBuiltIn = isBuiltIn
    }
}
