import Foundation

/// `destinationUnavailable`, `accessDenied` and `diskFull` are declared for type stability but
/// are only ever thrown by the Services layer (M2/M4) — Core never touches save folders.
nonisolated enum ConversionError: Error, Sendable {
    case unsupportedFile
    case readFailed
    case encodeFailed
    case destinationUnavailable(String)
    case accessDenied(String)
    case diskFull
}
