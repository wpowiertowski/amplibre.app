import AppKit
import Foundation
import AmplibreCore

/// Parses pledit.txt and viscolor.txt skin configuration files.
struct SkinColorConfig {
    /// Parse pledit.txt (INI format) for playlist colors.
    static func parsePlaylistColors(from data: Data) -> PlaylistColors {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return .default
        }

        var values: [String: String] = [:]
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let equalsIndex = trimmed.firstIndex(of: "=") {
                let key = trimmed[trimmed.startIndex..<equalsIndex]
                    .trimmingCharacters(in: .whitespaces).lowercased()
                let value = trimmed[trimmed.index(after: equalsIndex)...]
                    .trimmingCharacters(in: .whitespaces)
                values[key] = value
            }
        }

        return PlaylistColors(
            normalText: parseColor(values["normal"]) ?? .green,
            currentText: parseColor(values["current"]) ?? .white,
            normalBackground: parseColor(values["normalbg"]) ?? .black,
            selectedBackground: parseColor(values["selectedbg"]) ?? .darkGray,
            fontName: values["font"] ?? "Arial"
        )
    }

    /// Parse viscolor.txt — 24 RGB triplets for visualization colors.
    static func parseVisualizationColors(from data: Data) -> [NSColor] {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return defaultVisualizationColors
        }

        var colors: [NSColor] = []
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("//") || trimmed.hasPrefix(";") { continue }

            let components = trimmed.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if components.count >= 3,
               let r = Int(components[0]),
               let g = Int(components[1]),
               let b = Int(components[2]) {
                colors.append(NSColor(
                    red: CGFloat(r) / 255,
                    green: CGFloat(g) / 255,
                    blue: CGFloat(b) / 255,
                    alpha: 1
                ))
            }

            if colors.count >= 24 { break }
        }

        // Pad with defaults if fewer than 24
        while colors.count < 24 {
            colors.append(.green)
        }

        return colors
    }

    // MARK: - Private

    private static func parseColor(_ hex: String?) -> NSColor? {
        guard let hex = hex else { return nil }
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else { return nil }

        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        return NSColor(red: r, green: g, blue: b, alpha: 1)
    }

    private static var defaultVisualizationColors: [NSColor] {
        (0..<24).map { i in
            let hue = CGFloat(i) / 24.0
            return NSColor(hue: hue * 0.33, saturation: 1, brightness: 1, alpha: 1)
        }
    }
}
