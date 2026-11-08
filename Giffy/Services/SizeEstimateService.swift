import Foundation

/// Wraps Core's `SizeEstimator` so Features never calls the pipeline directly (architecture §1).
/// Unlike `SourceLoader`, doesn't manage security-scoped access itself — `ConverterModel` already
/// holds the scope open for the whole `.loaded` lifetime.
struct SizeEstimateService {
    func estimate(url: URL, settings: ConversionSettings) async throws -> Int64 {
        try await SizeEstimator().estimate(url: url, settings: settings)
    }
}
