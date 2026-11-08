import CoreGraphics
import Foundation

nonisolated struct ConvertedGIF: Sendable, Equatable {
    let url: URL
    let byteSize: Int64
    let pixelSize: CGSize
    let duration: Double
    let frameCount: Int
    let settings: ConversionSettings

    /// e.g. "640 × 1388 · 7.4 s · 2.8 MB"
    var headerText: String {
        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())
        let durationText = String(format: "%.1f s", duration)
        let sizeText = SizeFormatting.megabytesString(byteSize)
        return "\(width) × \(height) · \(durationText) · \(sizeText)"
    }
}
