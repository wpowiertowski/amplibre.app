import Foundation

/// Plugin protocol for custom audio visualizations.
protocol VisualizationPlugin: Sendable {
    var pluginName: String { get }
    func render(spectrumData: [Float], waveformData: [Float])
}
