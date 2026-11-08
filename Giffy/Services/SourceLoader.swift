import Foundation

struct SourceLoader {
    func load(_ url: URL) async throws -> SourceInfo {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }
        return try await VideoInspector().inspect(url)
    }
}
