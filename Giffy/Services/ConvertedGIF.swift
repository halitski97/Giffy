import CoreGraphics
import Foundation

nonisolated struct ConvertedGIF: Sendable, Equatable {
    let url: URL
    let byteSize: Int64
    let pixelSize: CGSize
    let duration: Double
    let frameCount: Int
    let settings: ConversionSettings
}
