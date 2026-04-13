import AppKit
import Foundation

/// Identifier for a skin UI element.
public enum SkinElement: String, Sendable, Hashable {
    case mainBackground
    case titleBarActive
    case titleBarInactive
    case transportPrevious
    case transportPlay
    case transportPause
    case transportStop
    case transportNext
    case volumeThumb
    case balanceThumb
    case positionThumb
    case shuffleButton
    case repeatButton
    case eqToggle
    case playlistToggle
    case monoIndicator
    case stereoIndicator
    case playIndicator
    case pauseIndicator
    case stopIndicator
    case eqBackground
    case playlistBackground
}

/// State of an interactive skin element.
public enum SkinState: String, Sendable, Hashable {
    case normal
    case pressed
    case active
    case inactive
    case on
    case off
}

/// Protocol for accessing skin graphical assets.
public protocol SkinProvider {
    func sprite(for element: SkinElement, state: SkinState) -> NSImage?
    func volumeBackground(position: Int) -> NSImage?
    func digit(_ value: Int) -> NSImage?
    func character(_ char: Character) -> NSImage?
    func visualizationColor(index: Int) -> NSColor
    var playlistColors: PlaylistColors { get }
}

/// Colors parsed from pledit.txt.
public struct PlaylistColors: Sendable {
    public var normalText: NSColor
    public var currentText: NSColor
    public var normalBackground: NSColor
    public var selectedBackground: NSColor
    public var fontName: String

    public init(
        normalText: NSColor,
        currentText: NSColor,
        normalBackground: NSColor,
        selectedBackground: NSColor,
        fontName: String
    ) {
        self.normalText = normalText
        self.currentText = currentText
        self.normalBackground = normalBackground
        self.selectedBackground = selectedBackground
        self.fontName = fontName
    }

    public static let `default` = PlaylistColors(
        normalText: .green,
        currentText: .white,
        normalBackground: .black,
        selectedBackground: .darkGray,
        fontName: "Arial"
    )
}
