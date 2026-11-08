import FactoryKit
import Foundation
import Observation

@Observable
final class ConverterModel {
    private(set) var phase: ConverterPhase = .empty(importError: nil)
    @ObservationIgnored @Injected(\.sourceLoader) private var sourceLoader: SourceLoader

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
