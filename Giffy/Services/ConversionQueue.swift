import FactoryKit
import Foundation
import Observation

/// Runs conversions one at a time, FIFO. Shared across the app (Factory `.singleton`) since
/// both `ConverterModel` (enqueues, reacts to its own job) and the sidebar (shows live
/// progress for whatever's in flight) read `jobs` independently.
@Observable
final class ConversionQueue {
    @ObservationIgnored @Injected(\.saveFolderService) private var saveFolderService: SaveFolderService

    private(set) var jobs: [ConversionJob] = []

    @ObservationIgnored private var runningJobID: ConversionJob.ID?
    @ObservationIgnored private var runningConversionTask: Task<GIFResult, Error>?

    @discardableResult
    func enqueue(_ request: ConversionRequest) -> ConversionJob.ID {
        let job = ConversionJob(id: UUID(), request: request, status: .queued)
        jobs.append(job)
        startNextIfIdle()
        return job.id
    }

    func cancel(_ id: ConversionJob.ID) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        if id == runningJobID {
            runningConversionTask?.cancel()
        } else if jobs[index].status.isQueued {
            jobs.remove(at: index)
        }
    }

    private func startNextIfIdle() {
        guard runningJobID == nil, let index = jobs.firstIndex(where: { $0.status.isQueued }) else { return }
        let job = jobs[index]
        runningJobID = job.id
        Task { await run(job) }
    }

    private func run(_ job: ConversionJob) async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")
        let coreRequest = CoreRequest(
            sourceURL: job.request.sourceURL,
            settings: job.request.settings,
            destinationURL: tempURL
        )
        let throttle = ConversionProgressThrottle()
        let conversionTask = Task {
            try await GIFConverter().convert(coreRequest) { [weak self] progress in
                guard let snapshot = throttle.record(progress) else { return }
                Task { @MainActor in self?.updateRunning(job.id, snapshot) }
            }
        }
        runningConversionTask = conversionTask

        do {
            let result = try await conversionTask.value
            let finalURL = try saveFolderService.save(
                tempURL: result.tempURL,
                outputBaseName: job.request.outputBaseName
            )
            updateStatus(job.id, .finished(ConvertedGIF(
                url: finalURL,
                byteSize: result.byteSize,
                pixelSize: result.pixelSize,
                duration: result.duration,
                frameCount: result.frameCount,
                settings: job.request.settings
            )))
        } catch is CancellationError {
            updateStatus(job.id, .cancelled)
        } catch let error as ConversionError {
            try? FileManager.default.removeItem(at: tempURL)
            updateStatus(job.id, .failed(error))
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            updateStatus(job.id, .failed(.encodeFailed))
        }

        runningJobID = nil
        runningConversionTask = nil
        startNextIfIdle()
    }

    private func updateRunning(_ id: ConversionJob.ID, _ snapshot: ConversionProgressSnapshot) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].status = .running(snapshot)
    }

    private func updateStatus(_ id: ConversionJob.ID, _ status: ConversionJob.Status) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].status = status
    }
}
