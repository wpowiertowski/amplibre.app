import AVFAudio
import Foundation
import AmplibreCore

/// Playback state observable by the UI.
@Observable
public final class PlaybackState {
    public var isPlaying = false
    public var isPaused = false
    public var currentTime: TimeInterval = 0
    public var duration: TimeInterval = 0
    public var volume: Float = 0.75
    public var balance: Float = 0 // -1.0 (left) to 1.0 (right)
    public var isMono = false
    public var currentTrack: LibraryItem?

    public init() {}
}

/// Manages the AVAudioEngine graph: playback, EQ, crossfade, visualization tap.
///
/// Node graph: PlayerNode → EQNode → Mixer → Output
/// Dual player nodes enable crossfading between tracks.
public final class AudioEngine {
    public let state = PlaybackState()

    private let engine = AVAudioEngine()
    private let playerNodeA = AVAudioPlayerNode()
    private let playerNodeB = AVAudioPlayerNode()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 10)
    private let mixer = AVAudioMixerNode()

    /// Winamp EQ frequency bands: 70, 180, 320, 600, 1K, 3K, 6K, 12K, 14K, 16K Hz
    static let eqFrequencies: [Float] = [70, 180, 320, 600, 1000, 3000, 6000, 12000, 14000, 16000]

    init() {
        setupGraph()
        configureEQ()
    }

    // MARK: - Graph Setup

    private func setupGraph() {
        engine.attach(playerNodeA)
        engine.attach(playerNodeB)
        engine.attach(eqNode)
        engine.attach(mixer)

        engine.connect(playerNodeA, to: eqNode, format: nil)
        engine.connect(playerNodeB, to: mixer, format: nil)
        engine.connect(eqNode, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
    }

    private func configureEQ() {
        for (i, freq) in Self.eqFrequencies.enumerated() {
            let band = eqNode.bands[i]
            band.filterType = .parametric
            band.frequency = freq
            band.bandwidth = 1.0
            band.gain = 0
            band.bypass = false
        }
    }

    // MARK: - Playback Controls

    func play(url: URL) throws {
        let file = try AVAudioFile(forReading: url)
        state.duration = Double(file.length) / file.processingFormat.sampleRate
        state.isMono = file.processingFormat.channelCount == 1

        playerNodeA.scheduleFile(file, at: nil)

        if !engine.isRunning {
            try engine.start()
        }

        playerNodeA.play()
        state.isPlaying = true
        state.isPaused = false
    }

    func pause() {
        playerNodeA.pause()
        state.isPlaying = false
        state.isPaused = true
    }

    func resume() {
        playerNodeA.play()
        state.isPlaying = true
        state.isPaused = false
    }

    func stop() {
        playerNodeA.stop()
        state.isPlaying = false
        state.isPaused = false
        state.currentTime = 0
    }

    func seek(to time: TimeInterval) {
        // Will be implemented with proper sample-accurate seeking
        state.currentTime = time
    }

    func setVolume(_ volume: Float) {
        state.volume = volume
        engine.mainMixerNode.outputVolume = volume
    }

    func setEQBand(_ band: Int, gain: Float) {
        guard band >= 0, band < 10 else { return }
        eqNode.bands[band].gain = gain
    }
}
