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

/// Only the cases M2 can reach are implemented. `docs/architecture.md` §2 fixes a 5-case
/// enum; `.converting`/`.done`/`.failed` need `ConversionJob` (M4) and `HistoryItem` (M6),
/// which don't exist yet — they're added additively once those milestones build them.
enum ConverterPhase {
    case empty(importError: ImportError?)
    case loaded(Draft)
}

struct Draft {
    var source: SourceInfo
    var settings: ConversionSettings
    var fileName: String
    var url: URL

    var recordingName: String { url.deletingPathExtension().lastPathComponent }
    var displayName: String { fileName.isEmpty ? recordingName : fileName }
}
