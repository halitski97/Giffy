import FactoryKit
import Foundation
import Observation

@Observable
final class ConverterModel {
    @ObservationIgnored @Injected(\.sourceLoader) private var sourceLoader: SourceLoader
    @ObservationIgnored @Injected(\.sizeEstimateService) private var sizeEstimateService: SizeEstimateService

    private(set) var phase: ConverterPhase = .empty(importError: nil)
    private(set) var estimatedByteSize: Int64?
    private(set) var isEstimatingSize = false

    /// The URL currently held open via `startAccessingSecurityScopedResource`, for exactly as
    /// long as `phase` is `.loaded` with that URL — spans preview playback and every repeated
    /// `SizeEstimateService` call while settings change. Independent of `SourceLoader`'s own
    /// transient start/stop during import, which is unaffected by this (nestable, refcounted).
    @ObservationIgnored private var activeAccess: (url: URL, didStart: Bool)?
    @ObservationIgnored private var estimateTask: Task<Void, Never>?

    deinit {
        if let activeAccess, activeAccess.didStart {
            activeAccess.url.stopAccessingSecurityScopedResource()
        }
    }

    func importFile(at url: URL) async {
        do {
            let source = try await sourceLoader.load(url)
            var settings = ConversionSettings.balanced
            settings.trim = 0...source.duration
            replaceActiveAccess(with: url)
            let draft = Draft(source: source, settings: settings, fileName: "", url: url)
            estimatedByteSize = nil
            phase = .loaded(draft)
            scheduleSizeEstimate(for: draft)
        } catch {
            stopActiveAccess()
            resetEstimate()
            phase = .empty(importError: .unsupportedFile)
        }
    }

    func updateFileName(_ newValue: String) {
        guard case .loaded(var draft) = phase else { return }
        draft.fileName = newValue
        phase = .loaded(draft)
    }

    func updateSettings(_ transform: (inout ConversionSettings) -> Void) {
        guard case .loaded(var draft) = phase else { return }
        transform(&draft.settings)
        phase = .loaded(draft)
        scheduleSizeEstimate(for: draft)
    }

    func applyPreset(_ preset: Preset) {
        updateSettings { settings in
            let values = preset.values
            settings.width = values.width
            settings.fps = values.fps
            settings.colors = values.colors
            settings.dithering = values.dithering
        }
    }

    private func scheduleSizeEstimate(for draft: Draft) {
        estimateTask?.cancel()
        isEstimatingSize = true
        let url = draft.url
        let settings = draft.settings
        estimateTask = Task {
            defer { if !Task.isCancelled { isEstimatingSize = false } }
            guard let bytes = try? await sizeEstimateService.estimate(url: url, settings: settings) else { return }
            guard !Task.isCancelled else { return }
            estimatedByteSize = bytes
        }
    }

    private func resetEstimate() {
        estimateTask?.cancel()
        estimateTask = nil
        estimatedByteSize = nil
        isEstimatingSize = false
    }

    private func replaceActiveAccess(with url: URL) {
        stopActiveAccess()
        let didStart = url.startAccessingSecurityScopedResource()
        activeAccess = (url, didStart)
    }

    private func stopActiveAccess() {
        if let activeAccess, activeAccess.didStart {
            activeAccess.url.stopAccessingSecurityScopedResource()
        }
        activeAccess = nil
    }
}
