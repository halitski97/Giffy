import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// M1: feeds plain (non-indexed) CGImages straight to CGImageDestination and lets ImageIO
/// quantize each frame automatically. No custom palette/dithering (see M1b in docs/PLAN.md).
nonisolated struct ImageIOGIFEncoder: GIFEncoder {
    private var destination: CGImageDestination?

    mutating func begin(url: URL, frameCount: Int, loopCount: Int) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw ConversionError.encodeFailed
        }
        let properties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loopCount]
        ]
        CGImageDestinationSetProperties(destination, properties as CFDictionary)
        self.destination = destination
    }

    mutating func add(frame: CGImage, delayCentiseconds: Int) throws {
        guard let destination else { throw ConversionError.encodeFailed }
        let delaySeconds = Double(delayCentiseconds) / 100
        let frameProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: delaySeconds,
                kCGImagePropertyGIFUnclampedDelayTime: delaySeconds
            ]
        ]
        CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
    }

    mutating func finish() throws {
        guard let destination else { throw ConversionError.encodeFailed }
        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.encodeFailed
        }
    }
}
