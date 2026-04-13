import CoreGraphics
import Foundation
import AmplibreCore

/// Extracts individual UI element sprites from skin BMP sprite sheets
/// using the documented Winamp skin specification pixel coordinates.
struct SpriteExtractor {
    enum ExtractionError: Error {
        case bitmapNotFound(String)
        case decodeFailed(String)
    }

    /// Sprite coordinate definition.
    struct SpriteRect {
        let x: Int
        let y: Int
        let width: Int
        let height: Int

        var cgRect: CGRect {
            CGRect(x: x, y: y, width: width, height: height)
        }
    }

    // MARK: - Transport buttons (cbuttons.bmp: 136×18)

    /// Each button: 23×18, laid out horizontally. Row 0 = normal, Row 1 = pressed (offset y+18)
    static let transportButtons: [(element: SkinElement, normal: SpriteRect, pressed: SpriteRect)] = [
        (.transportPrevious, SpriteRect(x: 0, y: 0, width: 23, height: 18),   SpriteRect(x: 0, y: 18, width: 23, height: 18)),
        (.transportPlay,     SpriteRect(x: 23, y: 0, width: 23, height: 18),  SpriteRect(x: 23, y: 18, width: 23, height: 18)),
        (.transportPause,    SpriteRect(x: 46, y: 0, width: 23, height: 18),  SpriteRect(x: 46, y: 18, width: 23, height: 18)),
        (.transportStop,     SpriteRect(x: 69, y: 0, width: 23, height: 18),  SpriteRect(x: 69, y: 18, width: 23, height: 18)),
        (.transportNext,     SpriteRect(x: 92, y: 0, width: 22, height: 18),  SpriteRect(x: 92, y: 18, width: 22, height: 18)),
    ]

    // MARK: - Numbers (numbers.bmp: 99×13)

    /// Digits 0-9 are each 9×13, laid out horizontally.
    static func digitRect(_ digit: Int) -> SpriteRect {
        SpriteRect(x: digit * 9, y: 0, width: 9, height: 13)
    }

    /// Blank digit (after 9)
    static let digitBlank = SpriteRect(x: 90, y: 0, width: 9, height: 13)

    // MARK: - Text font (text.bmp: 155×18)

    /// Characters are 5×6 pixels each, in a grid.
    /// Row 0: A-Z (26 chars), Row 1: 0-9 + symbols
    static let charWidth = 5
    static let charHeight = 6

    // MARK: - Extraction

    /// Extract all sprites from a set of decoded skin BMPs.
    static func extractAll(from bitmaps: [String: CGImage]) throws -> SkinSpriteSet {
        var sprites: [SkinElement: [SkinState: CGImage]] = [:]

        // Transport buttons
        if let cbuttons = bitmaps["cbuttons.bmp"] {
            for button in transportButtons {
                if let normal = cbuttons.cropping(to: button.normal.cgRect) {
                    sprites[button.element, default: [:]][.normal] = normal
                }
                if let pressed = cbuttons.cropping(to: button.pressed.cgRect) {
                    sprites[button.element, default: [:]][.pressed] = pressed
                }
            }
        }

        // Main window background
        if let main = bitmaps["main.bmp"] {
            sprites[.mainBackground] = [.normal: main]
        }

        // Title bar
        if let titlebar = bitmaps["titlebar.bmp"] {
            if let active = titlebar.cropping(to: CGRect(x: 27, y: 0, width: 275, height: 14)) {
                sprites[.titleBarActive] = [.normal: active]
            }
            if let inactive = titlebar.cropping(to: CGRect(x: 27, y: 15, width: 275, height: 14)) {
                sprites[.titleBarInactive] = [.normal: inactive]
            }
        }

        // EQ background
        if let eqmain = bitmaps["eqmain.bmp"] {
            sprites[.eqBackground] = [.normal: eqmain]
        }

        return SkinSpriteSet(sprites: sprites)
    }
}

/// Holds the complete set of extracted sprites for a skin.
struct SkinSpriteSet {
    var sprites: [SkinElement: [SkinState: CGImage]]

    func sprite(for element: SkinElement, state: SkinState) -> CGImage? {
        sprites[element]?[state]
    }
}
