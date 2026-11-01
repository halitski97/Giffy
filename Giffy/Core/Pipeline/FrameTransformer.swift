import CoreGraphics
import CoreImage
import CoreVideo
import Foundation

/// Applies orientation, optional crop, and width-preserving-aspect scaling to a decoded frame.
/// Returns a plain (non-indexed) CGImage; color quantization is the encoder's job.
nonisolated final class FrameTransformer {
    private let context = CIContext()

    /// `crop`, when present, is in the oriented image's pixel coordinate space (CoreImage's
    /// bottom-left origin), before scaling. Not exercised by any caller until M5's crop UI exists.
    func transform(
        _ pixelBuffer: CVPixelBuffer,
        preferredTransform: CGAffineTransform,
        crop: CGRect?,
        targetWidth: Int?
    ) throws -> CGImage {
        var image = CIImage(cvPixelBuffer: pixelBuffer).transformed(by: preferredTransform)
        image = zeroOrigin(image)

        if let crop, crop.width > 0, crop.height > 0 {
            image = zeroOrigin(image.cropped(to: crop))
        }

        if let targetWidth, targetWidth > 0, image.extent.width > 0 {
            let scale = CGFloat(targetWidth) / image.extent.width
            if abs(scale - 1) > .ulpOfOne {
                image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }
        }

        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw ConversionError.readFailed
        }
        return cgImage
    }

    private func zeroOrigin(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))
    }
}
