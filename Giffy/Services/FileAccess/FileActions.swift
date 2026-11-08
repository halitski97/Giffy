import AppKit
import Foundation

/// Reveal/Trash for a GIF this session already produced. No bookmark/security-scope wrapping —
/// the file is already inside the Movies-folder-entitled directory; that pattern only matters
/// for reopening a file from a *previous* launch (M6's history rows).
struct FileActions {
    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func moveToTrash(_ url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
}
