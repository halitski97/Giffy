import CoreGraphics
import Foundation

nonisolated struct GIFResult: Sendable {
    let tempURL: URL
    let byteSize: Int64
    let frameCount: Int
    let pixelSize: CGSize
    let duration: Double
}
