import AVFoundation
import Foundation

nonisolated struct VideoInspector {
    @concurrent
    func inspect(_ url: URL) async throws -> SourceInfo {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ConversionError.unsupportedFile
        }

        let duration = try await asset.load(.duration).seconds
        let (naturalSize, preferredTransform, nominalFrameRate) =
            try await track.load(.naturalSize, .preferredTransform, .nominalFrameRate)

        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        let byteSize = Int64(resourceValues.fileSize ?? 0)

        let orientedSize = naturalSize.applying(preferredTransform)
        let pixelSize = CGSize(width: abs(orientedSize.width), height: abs(orientedSize.height))

        let kind = SourceInfo.guessKind(fileName: url.lastPathComponent, pixelSize: pixelSize)

        return SourceInfo(
            pixelSize: pixelSize,
            duration: duration,
            nominalFrameRate: nominalFrameRate,
            preferredTransform: preferredTransform,
            byteSize: byteSize,
            kind: kind
        )
    }
}
