import SwiftUI
import AmplibreCore
import SkinEngine
import AudioCore

/// The main Winamp-style window showing transport controls, time display,
/// title ticker, volume/balance sliders, and visualization area.
///
/// Dimensions: 275×116 pixels at 1x, with integer scaling support.
struct MainWindowView: View {
    let skinCache: SkinCache
    let playbackState: PlaybackState
    var scale: Int = 2

    /// Base Winamp main window dimensions
    private let baseWidth: CGFloat = 275
    private let baseHeight: CGFloat = 116

    var body: some View {
        ZStack {
            // Background skin image
            if let bg = skinCache.sprite(for: .mainBackground, state: .normal) {
                Image(nsImage: bg)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: baseWidth * CGFloat(scale), height: baseHeight * CGFloat(scale))
            } else {
                Rectangle()
                    .fill(.black)
                    .frame(width: baseWidth * CGFloat(scale), height: baseHeight * CGFloat(scale))
            }

            // Title bar overlay
            VStack(spacing: 0) {
                titleBar
                Spacer()
            }

            // Transport controls (bottom area)
            VStack {
                Spacer()
                transportControls
                    .padding(.bottom, 4 * CGFloat(scale))
            }
        }
        .frame(width: baseWidth * CGFloat(scale), height: baseHeight * CGFloat(scale))
    }

    private var titleBar: some View {
        HStack {
            if let titlebar = skinCache.sprite(for: .titleBarActive, state: .normal) {
                Image(nsImage: titlebar)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: baseWidth * CGFloat(scale), height: 14 * CGFloat(scale))
            }
        }
    }

    private var transportControls: some View {
        HStack(spacing: 0) {
            transportButton(.transportPrevious)
            transportButton(.transportPlay)
            transportButton(.transportPause)
            transportButton(.transportStop)
            transportButton(.transportNext)
        }
    }

    private func transportButton(_ element: SkinElement) -> some View {
        let image = skinCache.sprite(for: element, state: .normal)
        return Button(action: { handleTransport(element) }) {
            if let img = image {
                Image(nsImage: img)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 23 * CGFloat(scale), height: 18 * CGFloat(scale))
            } else {
                Rectangle()
                    .fill(.gray)
                    .frame(width: 23 * CGFloat(scale), height: 18 * CGFloat(scale))
            }
        }
        .buttonStyle(.plain)
    }

    private func handleTransport(_ element: SkinElement) {
        // Transport actions will be wired to AudioEngine in Week 5
        switch element {
        case .transportPlay: break
        case .transportPause: break
        case .transportStop: break
        case .transportPrevious: break
        case .transportNext: break
        default: break
        }
    }
}
