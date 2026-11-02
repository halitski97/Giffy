# Giffy: Architecture

How the app is structured. UI details are in `docs/design/HANDOFF.md`; stages and decisions are in `docs/PLAN.md`. Do not change the decisions here without discussion (see `CLAUDE.md`).

## Fixed decisions

- One app target. The conversion core lives in `Giffy/Core/` (a folder, not a package), and a SwiftLint rule enforces its boundary.
- Swift 6 language mode, default MainActor isolation, Approachable Concurrency.
- App Sandbox on. File access uses the Movies Folder read/write entitlement plus user-selected folders stored as security-scoped bookmarks.
- Conversions run one at a time; further requests queue.
- History is result-only: it stores the GIF and its parameters, never long-lived access to the source recording.
- Save As… exports a copy; history keeps pointing at the original file.
- The recordings folder defaults to `~/Desktop` and is granted once, on first use.

## 1. Layers and module boundaries

```
Features  ──▶  Services  ──▶  Core
   │                            ▲
   └────── value types only ────┘
Persistence ◀── Services, Features
```

```
Giffy/
  App/          GiffyApp (scenes), AppEnvironment (composition root)
  Core/         conversion core: no SwiftUI, AppKit, SwiftData
    Model/        ConversionSettings, Preset, SourceInfo, GIFResult, ConversionProgress, ConversionError
    Pipeline/     VideoInspector, FrameReader, FrameTransformer, GIFEncoder (+ implementation), GIFConverter, SizeEstimator
    Media/        FilmstripGenerator
    Naming/       FileNameSanitizer
  Services/     app-side glue: ConversionQueue, HistoryStore, Pasteboard, Hotkeys (M8), LaunchAtLogin, AppSettings
    FileAccess/   FolderAccess, BookmarkStore, SaveLocation, RecordingsFolder, RecordingFinder, OutputFileResolver
  Persistence/  HistoryItem (@Model), GiffySchemaV1, migration plan
  Features/
    Main/         MainView, HistorySidebar, ConverterView, Inspector, MainWindowModel, ConverterModel
    MenuBar/      MenuBarView, MenuBarModel
    Settings/     SettingsView and its tabs
  Shared/       formatters (sizes, durations), small view helpers
```

Rules:

- **Core** imports only Foundation, AVFoundation, CoreMedia, CoreVideo, CoreGraphics, ImageIO, UniformTypeIdentifiers and Accelerate. It knows nothing about bookmarks, settings, history or windows: it receives URLs it can already access and returns values.
- **Services** may use AppKit for system integration (`NSPasteboard`, `NSWorkspace`, `NSOpenPanel`), plus Observation and SwiftData. They contain no SwiftUI views.
- **Features** (SwiftUI) talk to Services and display Core value types. They never call the pipeline directly. Read-only previews (player, filmstrip, size estimate) also go through small service wrappers.
- **Persistence** holds only the SwiftData schema. Features read with `@Query`; all writes go through `HistoryStore`.

### Concurrency

- Core types are declared `nonisolated` (for example `nonisolated struct ConversionSettings`), are `Sendable` values, and do CPU-heavy work in `@concurrent` async functions so it runs off the main actor.
- Frames (`CGImage`, `CVPixelBuffer`) never cross an isolation boundary. They are produced and consumed inside a single `@concurrent` call; only `Sendable` values (progress, `GIFResult`, errors) come out.
- Services and view models are `@MainActor @Observable` (the target default). SwiftData is used only through the `mainContext`.

### Boundary enforcement

The `core_no_ui_imports` custom rule in `.swiftlint.yml` fails `swiftlint` (and therefore the git hooks) when a file under `Giffy/Core/` imports SwiftUI, AppKit, SwiftData or KeyboardShortcuts.

### Composition

`GiffyApp` creates one `ModelContainer` and one `AppEnvironment` (which holds the services) and injects them into all scenes with `.modelContainer(_:)` and `.environment(_:)`. Scenes:

- `Window("Giffy", id: "main")`: a single main window, so "Open Giffy" in the menu bar always brings back the same one. This replaces the handoff's `WindowGroup`.
- `MenuBarExtra(isInserted:)` with the custom `MenuBarIcon` template image, `.menuBarExtraStyle(.window)`.
- `Settings`.

## 2. State model

### Main window

`MainWindowModel` decides what the detail area shows, based on the sidebar selection:

```swift
enum SidebarSelection: Hashable {
    case current                     // the converter session (ConverterModel.phase)
    case job(ConversionJob.ID)       // a queued or running job started from the menu bar or hotkey: progress + Cancel
    case history(HistoryItem.ID)     // a past GIF, shown in the "GIF ready" layout
}
```

### Converter session

`ConverterModel` holds one explicit phase:

```swift
enum ConverterPhase {
    case empty(importError: ImportError?)          // drop zone; inline "This file isn't a video Giffy can read."
    case loaded(Draft)                             // preview, trim, crop, inspector
    case converting(Draft, job: ConversionJob.ID)  // progress comes from ConversionQueue; "Waiting…" while queued
    case done(HistoryItem.ID)                      // GIF ready
    case failed(Draft, ConversionError)            // footer error + Try Again (re-enqueues the same Draft)
}

struct Draft {
    var source: SourceInfo           // url, pixel size, duration, nominal fps, byte size, kind (.simulator / .mac)
    var settings: ConversionSettings
    var fileName: String             // empty = use the recording name
}
```

- The handoff's four phases are kept. `failed` is added for the error state, and the import error lives on `empty`.
- **The preset is derived, not stored.** `ConversionSettings` holds `fps`, `width` (nil = original), `colors`, `dithering`, `loops`, `trim` and `crop` (`colors`/`dithering` are present on the type but functionally inert until M1b ships — see §3). `Preset.matching(settings)` returns `.small`, `.balanced`, `.sharp` or nil, and nil is shown as "Custom". Choosing a preset overwrites `fps`, `width`, `colors` and `dithering`. The preset and the advanced values therefore can never disagree.
- Dropping a new file while converting needs no "replace?" confirmation (a deliberate change from the handoff): the running job continues in the queue and stays visible in the sidebar, and the window moves to `.loaded` with the new file.
- The toolbar subtitle, Crop toggle availability, Share enablement and inspector disabling are all computed from the phase.

### Conversion queue

`ConversionQueue` (`@MainActor @Observable`, one per app) is the only component that starts conversions:

```swift
struct ConversionJob: Identifiable {
    let id: UUID
    let request: ConversionRequest   // source URL + access token, settings, file name, origin (.window / .menuBar / .hotkey)
    var status: Status               // .queued, .running(ConversionProgress), .finished(HistoryItem.ID), .failed(ConversionError), .cancelled
}
```

- Jobs run strictly one at a time, first in, first out. `cancel(_:)` works for queued and running jobs.
- The sidebar's in-progress rows ("Converting · 62%", or "Waiting" when queued) come from `queue.jobs`, not from SwiftData. A history row is inserted only on success, so cancelled and failed jobs leave nothing in history.
- When a job finishes, the queue inserts the `HistoryItem` through `HistoryStore` and copies the GIF to the clipboard if "Copy GIF to clipboard after converting" is on. Menu bar and hotkey jobs always copy, because their UI promises it. The queue also keeps the result briefly for the menu bar's progress card.

### Settings

`AppSettings` declares every `@AppStorage` key and default in one place. Views use `@AppStorage`; services read a snapshot from `UserDefaults` when a job is enqueued. "Launch at login" is not stored: it is read from and written to `SMAppService.mainApp.status`.

## 3. Conversion pipeline (Core)

Entry point:

```swift
nonisolated struct GIFConverter {
    @concurrent func convert(_ request: CoreRequest,   // source URL, settings, destination temp URL
                             progress: @Sendable (ConversionProgress) -> Void) async throws -> GIFResult
}
```

All stages run inside that one call:

1. **Inspect** (`VideoInspector`): `AVURLAsset` loads the duration and, for the first video track, `naturalSize`, `preferredTransform` and `nominalFrameRate`; the file size comes from resource values. If there is no video track, it throws `.unsupportedFile`. The same call feeds the loaded-state header (`1179 × 2556 · 14.0 s · 60 fps · 38.2 MB`). `SourceKind` is guessed from the file name (Simulator names start with "Simulator Screen Recording") and the aspect ratio.
2. **Plan frames**: target times are `trim.lowerBound + i / fps` for every `i` whose time is below `trim.upperBound`. GIF delays are in hundredths of a second, so per-frame delays are distributed to avoid drift (15 fps gives 7, 7, 6, 7, 7, 6…). The number of times is the `frameCount` shown as "frame X of Y".
3. **Read** (`FrameReader`): `AVAssetReader` with an `AVAssetReaderTrackOutput` (32BGRA) and `timeRange` set to the trim range, decoding sequentially. For each target time it keeps the nearest decoded sample and drops the rest. Sequential reading is much faster than `AVAssetImageGenerator` for full conversions.
4. **Transform** (`FrameTransformer`): apply the orientation, crop to the source-pixel rectangle, then scale to the target width, keeping the aspect ratio (vImage or a high-quality `CGContext`).
5. **Encode** (`GIFEncoder` protocol: `begin(url:frameCount:loopCount:)`, `add(frame:delay:)`, `finish()`). Giffy's goal is GIFs for PR review under GitHub's 10 MB limit, not best-possible animation quality, so M1 prototypes the simplest option first: plain (non-indexed) `CGImage` frames go straight to `CGImageDestinationAddImage`, and ImageIO quantizes each frame automatically. Width, frame rate and trim are the primary size/quality controls for M1. `colors` and `dithering` belong to the encoder in principle (gifski quantizes internally, ImageIO does not), but `ConversionSettings` only carries those fields for now — they aren't wired to any encoder behavior yet. M1 records its quality/size findings in the decision log and decides whether a follow-up is needed:
   - If automatic quantization is good enough: ship it, nothing more to build for M1.
   - If not: **M1b** (conditional, see `docs/PLAN.md`) builds our own palette quantizer and Floyd–Steinberg dithering — one palette per conversion, sampled across frames, to avoid the inter-frame flicker that independent per-frame quantization causes — feeding indexed images to the same `CGImageDestination` path. The prototype must then check that ImageIO keeps the given palette.
   - gifski (needs approval as a third-party dependency) and a small native GIF89a/LZW writer remain further fallbacks if M1b still isn't enough.

   The loop flag maps to `kCGImagePropertyGIFLoopCount = 0` (or the equivalent in the chosen encoder).
6. **Write safely**: the encoder always writes to a temp file in the app's container. On success, Services resolve the final name and move the file into the save folder (see §5). On failure or cancellation, the temp file is deleted. The save folder never contains partial GIFs.

### Progress and cancellation

After each encoded frame the converter reports `(frameIndex, frameCount, fraction)`. The queue throttles UI updates to about 10 per second and computes "About N seconds remaining" from a moving average of frame time. Cancellation is standard task cancellation: `Task.checkCancellation()` runs per frame, the reader's `cancelReading()` is called on the way out, and the temp file is removed. Cancelling is not an error; the UI returns to `.loaded`.

### Size estimate

`SizeEstimator` replaces the handoff's mock formula. It encodes a sample of up to 1 s from the middle of the trim range, with the current settings and crop, into a temp file. It then scales the byte count by trimmed duration / sample duration. It runs at `.utility` priority, is debounced by about 300 ms after any change to settings, trim or crop, cancels the previous run, and caches results per settings key. While it computes, the footer keeps showing the last value with a small spinner. M1 checks its accuracy against full conversions of real Simulator recordings.

### Filmstrip

`FilmstripGenerator` uses `AVAssetImageGenerator` to make about 12 thumbnails across the full duration, sized for the 40 pt trim bar at 2×.

### Errors

`ConversionError` is `Sendable`: `unsupportedFile`, `readFailed`, `encodeFailed`, `destinationUnavailable(folder)`, `accessDenied(folder)`, `diskFull`.

## 4. SwiftData model

```swift
enum GiffySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [HistoryItem.self] }
}

@Model final class HistoryItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var fileName: String          // "onboarding-flow.gif"
    var filePath: String          // last known absolute path: display and fallback
    var fileBookmark: Data?       // security-scoped bookmark to the GIF file
    var sourceName: String        // original recording name, used by search
    var sourceKindRaw: String     // SourceKind
    var byteSize: Int64
    var pixelWidth: Int
    var pixelHeight: Int
    var duration: Double          // seconds, after trim
    var frameCount: Int
    var fps: Int
    var colors: Int
    var dithered: Bool
    var loops: Bool
    @Attribute(.externalStorage) var thumbnailPNG: Data?   // first frame, ~68 px; the sidebar never opens the GIF file
}
```

- The store uses SwiftData's default location inside the sandbox container (Application Support). `VersionedSchema` and a `SchemaMigrationPlan` exist from the start, so later changes are migrations, not ad-hoc fixes.
- No bookmark to the source recording is stored (history is result-only).
- **Grouping and search**: the sidebar groups by `createdAt` (Today, Yesterday, Previous 7 days, then by month). Search matches `fileName` and `sourceName` through a `@Query` with a `#Predicate`.
- **Pruning**: `HistoryStore.prune(keep:)` runs at launch, after each insert and when "Keep history" changes. It deletes rows older than the cutoff; Forever turns it off. **Clear History** deletes all rows. Neither touches GIF files.
- **Move to Trash** trashes the file, then deletes the row.
- **Missing files**: if the bookmark doesn't resolve and nothing exists at `filePath`, the row shows "File missing", file actions are disabled, and "Remove from History" is offered.

## 5. File access (App Sandbox on)

All file access goes through `Services/FileAccess/`. UI and Core never call `startAccessingSecurityScopedResource` themselves.

```swift
@MainActor protocol FolderAccessing {
    func url(for folder: KnownFolder) throws -> URL               // .saveFolder, .recordingsFolder
    func withAccess<T>(to url: URL, _ body: () async throws -> T) async rethrows -> T
    func requestAccess(to folder: KnownFolder) async -> URL?      // NSOpenPanel + bookmark
}
```

| Need | Mechanism | Entitlement |
|---|---|---|
| Read a dropped recording | The drag grants a sandbox extension for the file URL. The URL is held in the `ConversionRequest` for the job's lifetime. | user-selected files |
| Read a picked recording (Choose File…, ⌘O) | `.fileImporter`. The security scope is started when the file is loaded and stopped when the draft or job is released; the access token travels in `ConversionRequest`. | user-selected files |
| Default save folder `~/Movies/Giffy` | Movies Folder entitlement. The real path is built from `getpwuid(getuid()).pw_dir` + `/Movies/Giffy`, because under the sandbox `FileManager`'s home and Movies URLs point into the container. The folder is created on first save. | Movies Folder read/write |
| Custom save folder (Settings > General > Change…) | `NSOpenPanel` for directories, then a security-scoped bookmark in `UserDefaults` (`BookmarkStore`). Stale bookmarks are refreshed when resolved. If resolving fails, fall back to `~/Movies/Giffy` and show a notice. | user-selected read/write |
| Recordings folder (default `~/Desktop`) | The first time the hotkey or Settings needs it: a short explanation, then `NSOpenPanel` with `directoryURL = ~/Desktop`, then a bookmark. Settings shows the folder with "Change…". | user-selected read/write |
| Newest recording | `RecordingFinder`, inside `withAccess`, lists the folder (not recursively). It keeps files with extension `mov` or `mp4` that conform to `.movie`, sorts by creation date (falling back to modification date), and skips files modified in the last ~2 s, which may still be being written. | — |
| Final GIF location | `OutputFileResolver`: `FileNameSanitizer` (Core, pure) cleans the name, collisions get `-2`, `-3`… in the target folder, then the temp file is moved there. A security-scoped bookmark to the new file is stored on the `HistoryItem`. | — |
| History GIFs in older save folders | Each item's own `fileBookmark`, so changing the save folder never breaks older rows. | — |
| Save As… (⇧⌘S) | `.fileExporter` / `NSSavePanel` writes a copy; history is unchanged. | user-selected read/write |
| Move to Trash, Reveal in Finder, drag a row out | Inside `withAccess` for the item: `FileManager.trashItem`, `NSWorkspace.activateFileViewerSelecting`, `Transferable` with `FileRepresentation`. | — |
| Copy to Clipboard | `Pasteboard` writes both the file URL and the GIF data (`UTType.gif`), so Finder and browsers (GitHub) both accept the paste. | — |
| Temp files and thumbnails | The container's `temporaryDirectory`; thumbnails are stored in SwiftData. | — |

Required target settings: `ENABLE_APP_SANDBOX = YES`, `ENABLE_USER_SELECTED_FILES = readwrite`, `ENABLE_FILE_ACCESS_MOVIES_FOLDER = readwrite`.

To verify during M1/M2 rather than assume:

- Whether security-scoped bookmarks need `com.apple.security.files.bookmarks.app-scope` on macOS 26. Add it only if bookmark creation fails without it.
- That the Movies entitlement allows creating `~/Movies/Giffy` without a prompt.

If distribution later moves outside the sandbox (M9), only the `FolderAccess` implementation changes: bookmarks keep working and the access prompts can be skipped.

## 6. Out of scope

The visual layout (see `HANDOFF.md`), the encoder choice (M1) and the distribution method (M9).
