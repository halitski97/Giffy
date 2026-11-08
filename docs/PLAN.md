# Giffy: Development Plan

## Current status

- **Stage:** M0, M1 and M2 done; starting M3
- **Done:** design handoff, icons in `Assets.xcassets`, Xcode project, SwiftLint and git hooks, Plan Mode interview, `docs/architecture.md`, project settings applied; M1 conversion core in `Giffy/Core/`, validated on a real Simulator recording (M1b not needed); M2 app shell — `App/` (GiffyApp, AppEnvironment), `Services/SourceLoader.swift`, `Features/Main/` (MainView, HistorySidebar stub, ConverterView, empty/loaded-placeholder views, ConverterModel/MainWindowModel, reduced `ConverterPhase`/`SidebarSelection`), `Features/MenuBar/` and `Features/Settings/` stubs. Build and lint pass; app launches cleanly (no crash, confirmed via process check — full interactive click-through needs the developer's own pass, see below)
- **Open in M0:** `docs/design/assets/` is missing (the HTML mock references `assets/icons/*.svg`); left open, not blocking later milestones
- **M2 follow-up:** the sandboxed verification environment has no Screen Recording/Accessibility permissions, so drag-and-drop, file-picker, and menu-bar interactions weren't click-tested automatically — only build/lint/launch were confirmed. Please do a quick manual pass (empty state copy, ⌘O/Choose File… picker restricted to movies, dropping/picking a real recording shows real header text in the loaded placeholder, dropping/picking a bad file shows the inline error, menu bar icon + Quit, Settings ⌘,) before merging
- **Next step:** M3 — loaded state and options (real preview/inspector UI replacing M2's placeholder)

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
- [x] Core in `Giffy/Core/`: `nonisolated` value types, `@concurrent` pipeline (`docs/architecture.md` §3)
- [x] Read frames from MOV/MP4 (AVFoundation)
- [x] Encode to GIF behind the `GIFEncoder` protocol; output always goes to a temp file first (M1 uses ImageIO's own automatic per-frame quantization; no custom palette/dithering code)
- [x] Parameters: frame rate, width, loop flag (`colors`/`dithering` fields exist on `ConversionSettings` but are inert until M1b)
- [x] Progress reporting (frame X of Y) and cancellation
- [x] Real output size estimation (e.g. encode a 1 s sample), replacing the handoff's mock formula
- [x] Manual check of quality and size on real Simulator recordings
- [x] Decide, from the manual quality/size check, whether M1b (custom quantizer) is needed → **no, not needed** (see decision log)
- [x] Record the encoder decision in the decision log

### M1b. Palette quantizer (not needed — kept for reference)
M1's manual check showed ImageIO's automatic per-frame quantization already meets the bar (see decision log), so this milestone is not being started. Left here in case a future recording type or longer clip reopens the question.
- [ ] Median-cut palette quantizer (`Core/Pipeline/PaletteQuantizer.swift`), one palette per conversion built from ~20 frames sampled across the trim range, reused for every frame
- [ ] Floyd–Steinberg dithering (`Core/Pipeline/Ditherer.swift`) against that fixed palette
- [ ] Empirical check: does ImageIO preserve a given indexed palette, or re-quantize anyway — record the result in the decision log
- [ ] Wire `ConversionSettings.colors` / `.dithering` to the encoder
- [ ] Enable the Colors slider and Dithering toggle in the Advanced section (M3 UI)

### M2. Main window shell and input
- [x] App scenes: main window, menu bar extra stub, Settings stub
- [x] `NavigationSplitView` with sidebar stub, toolbar (New ⌘O, Share — Crop toggle omitted until M5 gives it a real on/off meaning)
- [x] Empty state: drop zone, Choose File…, ⌘O
- [x] Whole-window drop in reachable states (`.empty`, placeholder `.loaded`); unsupported-file error
- [x] Reads a dropped/picked file for real via `Services/SourceLoader.swift` (wraps Core's `VideoInspector`); "loaded" state is a minimal placeholder (M3 builds the real preview/inspector UI)

### M3. Loaded state and options
- [ ] File header, preview with looped playback
- [ ] Inspector: file name, presets, Advanced section (Colors slider and Dithering toggle stay hidden/disabled until M1b ships; until then Advanced exposes only frame rate and width)
- [ ] "Custom" preset behavior when advanced values diverge
- [ ] Footer: estimated size, 10 MB status, Convert to GIF

### M4. Converting and result
- [ ] File access layer (`Services/FileAccess/`): save folder `~/Movies/Giffy` via the Movies entitlement, bookmark store; verify whether the app-scope bookmark entitlement is needed (moved here from M2, which only needed to read an already-granted dropped/picked file)
- [ ] `ConversionQueue`: one job at a time, others queued; temp file moved into the save folder on success
- [ ] `ConverterPhase` gains `.converting(Draft, job: ConversionJob.ID)` and `.failed(Draft, ConversionError)` (additive to M2's `ConverterPhase`, which only implemented `.empty`/`.loaded`); `.done(HistoryItem.ID)` needs `HistoryItem`, which is M6 — decide here whether M4 introduces a minimal `HistoryItem` ahead of M6's full SwiftData schema, or whether "GIF ready" waits for M6
- [ ] `SidebarSelection` gains `.job(ConversionJob.ID)`
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
- [ ] Date-grouped sidebar list (replaces M2's `HistorySidebar` stub), search, in-progress row
- [ ] Row context menu and drag out as file
- [ ] Prune by "Keep history" setting; clear history (GIF files stay on disk)
- [ ] `ConverterPhase.done` and `SidebarSelection.history(HistoryItem.ID)` gain a real backing type (`HistoryItem`)

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
- 2026-11-01: GIF encoder is ImageIO (`CGImageDestination`) with its own automatic per-frame quantization — no custom palette quantizer or Floyd–Steinberg dithering, no gifski. Validated against a real Simulator recording (1206×2622, 7.1s): all three presets stay well under GitHub's 10 MB limit (Small 1.07 MB, Balanced 2.18 MB/3s clip and 5.29 MB for the full 7.1s clip, Sharp 6.62 MB), `SizeEstimator`'s 1s-sample estimate is accurate to within ~1.5% of the actual output, conversions complete in 0.5-2.5s, and frames spot-checked across the sequence show no visible banding or inter-frame color flicker. M1b (custom quantizer) is therefore not started — `colors`/`dithering` stay inert on `ConversionSettings` until a future recording type reopens the question
- 2026-11-02: M2's file-access/save-folder/bookmark work moved to M4 (where it's actually needed) — M2 only reads a dropped/picked file, which needs nothing beyond the already-enabled "user-selected files" sandbox capability
- 2026-11-02: M2 implements only the reachable cases of `ConverterPhase` (`.empty`/`.loaded`) and `SidebarSelection` (`.current`) rather than inventing placeholder `ConversionJob`/`HistoryItem` types to satisfy the architecture doc's full 5-case/3-case enums. Not a change to the architecture decision — the remaining cases are added additively once M4/M6 build the types they need
- 2026-11-02: On a drop/pick, M2 calls Core's `VideoInspector` for real (via `Services/SourceLoader.swift`) rather than fabricating placeholder metadata; the "loaded" state is a minimal placeholder showing the real header text, with the actual preview/inspector UI staying out of scope until M3
