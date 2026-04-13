import CoreGraphics
import Foundation

extension CGImage {
    /// Create a new image with a specific color replaced by transparency.
    public func applyingTransparency(magicColor: (UInt8, UInt8, UInt8)) -> CGImage? {
        let width = self.width
        let height = self.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        for i in 0..<(width * height) {
            let offset = i * bytesPerPixel
            if pixels[offset] == magicColor.0
                && pixels[offset + 1] == magicColor.1
                && pixels[offset + 2] == magicColor.2 {
                pixels[offset + 3] = 0 // set alpha to transparent
            }
        }

        return context.makeImage()
    }
}
