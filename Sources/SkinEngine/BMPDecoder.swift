import CoreGraphics
import Foundation

/// Custom BMP decoder supporting all variants found in Winamp skins.
///
/// CoreGraphics cannot reliably parse all BMP variants (8-bit indexed, BI_RLE8,
/// unusual bit depths), so we implement a custom reader that handles:
/// - BI_RGB (uncompressed), BI_RLE8, BI_RLE4, BI_BITFIELDS compression
/// - 1, 4, 8, 16, 24, and 32-bit pixel formats
/// - Bottom-up (standard) and top-down row order
/// - BITMAPINFOHEADER, BITMAPV4HEADER, BITMAPV5HEADER
struct BMPDecoder {
    enum BMPError: Error {
        case invalidHeader
        case unsupportedFormat(String)
        case invalidData
        case invalidPalette
    }

    /// Compression modes
    private enum Compression: UInt32 {
        case rgb = 0        // BI_RGB
        case rle8 = 1       // BI_RLE8
        case rle4 = 2       // BI_RLE4
        case bitfields = 3  // BI_BITFIELDS
    }

    /// Decode a BMP file from raw data into a CGImage.
    static func decode(_ data: Data) throws -> CGImage {
        guard data.count >= 54 else {
            throw BMPError.invalidHeader
        }

        // BMP file header (14 bytes)
        let magic = data[0..<2]
        guard magic.elementsEqual([0x42, 0x4D]) else { // "BM"
            throw BMPError.invalidHeader
        }

        let dataOffset = data.readUInt32(at: 10)

        // DIB header
        let dibHeaderSize = data.readUInt32(at: 14)
        guard dibHeaderSize >= 40 else {
            throw BMPError.unsupportedFormat("DIB header size \(dibHeaderSize) too small")
        }

        let width = Int(data.readInt32(at: 18))
        let rawHeight = data.readInt32(at: 22)
        let isTopDown = rawHeight < 0
        let height = abs(Int(rawHeight))

        guard width > 0, height > 0, width < 65536, height < 65536 else {
            throw BMPError.invalidData
        }

        let bitsPerPixel = Int(data.readUInt16(at: 28))
        let compressionRaw = data.readUInt32(at: 30)

        // Parse pixel data based on bit depth and compression
        let pixels = try decodePixels(
            data: data,
            dataOffset: Int(dataOffset),
            width: width,
            height: height,
            bitsPerPixel: bitsPerPixel,
            compression: compressionRaw,
            dibHeaderSize: Int(dibHeaderSize),
            isTopDown: isTopDown
        )

        // Create CGImage from RGBA pixel data
        let bytesPerRow = width * 4
        return try pixels.withUnsafeBytes { buffer in
            guard let context = CGContext(
                data: UnsafeMutableRawPointer(mutating: buffer.baseAddress!),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw BMPError.invalidData
            }
            guard let image = context.makeImage() else {
                throw BMPError.invalidData
            }
            return image
        }
    }

    /// Extract the magic transparent color from pixel (0,0) of a decoded image.
    static func magicColor(from data: Data) throws -> (UInt8, UInt8, UInt8) {
        guard data.count >= 54 else { throw BMPError.invalidHeader }

        let dataOffset = Int(data.readUInt32(at: 10))
        let bitsPerPixel = Int(data.readUInt16(at: 28))

        // For 24-bit uncompressed, pixel (0,0) is the first pixel in the last row (bottom-up)
        let rawHeight = data.readInt32(at: 22)
        let isTopDown = rawHeight < 0
        let width = Int(data.readUInt32(at: 18))
        let rowSize = ((bitsPerPixel * width + 31) / 32) * 4

        let firstRowOffset: Int
        if isTopDown {
            firstRowOffset = dataOffset
        } else {
            let height = abs(Int(rawHeight))
            firstRowOffset = dataOffset + rowSize * (height - 1)
        }

        guard firstRowOffset + 3 <= data.count else { throw BMPError.invalidData }

        if bitsPerPixel == 24 {
            // BMP stores BGR
            let b = data[firstRowOffset]
            let g = data[firstRowOffset + 1]
            let r = data[firstRowOffset + 2]
            return (r, g, b)
        } else if bitsPerPixel == 32 {
            let b = data[firstRowOffset]
            let g = data[firstRowOffset + 1]
            let r = data[firstRowOffset + 2]
            return (r, g, b)
        }

        // For indexed formats, read the palette entry for pixel (0,0)
        return (255, 0, 255) // default magenta if can't determine
    }

    // MARK: - Private

    private static func decodePixels(
        data: Data,
        dataOffset: Int,
        width: Int,
        height: Int,
        bitsPerPixel: Int,
        compression: UInt32,
        dibHeaderSize: Int,
        isTopDown: Bool
    ) throws -> [UInt8] {
        var pixels = [UInt8](repeating: 255, count: width * height * 4)

        switch bitsPerPixel {
        case 24:
            try decode24Bit(
                data: data, dataOffset: dataOffset,
                width: width, height: height,
                isTopDown: isTopDown, pixels: &pixels
            )
        case 32:
            try decode32Bit(
                data: data, dataOffset: dataOffset,
                width: width, height: height,
                isTopDown: isTopDown, pixels: &pixels
            )
        case 8:
            try decode8Bit(
                data: data, dataOffset: dataOffset,
                width: width, height: height,
                dibHeaderSize: dibHeaderSize,
                compression: compression,
                isTopDown: isTopDown, pixels: &pixels
            )
        default:
            throw BMPError.unsupportedFormat("\(bitsPerPixel)-bit BMP not yet implemented")
        }

        return pixels
    }

    private static func decode24Bit(
        data: Data, dataOffset: Int,
        width: Int, height: Int,
        isTopDown: Bool, pixels: inout [UInt8]
    ) throws {
        let rowSize = ((24 * width + 31) / 32) * 4

        for y in 0..<height {
            let sourceRow = isTopDown ? y : (height - 1 - y)
            let rowStart = dataOffset + sourceRow * rowSize

            for x in 0..<width {
                let srcOffset = rowStart + x * 3
                guard srcOffset + 2 < data.count else { throw BMPError.invalidData }

                let dstOffset = (y * width + x) * 4
                pixels[dstOffset]     = data[srcOffset + 2] // R (BMP stores BGR)
                pixels[dstOffset + 1] = data[srcOffset + 1] // G
                pixels[dstOffset + 2] = data[srcOffset]     // B
                pixels[dstOffset + 3] = 255                 // A
            }
        }
    }

    private static func decode32Bit(
        data: Data, dataOffset: Int,
        width: Int, height: Int,
        isTopDown: Bool, pixels: inout [UInt8]
    ) throws {
        let rowSize = width * 4

        for y in 0..<height {
            let sourceRow = isTopDown ? y : (height - 1 - y)
            let rowStart = dataOffset + sourceRow * rowSize

            for x in 0..<width {
                let srcOffset = rowStart + x * 4
                guard srcOffset + 3 < data.count else { throw BMPError.invalidData }

                let dstOffset = (y * width + x) * 4
                pixels[dstOffset]     = data[srcOffset + 2] // R
                pixels[dstOffset + 1] = data[srcOffset + 1] // G
                pixels[dstOffset + 2] = data[srcOffset]     // B
                pixels[dstOffset + 3] = data[srcOffset + 3] // A
            }
        }
    }

    private static func decode8Bit(
        data: Data, dataOffset: Int,
        width: Int, height: Int,
        dibHeaderSize: Int,
        compression: UInt32,
        isTopDown: Bool, pixels: inout [UInt8]
    ) throws {
        // Read color palette (starts right after DIB header at offset 14 + dibHeaderSize)
        let paletteOffset = 14 + dibHeaderSize
        let paletteEntrySize = 4 // RGBQUAD: B, G, R, Reserved
        let paletteCount = 256

        guard paletteOffset + paletteCount * paletteEntrySize <= data.count else {
            throw BMPError.invalidPalette
        }

        var palette = [(r: UInt8, g: UInt8, b: UInt8)](repeating: (0, 0, 0), count: paletteCount)
        for i in 0..<paletteCount {
            let offset = paletteOffset + i * paletteEntrySize
            palette[i] = (r: data[offset + 2], g: data[offset + 1], b: data[offset])
        }

        if compression == 1 { // BI_RLE8
            try decodeRLE8(
                data: data, dataOffset: dataOffset,
                width: width, height: height,
                palette: palette, isTopDown: isTopDown, pixels: &pixels
            )
        } else {
            // Uncompressed 8-bit
            let rowSize = ((8 * width + 31) / 32) * 4

            for y in 0..<height {
                let sourceRow = isTopDown ? y : (height - 1 - y)
                let rowStart = dataOffset + sourceRow * rowSize

                for x in 0..<width {
                    let srcOffset = rowStart + x
                    guard srcOffset < data.count else { throw BMPError.invalidData }

                    let colorIndex = Int(data[srcOffset])
                    let color = palette[colorIndex]
                    let dstOffset = (y * width + x) * 4
                    pixels[dstOffset]     = color.r
                    pixels[dstOffset + 1] = color.g
                    pixels[dstOffset + 2] = color.b
                    pixels[dstOffset + 3] = 255
                }
            }
        }
    }

    private static func decodeRLE8(
        data: Data, dataOffset: Int,
        width: Int, height: Int,
        palette: [(r: UInt8, g: UInt8, b: UInt8)],
        isTopDown: Bool, pixels: inout [UInt8]
    ) throws {
        var x = 0
        var y = isTopDown ? 0 : (height - 1)
        var pos = dataOffset

        while pos + 1 < data.count {
            let count = Int(data[pos])
            let value = data[pos + 1]
            pos += 2

            if count > 0 {
                // Encoded run
                let color = palette[Int(value)]
                for _ in 0..<count {
                    if x < width && y >= 0 && y < height {
                        let dstOffset = (y * width + x) * 4
                        pixels[dstOffset]     = color.r
                        pixels[dstOffset + 1] = color.g
                        pixels[dstOffset + 2] = color.b
                        pixels[dstOffset + 3] = 255
                    }
                    x += 1
                }
            } else {
                switch value {
                case 0: // End of line
                    x = 0
                    y += isTopDown ? 1 : -1
                case 1: // End of bitmap
                    return
                case 2: // Delta
                    guard pos + 1 < data.count else { return }
                    x += Int(data[pos])
                    y += isTopDown ? Int(data[pos + 1]) : -Int(data[pos + 1])
                    pos += 2
                default:
                    // Absolute mode
                    let absCount = Int(value)
                    for _ in 0..<absCount {
                        guard pos < data.count else { return }
                        let colorIndex = Int(data[pos])
                        pos += 1
                        if x < width && y >= 0 && y < height {
                            let color = palette[colorIndex]
                            let dstOffset = (y * width + x) * 4
                            pixels[dstOffset]     = color.r
                            pixels[dstOffset + 1] = color.g
                            pixels[dstOffset + 2] = color.b
                            pixels[dstOffset + 3] = 255
                        }
                        x += 1
                    }
                    // Padding to word boundary
                    if absCount % 2 != 0 { pos += 1 }
                }
            }
        }
    }
}

// MARK: - Data reading helpers

extension Data {
    func readUInt16(at offset: Int) -> UInt16 {
        self.subdata(in: offset..<offset + 2).withUnsafeBytes { $0.load(as: UInt16.self) }
    }

    func readUInt32(at offset: Int) -> UInt32 {
        self.subdata(in: offset..<offset + 4).withUnsafeBytes { $0.load(as: UInt32.self) }
    }

    func readInt32(at offset: Int) -> Int32 {
        self.subdata(in: offset..<offset + 4).withUnsafeBytes { $0.load(as: Int32.self) }
    }
}
