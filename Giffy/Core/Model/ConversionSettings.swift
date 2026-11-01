import CoreGraphics
import Foundation

/// Tunable parameters for a conversion. `colors` and `dithering` are carried here for type
/// stability but are not yet wired to any encoder (see M1b in docs/PLAN.md).
nonisolated struct ConversionSettings: Sendable, Codable, Hashable {
    var fps: Int
    var width: Int?
    var colors: Int
    var dithering: Bool
    var loop: Bool
    var trim: ClosedRange<Double>
    var crop: CGRect?

    static let balanced = ConversionSettings(
        fps: 15,
        width: 640,
        colors: 128,
        dithering: false,
        loop: true,
        trim: 0...0,
        crop: nil
    )
}
