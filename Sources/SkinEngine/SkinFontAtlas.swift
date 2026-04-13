import CoreGraphics
import Foundation

/// Parses text.bmp into a character map for the scrolling title display.
///
/// The text.bmp sprite sheet contains characters in a grid layout:
/// - Each character is 5×6 pixels
/// - Row 0: A-Z (uppercase)
/// - Row 1: "0-9...
/// - Additional rows for lowercase and symbols
struct SkinFontAtlas {
    private var characters: [Character: CGImage] = [:]

    /// The character grid layout matching Winamp's text.bmp specification.
    private static let charMap: [[Character]] = [
        Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ\"@"),
        Array("0123456789….:()-'!_+\\/[]^&%"),
        Array(#"  {}$#ÀÖÜàöüÉéÈèÇçÊêÎîÂâ"#),
    ]

    let charWidth = 5
    let charHeight = 6

    init(from image: CGImage) {
        for (row, chars) in Self.charMap.enumerated() {
            for (col, char) in chars.enumerated() {
                let rect = CGRect(
                    x: col * charWidth,
                    y: row * charHeight,
                    width: charWidth,
                    height: charHeight
                )
                if let sprite = image.cropping(to: rect) {
                    characters[char] = sprite
                }
            }
        }
    }

    /// Get the sprite for a character (case-insensitive, uppercased).
    func sprite(for char: Character) -> CGImage? {
        characters[Character(char.uppercased())] ?? characters[" "]
    }

    /// Render a string as a composite CGImage.
    func renderString(_ text: String, maxWidth: Int? = nil) -> CGImage? {
        let chars = Array(text.uppercased())
        let totalWidth = chars.count * charWidth
        let width = maxWidth ?? totalWidth

        guard width > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: charHeight,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        for (i, char) in chars.enumerated() {
            let x = i * charWidth
            if x >= width { break }
            if let glyph = sprite(for: char) {
                context.draw(glyph, in: CGRect(x: x, y: 0, width: charWidth, height: charHeight))
            }
        }

        return context.makeImage()
    }
}
