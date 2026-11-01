import AVFoundation
import CoreMedia
import CoreVideo
import Foundation

/// Sequential frame decoder over a trim range. Dumb on purpose: it knows nothing about target
/// times or frame rate — matching decoded samples to target times is the caller's job.
nonisolated final class FrameReader {
    private var reader: AVAssetReader?
    private var output: AVAssetReaderTrackOutput?

    func start(url: URL, trim: ClosedRange<Double>) async throws {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ConversionError.unsupportedFile
        }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        output.alwaysCopiesSampleData = false
        reader.add(output)
        reader.timeRange = CMTimeRange(
            start: CMTime(seconds: trim.lowerBound, preferredTimescale: 600),
            duration: CMTime(seconds: trim.upperBound - trim.lowerBound, preferredTimescale: 600)
        )
        guard reader.startReading() else {
            throw ConversionError.readFailed
        }
        self.reader = reader
        self.output = output
    }

    /// Returns the next decoded sample, or `nil` once the trim range is exhausted.
    func nextSample() throws -> (pixelBuffer: CVPixelBuffer, time: Double)? {
        guard let output else { return nil }
        guard let sampleBuffer = output.copyNextSampleBuffer() else {
            if let reader, reader.status == .failed {
                throw ConversionError.readFailed
            }
            return nil
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw ConversionError.readFailed
        }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        return (pixelBuffer, time)
    }

    func cancelReading() {
        reader?.cancelReading()
    }
}
