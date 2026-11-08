import Foundation
import Observation

@Observable
final class ConverterModel {
    private(set) var phase: ConverterPhase = .empty(importError: nil)
    private let sourceLoader: SourceLoader

    init(sourceLoader: SourceLoader) {
        self.sourceLoader = sourceLoader
    }

    func importFile(at url: URL) async {
        do {
            let source = try await sourceLoader.load(url)
            var settings = ConversionSettings.balanced
            settings.trim = 0...source.duration
            phase = .loaded(Draft(source: source, settings: settings, fileName: ""))
        } catch {
            phase = .empty(importError: .unsupportedFile)
        }
    }
}
