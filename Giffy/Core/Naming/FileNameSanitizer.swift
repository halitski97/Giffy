import Foundation

/// Cleans a screen-recording-derived display name into something safe to use as a filename
/// component. Deliberately simple: this input isn't adversarial, just occasionally awkward
/// (slashes, colons, stray whitespace).
nonisolated enum FileNameSanitizer {
    private static let maxLength = 200

    static func sanitize(_ name: String) -> String {
        var result = String(name.unicodeScalars.map { scalar -> Character in
            if scalar == "/" || scalar == ":" || CharacterSet.controlCharacters.contains(scalar) {
                "-"
            } else {
                Character(scalar)
            }
        })

        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        while result.hasPrefix(".") {
            result.removeFirst()
        }
        if result.count > maxLength {
            result = String(result.prefix(maxLength))
        }

        return result.isEmpty ? "GIF" : result
    }
}
