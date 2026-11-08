import Foundation

nonisolated struct SizeEstimator {
    @concurrent
    func estimate(url: URL, settings: ConversionSettings) async throws -> Int64 {
        let sourceInfo = try await VideoInspector().inspect(url)
        let fullTrim = settings.trim
        let fullDuration = fullTrim.upperBound - fullTrim.lowerBound
        guard fullDuration > 0 else { return 0 }

        let sampleDuration = min(1.0, fullDuration)
        let mid = fullTrim.lowerBound + fullDuration / 2
        let sampleStart = max(fullTrim.lowerBound, mid - sampleDuration / 2)
        let sampleEnd = min(fullTrim.upperBound, sampleStart + sampleDuration)
        let sampleTrim = sampleStart...sampleEnd

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var encoder = ImageIOGIFEncoder()
        let context = PipelineContext(
            sourceURL: url,
            sourceInfo: sourceInfo,
            settings: settings,
            trim: sampleTrim,
            destinationURL: tempURL
        )
        do {
            _ = try await GIFConverter.runPipeline(context: context, encoder: &encoder, progress: { _ in })
        } catch {
            // Same ordering requirement as GIFConverter.convert's own catch: drop the encoder's
            // CGImageDestination before sweeping for its atomic-write staging sibling.
            encoder = ImageIOGIFEncoder()
            GIFConverter.removeAtomicWriteSiblings(of: tempURL)
            throw error
        }

        let sampleBytes = (try? FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? Int64) ?? 0
        let scale = fullDuration / (sampleEnd - sampleStart)
        return Int64(Double(sampleBytes) * scale)
    }
}
