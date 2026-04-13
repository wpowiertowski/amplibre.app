import SwiftUI

/// Placeholder for the SwiftUI library browser with NavigationSplitView.
/// Will be implemented in Milestone 3 (Week 10).
struct LibraryBrowserView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Text("Artists")
                Text("Albums")
                Text("Genres")
                Text("Playlists")
            }
            .navigationTitle("Library")
        } detail: {
            Text("Select a category")
                .foregroundStyle(.secondary)
        }
    }
}
