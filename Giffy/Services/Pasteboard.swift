import AppKit
import Foundation
import UniformTypeIdentifiers

/// Writes a converted GIF to the system pasteboard as both a file URL and raw image data on
/// the same item, so Finder (paste-as-file) and browsers like GitHub (paste-as-image) both
/// accept the paste.
struct Pasteboard {
    func copy(gifAt url: URL) throws {
        let data = try Data(contentsOf: url)
        let item = NSPasteboardItem()
        item.setString(url.absoluteString, forType: .fileURL)
        item.setData(data, forType: NSPasteboard.PasteboardType(UTType.gif.identifier))

        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([item])
    }
}
