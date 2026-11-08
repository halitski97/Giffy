import Foundation

enum ImportError: Equatable, Sendable {
    case unsupportedFile

    var message: String {
        switch self {
        case .unsupportedFile:
            "This file isn't a video Giffy can read."
        }
    }
}

/// `.done` carries a plain `ConvertedGIF` rather than architecture's `HistoryItem.ID`: M4a
/// deliberately stays SwiftData-free (see docs/PLAN.md's decision log). `HistoryItem`/M6 can
/// replace this payload later without touching anything else that reads `.done`.
enum ConverterPhase {
    case empty(importError: ImportError?)
    case loaded(Draft)
    case converting(Draft, job: ConversionJob.ID)
    case failed(Draft, ConversionError)
    case done(ConvertedGIF)
}

struct Draft {
    var source: SourceInfo
    var settings: ConversionSettings
    var fileName: String
    var url: URL

    var recordingName: String { url.deletingPathExtension().lastPathComponent }
    var displayName: String { fileName.isEmpty ? recordingName : fileName }
}
