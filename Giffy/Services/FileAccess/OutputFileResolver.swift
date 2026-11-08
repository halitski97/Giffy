import Foundation

/// Decides the final destination URL for a converted GIF: sanitizes the name (Core, pure),
/// then finds a non-colliding path in the target folder via numbered suffixes. Only decides
/// the URL via `fileExists` checks — `SaveFolderService` keeps sole responsibility for the
/// actual file move.
struct OutputFileResolver {
    private static let maxCollisionAttempts = 500

    func resolve(baseName: String, extension ext: String = "gif", in folder: URL) -> URL {
        let sanitized = FileNameSanitizer.sanitize(baseName)

        let firstCandidate = folder.appendingPathComponent(sanitized).appendingPathExtension(ext)
        if !FileManager.default.fileExists(atPath: firstCandidate.path) {
            return firstCandidate
        }

        for suffix in 2...Self.maxCollisionAttempts {
            let candidate = folder.appendingPathComponent("\(sanitized)-\(suffix)").appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        // Pathological case: give up trying to be pretty and guarantee uniqueness.
        let timestamp = Int(Date().timeIntervalSince1970)
        return folder.appendingPathComponent("\(sanitized)-\(timestamp)").appendingPathExtension(ext)
    }
}
