import CoreGraphics
import Foundation

nonisolated enum SourceKind: Sendable {
    case simulator
    case mac
    case other
}

nonisolated struct SourceInfo: Sendable {
    let pixelSize: CGSize
    let duration: Double
    let nominalFrameRate: Float
    let preferredTransform: CGAffineTransform
    let byteSize: Int64
    let kind: SourceKind

    /// e.g. "1179 × 2556 · 14.0 s · 60 fps · 38.2 MB"
    var headerText: String {
        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())
        let durationText = String(format: "%.1f s", duration)
        let fpsText = "\(Int(nominalFrameRate.rounded())) fps"
        let megabytes = Double(byteSize) / 1_048_576
        let sizeText = String(format: "%.1f MB", megabytes)
        return "\(width) × \(height) · \(durationText) · \(fpsText) · \(sizeText)"
    }

    static func guessKind(fileName: String, pixelSize: CGSize) -> SourceKind {
        if fileName.hasPrefix("Simulator Screen Recording") {
            return .simulator
        }
        let aspect = pixelSize.width / max(pixelSize.height, 1)
        return aspect > 1.3 ? .mac : .other
    }
}
