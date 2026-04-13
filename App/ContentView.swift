import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Amplibre")
                .font(.system(.title, design: .monospaced))
            Text("Loading skin engine…")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(width: 275 * 2, height: 116 * 2)
    }
}
