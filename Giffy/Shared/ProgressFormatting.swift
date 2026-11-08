import Foundation

enum ProgressFormatting {
    static func percentText(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    static func secondsRemainingText(_ seconds: Double) -> String {
        let rounded = max(Int(seconds.rounded()), 0)
        return rounded == 1 ? "About 1 second remaining" : "About \(rounded) seconds remaining"
    }
}
