import AVFoundation
import CoreGraphics
import Foundation

/// Parameters for one run of the read/transform/encode loop, shared by `GIFConverter` (full
/// trim range) and `SizeEstimator` (a short sample range).
nonisolated struct PipelineContext: Sendable {
    let sourceURL: URL
    let sourceInfo: SourceInfo
    let settings: ConversionSettings
    let trim: ClosedRange<Double>
    let destinationURL: URL
}

nonisolated struct GIFConverter {
    @concurrent
    func convert(
        _ request: CoreRequest,
        progress: @Sendable (ConversionProgress) -> Void
    ) async throws -> GIFResult {
        let sourceInfo = try await VideoInspector().inspect(request.sourceURL)
        var encoder = ImageIOGIFEncoder()
        let context = PipelineContext(
            sourceURL: request.sourceURL,
            sourceInfo: sourceInfo,
            settings: request.settings,
            trim: request.settings.trim,
            destinationURL: request.destinationURL
        )
        let frameCount = try await Self.runPipeline(context: context, encoder: &encoder, progress: progress)

        let byteSize = Self.fileSize(at: request.destinationURL)
        let scaledSize = Self.outputSize(sourceInfo: sourceInfo, settings: request.settings)
        return GIFResult(
            tempURL: request.destinationURL,
            byteSize: byteSize,
            frameCount: frameCount,
            pixelSize: scaledSize,
            duration: request.settings.trim.upperBound - request.settings.trim.lowerBound
        )
    }

    /// Reads frames for `context.trim` at `context.settings.fps`, transforms them, and feeds
    /// them to `encoder`. On any failure or cancellation, the reader is stopped and the partial
    /// temp file removed.
    static func runPipeline<Encoder: GIFEncoder>(
        context: PipelineContext,
        encoder: inout Encoder,
        progress: @Sendable (ConversionProgress) -> Void
    ) async throws -> Int {
        let settings = context.settings
        let trim = context.trim
        let destinationURL = context.destinationURL

        let targetTimes = FramePlan.targetTimes(fps: settings.fps, trim: trim)
        guard !targetTimes.isEmpty else { throw ConversionError.unsupportedFile }
        let delays = FramePlan.delays(forFPS: settings.fps, frameCount: targetTimes.count)

        let reader = FrameReader()
        let transformer = FrameTransformer()
        try await reader.start(url: context.sourceURL, trim: trim)

        do {
            try encoder.begin(url: destinationURL, frameCount: targetTimes.count, loopCount: settings.loop ? 0 : 1)

            var pending: (pixelBuffer: CVPixelBuffer, time: Double)?
            var lastSample: (pixelBuffer: CVPixelBuffer, time: Double)?
            var frameIndex = 0
            for targetTime in targetTimes {
                try Task.checkCancellation()
                // Variable-frame-rate sources (e.g. Simulator recordings skip frames during
                // static screen content) can run dry near the trim boundary with target times
                // still left; hold the last decoded frame rather than failing the conversion.
                let matched = try nearestSample(to: targetTime, reader: reader, pending: &pending)
                guard let sample = matched ?? lastSample else {
                    throw ConversionError.readFailed
                }
                lastSample = sample
                let cgImage = try transformer.transform(
                    sample.pixelBuffer,
                    preferredTransform: context.sourceInfo.preferredTransform,
                    crop: settings.crop,
                    targetWidth: settings.width
                )
                try encoder.add(frame: cgImage, delayCentiseconds: delays[frameIndex])
                frameIndex += 1
                progress(ConversionProgress(
                    frameIndex: frameIndex,
                    frameCount: targetTimes.count,
                    fraction: Double(frameIndex) / Double(targetTimes.count)
                ))
            }
            try encoder.finish()
            return frameIndex
        } catch {
            reader.cancelReading()
            try? FileManager.default.removeItem(at: destinationURL)
            throw error
        }
    }

    /// Advances `reader`, carrying over an unconsumed look-ahead sample in `pending`, and
    /// returns whichever decoded sample is nearest to `targetTime`.
    private static func nearestSample(
        to targetTime: Double,
        reader: FrameReader,
        pending: inout (pixelBuffer: CVPixelBuffer, time: Double)?
    ) throws -> (pixelBuffer: CVPixelBuffer, time: Double)? {
        if pending == nil {
            pending = try reader.nextSample()
        }
        guard var best = pending else { return nil }
        pending = nil

        while let next = try reader.nextSample() {
            if abs(next.time - targetTime) < abs(best.time - targetTime) {
                best = next
            } else {
                pending = next
                break
            }
        }
        return best
    }

    private static func fileSize(at url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }

    private static func outputSize(sourceInfo: SourceInfo, settings: ConversionSettings) -> CGSize {
        guard let width = settings.width, sourceInfo.pixelSize.width > 0 else {
            return sourceInfo.pixelSize
        }
        let scale = CGFloat(width) / sourceInfo.pixelSize.width
        return CGSize(width: CGFloat(width), height: (sourceInfo.pixelSize.height * scale).rounded())
    }
}
