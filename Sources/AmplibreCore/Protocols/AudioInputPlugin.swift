import Foundation

/// Plugin protocol for custom audio input sources.
protocol AudioInputPlugin: Sendable {
    var pluginName: String { get }
    var supportedExtensions: [String] { get }
    func canHandle(url: URL) -> Bool
}
