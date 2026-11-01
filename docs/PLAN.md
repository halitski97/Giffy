# Giffy: Development Plan

## Current status

- **Stage:** M0 done; starting M1
- **Done:** design handoff, icons in `Assets.xcassets`, Xcode project, SwiftLint and git hooks, Plan Mode interview, `docs/architecture.md`, project settings applied (user-selected files read/write, Movies Folder read/write, Swift 6, single deployment target 26.0)
- **Open in M0:** `docs/design/assets/` is missing (the HTML mock references `assets/icons/*.svg`); left open, not blocking M1
- **Next step:** M1 conversion core — start with `Giffy/Core/` scaffolding (`nonisolated` value types, `@concurrent` pipeline per `docs/architecture.md` §3), then reading frames from MOV/MP4 via AVFoundation

> Update this section at the end of every session.

## Stages

Each stage = one branch and one PR. A stage is done when all items are checked and `swiftlint` and the build pass. UI details for every stage are in `docs/design/HANDOFF.md`.

### M0. Preparation
- [ ] Design material in `docs/design/`: `HANDOFF.md`, `Giffy macOS App v2.dc.html`, `support.js`, `assets/`, `icon/` (`assets/` is missing: restore it, or drop it from this item since its icons are placeholders)
- [x] `CLAUDE.md` and `docs/PLAN.md` in place; `.gitignore` includes `CLAUDE.local.md` and `.claude/settings.local.json`
- [x] Xcode project created (macOS App, SwiftUI, name Giffy, deployment target macOS 26)
- [x] App icon and menu bar icon added to `Assets.xcassets` (menu bar icon rendered as Template Image)
- [x] SwiftLint configured (`.swiftlint.yml`), including the `core_no_ui_imports` rule
- [x] Plan Mode: requirements interview and remaining decisions
- [x] `docs/architecture.md` written
- [x] This plan refined after Plan Mode
- [x] Project settings applied (see `docs/architecture.md` §5): `ENABLE_USER_SELECTED_FILES = readwrite`, `ENABLE_FILE_ACCESS_MOVIES_FOLDER = readwrite`, `SWIFT_VERSION = 6.0`, project-level `MACOSX_DEPLOYMENT_TARGET = 26.4` removed so the target's 26.0 applies

### M1. Conversion core (no UI)
- [ ] Core in `Giffy/Core/`: `nonisolated` value types, `@concurrent` pipeline (`docs/architecture.md` §3)
- [ ] Read frames from MOV/MP4 (AVFoundation)
- [ ] Encode to GIF behind the `GIFEncoder` protocol (prototype, then pick the encoder); output always goes to a temp file first
- [ ] Parameters: frame rate, width, colors, dithering, loop flag
- [ ] Progress reporting (frame X of Y) and cancellation
- [ ] Real output size estimation (e.g. encode a 1 s sample), replacing the handoff's mock formula
- [ ] Manual check of quality and size on real Simulator recordings
- [ ] Record the encoder decision in the decision log

### M2. Main window shell and input
- [ ] App scenes: main window, menu bar extra stub, Settings stub
- [ ] `NavigationSplitView` with sidebar stub, toolbar (Crop toggle, New ⌘O, Share)
- [ ] Empty state: drop zone, Choose File…, ⌘O
- [ ] Whole-window drop in every state; unsupported-file error
- [ ] File access layer (`Services/FileAccess/`): save folder `~/Movies/Giffy` via the Movies entitlement, bookmark store; verify whether the app-scope bookmark entitlement is needed

### M3. Loaded state and options
- [ ] File header, preview with looped playback
- [ ] Inspector: file name, presets, Advanced section
- [ ] "Custom" preset behavior when advanced values diverge
- [ ] Footer: estimated size, 10 MB status, Convert to GIF

### M4. Converting and result
- [ ] `ConversionQueue`: one job at a time, others queued; temp file moved into the save folder on success
- [ ] Converting state: progress, time remaining, Cancel
- [ ] "GIF ready" state: GIF preview, details, actions
- [ ] Copy to Clipboard, Reveal in Finder, Save As…, Move to Trash (with confirmation)
- [ ] File name sanitizing and collision handling
- [ ] Error state with Try Again

### M5. Trim and crop
- [ ] Trim bar with filmstrip, draggable handles, snap to frames, min length 0.5 s
- [ ] Crop overlay with draggable edges and size label
- [ ] Take trim/crop into account in the size estimate

### M6. History and sidebar
- [ ] SwiftData model for history items
- [ ] Date-grouped sidebar list, search, in-progress row
- [ ] Row context menu and drag out as file
- [ ] Prune by "Keep history" setting; clear history (GIF files stay on disk)

### M7. Menu bar extra
- [ ] Menu bar item uses the custom `MenuBarIcon` template image
- [ ] Drop target that converts with the default preset
- [ ] Recent GIFs grid, click to copy with "Copied" feedback
- [ ] Open / Settings / Quit rows

### M8. Settings and hotkeys
- [ ] General: save location, recordings folder (default `~/Desktop`), copy after converting, show in menu bar, launch at login, keep history, clear history
- [ ] Output: default preset, default file name, warn over 10 MB, loop forever
- [ ] Shortcuts: KeyboardShortcuts recorders for "open menu bar extra" and "convert last screen recording"
- [ ] "Convert last screen recording": newest MOV/MP4 in the recordings folder, converted with the default preset; one-time folder grant (open panel at `~/Desktop`, security-scoped bookmark) on first use

### M9. Release
- [ ] Final polish
- [ ] Decide distribution method (DMG / Homebrew cask / Mac App Store) and sandbox setup accordingly
- [ ] Code signing and notarization

## Open questions

- GIF encoder: ImageIO vs. gifski (decided after the M1 prototype)
- Distribution method: undecided (M9). The app is built sandboxed for now; leaving the sandbox later only changes the `FolderAccess` implementation
- Whether security-scoped bookmarks need the `com.apple.security.files.bookmarks.app-scope` entitlement on macOS 26 (check in M2)
- Exact file name pattern and location of Simulator recordings on the developer's machine (check on the Desktop), to filter "last recording" reliably

## Decision log

Format: date, decision, reason.

- Minimum macOS 26: matches the design, simplest to build against (the handoff's "macOS 14+" is overridden)
- Plain Xcode project, no Tuist: the project is small, no need for multi-module tooling
- SwiftLint for linting; no automated tests for now
- No in-app recording or `simctl` integration: recording is made in Simulator, Giffy takes the saved file via drag & drop or the file picker
- Target GIF size: stay under GitHub's 10 MB upload limit (from the handoff); the app warns when over
- SwiftData for history persistence
- KeyboardShortcuts package for global hotkeys (accepted third-party dependency)
- "Convert last screen recording" looks in `~/Desktop` by default; the folder is configurable in Settings
- App icon and menu bar icon are already designed (otter); menu bar uses the custom icon instead of an SF Symbol
- 2026-10-29: App Sandbox stays on; file access via the Movies Folder read/write entitlement (default save folder `~/Movies/Giffy`) and user-selected folders with security-scoped bookmarks. Keeps the Mac App Store option open
- 2026-10-29: Conversion core is a folder in the app target (`Giffy/Core/`), not a package; a SwiftLint custom rule blocks UI imports there. Least project overhead
- 2026-10-29: Swift 6 language mode, switched before any code exists so it costs nothing
- 2026-10-29: Recordings folder `~/Desktop` is granted once on first use (open panel + bookmark), since the sandbox can't read it otherwise
- 2026-10-29: One conversion at a time; further requests queue. Encoding is CPU-heavy, and serial jobs keep progress UI simple
- 2026-10-29: History is result-only (no source bookmarks, no "Convert Again"); Save As… exports a copy
- 2026-10-29: Single main `Window` instead of `WindowGroup`, so "Open Giffy" always targets the same window. Dropping a file while converting needs no confirmation: the running job continues in the queue
