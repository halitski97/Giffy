import Foundation

enum SizeFormatting {
    /// GitHub's quoted 10 MB upload limit, in the same binary-unit convention
    /// `SourceInfo.headerText` already uses (bytes / 1_048_576, labeled "MB").
    static let githubUploadLimitBytes: Int64 = 10 * 1_048_576

    static func megabytesString(_ bytes: Int64) -> String {
        String(format: "%.1f MB", Double(bytes) / 1_048_576)
    }
}
