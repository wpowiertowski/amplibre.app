import Foundation

/// UserDefaults wrapper for app preferences.
public struct Preferences {
    private nonisolated(unsafe) static let defaults = UserDefaults.standard

    // MARK: - Playback

    public static var crossfadeDuration: TimeInterval {
        get { defaults.double(forKey: "crossfadeDuration").clamped(to: 0...12) }
        set { defaults.set(newValue, forKey: "crossfadeDuration") }
    }

    public static var replayGainMode: ReplayGainMode {
        get { ReplayGainMode(rawValue: defaults.string(forKey: "replayGainMode") ?? "") ?? .off }
        set { defaults.set(newValue.rawValue, forKey: "replayGainMode") }
    }

    // MARK: - Skin

    public static var currentSkinName: String? {
        get { defaults.string(forKey: "currentSkinName") }
        set { defaults.set(newValue, forKey: "currentSkinName") }
    }

    public static var skinScale: Int {
        get { max(1, defaults.integer(forKey: "skinScale")) }
        set { defaults.set(newValue, forKey: "skinScale") }
    }

    // MARK: - Docking

    public static var dockingSnapDistance: CGFloat {
        get {
            let val = defaults.double(forKey: "dockingSnapDistance")
            return val > 0 ? CGFloat(val) : 10
        }
        set { defaults.set(Double(newValue), forKey: "dockingSnapDistance") }
    }
}

public enum ReplayGainMode: String, Sendable {
    case off
    case track
    case album
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
