import Foundation

/// M4a: window-origin only. M7/M8 add a menu-bar/hotkey origin when those surfaces exist.
nonisolated struct ConversionRequest: Sendable {
    let sourceURL: URL
    let settings: ConversionSettings
    let outputBaseName: String
}
