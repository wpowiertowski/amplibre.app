import CoreGraphics
import Foundation

/// Renders the time display using numbers.bmp digit sprites.
struct SkinDigitRenderer {
    private var digits: [Int: CGImage] = [:]
    private var blankDigit: CGImage?
    private var minusSign: CGImage?

    let digitWidth = 9
    let digitHeight = 13

    init(from image: CGImage) {
        // Digits 0-9 are each 9×13, horizontally
        for i in 0...9 {
            let rect = CGRect(x: i * digitWidth, y: 0, width: digitWidth, height: digitHeight)
            digits[i] = image.cropping(to: rect)
        }
        // Blank at position 10
        blankDigit = image.cropping(to: CGRect(x: 90, y: 0, width: digitWidth, height: digitHeight))
        // Minus at position 11 (if present in wider numbers.bmp)
        if image.width > 99 {
            minusSign = image.cropping(to: CGRect(x: 99, y: 0, width: digitWidth, height: digitHeight))
        }
    }

    /// Render a time value as "M:SS" or "-M:SS" using digit sprites.
    func renderTime(seconds: Int, showRemaining: Bool = false) -> CGImage? {
        let totalSeconds = abs(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60

        let components: [CGImage?]
        if showRemaining {
            components = [
                minusSign ?? blankDigit,
                digits[minutes / 10],
                digits[minutes % 10],
                blankDigit, // colon position (rendered separately in real skin)
                digits[secs / 10],
                digits[secs % 10],
            ]
        } else {
            components = [
                digits[minutes / 10],
                digits[minutes % 10],
                blankDigit,
                digits[secs / 10],
                digits[secs % 10],
            ]
        }

        let totalWidth = components.count * digitWidth
        guard let context = CGContext(
            data: nil,
            width: totalWidth,
            height: digitHeight,
            bitsPerComponent: 8,
            bytesPerRow: totalWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        for (i, digitImage) in components.enumerated() {
            if let img = digitImage {
                context.draw(img, in: CGRect(x: i * digitWidth, y: 0, width: digitWidth, height: digitHeight))
            }
        }

        return context.makeImage()
    }

    func digit(_ value: Int) -> CGImage? {
        digits[value]
    }
}
