import Foundation

extension ConversionError {
    var message: String {
        switch self {
        case .unsupportedFile:
            "This file isn't a video Giffy can read."
        case .readFailed:
            "Giffy couldn't read this recording."
        case .encodeFailed:
            "Giffy couldn't encode the GIF."
        case .destinationUnavailable:
            "Giffy couldn't access the save folder."
        case .accessDenied:
            "Giffy doesn't have permission to save there."
        case .diskFull:
            "There isn't enough disk space to save the GIF."
        }
    }
}
