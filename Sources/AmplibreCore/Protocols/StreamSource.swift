import Foundation

/// Protocol abstracting a streaming music source (Bandcamp, Apple Music).
protocol StreamSource: Sendable {
    var sourceName: String { get }
    func authenticate() async throws
    func search(query: String) async throws -> [LibraryItem]
    func streamURL(for item: LibraryItem) async throws -> URL
}
