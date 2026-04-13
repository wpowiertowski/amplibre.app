import AppKit
import Foundation
import AmplibreCore

/// In-memory cache of parsed skin assets, implementing the SkinProvider protocol.
@Observable
public final class SkinCache: SkinProvider {
    private var spriteSet: SkinSpriteSet?
    private var fontAtlas: SkinFontAtlas?
    private var digitRenderer: SkinDigitRenderer?
    private var vizColors: [NSColor] = []
    public private(set) var playlistColors: PlaylistColors = .default
    private(set) var skinName: String = "Default"

    /// Load a skin from a .wsz file URL.
    public init() {}

    public func loadSkin(from url: URL) throws {
        let files = try WSZArchiveParser.parse(at: url)

        // Decode all BMPs
        var bitmaps: [String: CGImage] = [:]
        for (filename, data) in files where filename.hasSuffix(".bmp") {
            do {
                let image = try BMPDecoder.decode(data)

                // Apply transparency using magic color from pixel (0,0)
                let magic = try BMPDecoder.magicColor(from: data)
                if let transparent = image.applyingTransparency(magicColor: magic) {
                    bitmaps[filename] = transparent
                } else {
                    bitmaps[filename] = image
                }
            } catch {
                // Non-fatal: skip problematic BMPs
                continue
            }
        }

        // Extract sprites
        spriteSet = try SpriteExtractor.extractAll(from: bitmaps)

        // Font atlas from text.bmp
        if let textBmp = bitmaps["text.bmp"] {
            fontAtlas = SkinFontAtlas(from: textBmp)
        }

        // Digit renderer from numbers.bmp
        if let numbersBmp = bitmaps["numbers.bmp"] {
            digitRenderer = SkinDigitRenderer(from: numbersBmp)
        }

        // Parse configuration files
        if let pleditData = files["pledit.txt"] {
            playlistColors = SkinColorConfig.parsePlaylistColors(from: pleditData)
        }
        if let viscolorData = files["viscolor.txt"] {
            vizColors = SkinColorConfig.parseVisualizationColors(from: viscolorData)
        }

        skinName = url.deletingPathExtension().lastPathComponent
    }

    // MARK: - SkinProvider

    public func sprite(for element: SkinElement, state: SkinState) -> NSImage? {
        guard let cgImage = spriteSet?.sprite(for: element, state: state) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    public func volumeBackground(position: Int) -> NSImage? {
        // TODO: extract volume frames from volume.bmp
        nil
    }

    public func digit(_ value: Int) -> NSImage? {
        guard let cgImage = digitRenderer?.digit(value) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    public func character(_ char: Character) -> NSImage? {
        guard let cgImage = fontAtlas?.sprite(for: char) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    public func visualizationColor(index: Int) -> NSColor {
        guard index >= 0, index < vizColors.count else { return .green }
        return vizColors[index]
    }
}
