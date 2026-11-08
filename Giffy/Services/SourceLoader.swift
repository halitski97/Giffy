import Foundation

/// Reads a dropped or picked recording's metadata for the import flow. Wraps Core's
/// `VideoInspector` with the security-scoped resource access that user-selected and
/// dropped files require under App Sandbox.
struct SourceLoader {
    func load(_ url: URL) async throws -> SourceInfo {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }
        return try await VideoInspector().inspect(url)
    }
}
