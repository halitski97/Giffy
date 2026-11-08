import Foundation

nonisolated struct ConversionProgressSnapshot: Sendable, Equatable {
    let frameIndex: Int
    let frameCount: Int
    let fraction: Double
    let secondsRemaining: Double?
}
