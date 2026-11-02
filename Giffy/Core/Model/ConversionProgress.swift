import Foundation

nonisolated struct ConversionProgress: Sendable {
    let frameIndex: Int
    let frameCount: Int
    let fraction: Double
}
