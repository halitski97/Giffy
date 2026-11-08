import Foundation

struct ConversionJob: Identifiable, Sendable {
    let id: UUID
    let request: ConversionRequest
    var status: Status

    enum StatusKind: Equatable {
        case queued, running, finished, failed, cancelled
    }

    enum Status: Sendable {
        case queued
        case running(ConversionProgressSnapshot)
        case finished(ConvertedGIF)
        case failed(ConversionError)
        case cancelled

        var isQueued: Bool {
            if case .queued = self { true } else { false }
        }

        var kind: StatusKind {
            switch self {
            case .queued: .queued
            case .running: .running
            case .finished: .finished
            case .failed: .failed
            case .cancelled: .cancelled
            }
        }
    }
}
