import Darwin
import Foundation

/// Resolves and writes into the default save folder `~/Movies/Giffy`. M4a/M4b only: no custom
/// folder, no bookmarks (architecture.md §5's full FolderAccessing design is M8).
struct SaveFolderService {
    private let outputFileResolver = OutputFileResolver()

    func resolveFolder() throws -> URL {
        let folder = realHomeDirectory.appendingPathComponent("Movies/Giffy", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            throw ConversionError.destinationUnavailable(folder.path)
        }
        return folder
    }

    func save(tempURL: URL, outputBaseName: String) throws -> URL {
        let folder = try resolveFolder()
        let destination = outputFileResolver.resolve(baseName: outputBaseName, in: folder)
        do {
            try FileManager.default.moveItem(at: tempURL, to: destination)
        } catch let error as NSError {
            switch error.code {
            case NSFileWriteOutOfSpaceError:
                throw ConversionError.diskFull
            case NSFileWriteNoPermissionError, NSFileReadNoPermissionError:
                throw ConversionError.accessDenied(folder.path)
            default:
                throw ConversionError.destinationUnavailable(folder.path)
            }
        }
        return destination
    }

    /// Under App Sandbox, FileManager's home/Movies URLs resolve inside this app's sandbox
    /// container, not the user's real home — the Movies Folder entitlement grants access to
    /// the real `~/Movies`, which only `getpwuid` locates. Do not "simplify" this back to the
    /// FileManager APIs; it silently breaks under the sandbox.
    private var realHomeDirectory: URL {
        guard let passwd = getpwuid(getuid()), let dir = passwd.pointee.pw_dir else {
            return FileManager.default.homeDirectoryForCurrentUser
        }
        return URL(fileURLWithPath: FileManager.default.string(withFileSystemRepresentation: dir, length: strlen(dir)))
    }
}
