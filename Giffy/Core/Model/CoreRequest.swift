import Foundation

nonisolated struct CoreRequest: Sendable {
    let sourceURL: URL
    let settings: ConversionSettings
    let destinationURL: URL
}
