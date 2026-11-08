# Giffy: Development Plan

## Current status

- **Stage:** M0-M3 and M4a done; M4b and starting M5 are both open (M4 was split into two PRs)
- **Done:** design handoff, icons in `Assets.xcassets`, Xcode project, SwiftLint and git hooks, Plan Mode interview, `docs/architecture.md`, project settings applied; M1 conversion core in `Giffy/Core/`, validated on a real Simulator recording (M1b not needed); M2 app shell (scenes, empty state, whole-window drop, file import); Factory (`FactoryKit`) adopted for DI; M3 real loaded-state UI (header, looped preview via `AVPlayerLayer`, inspector, estimated-size footer); M4a — real `ConversionQueue` (FIFO, Factory `.singleton`), default-save-folder writes to the real `~/Movies/Giffy` (verified a converted GIF actually lands there, not in the sandbox container), converting state with throttled progress/ETA/Cancel, error state with Try Again. `.done` is SwiftData-free (plain `ConvertedGIF`, placeholder `DoneView` — M4b builds the real one). Along the way, found and fixed a real temp-file-leak bug in Core's `GIFConverter` cancellation path (atomic-write `.sb-` sibling file from `CGImageDestination`, see decision log). Build and lint pass; the full M4a flow (convert → done with real path, cancel mid-flight → loaded with no leftover temp files, forced save failure → Try Again → done) verified end-to-end via a temporary debug harness, then removed
- **Open in M0:** `docs/design/assets/` is missing (the HTML mock references `assets/icons/*.svg`); left open, not blocking later milestones
- **Interactive click-through still needed from the developer:** this sandboxed environment has no Screen Recording/Accessibility permissions, so while M3/M4a's underlying logic was verified via debug harnesses (see decision log), the actual rendered UI hasn't been visually confirmed. Please click through M2-M4a together before merging: empty state copy, ⌘O/Choose File… picker restricted to movies, drop/pick a real recording and check header/preview/inspector, change presets and advanced fields and watch them stay in sync, drop a bad file and confirm the inline error, **click Convert to GIF and watch the dimmed preview/progress/ETA/Cancel**, try cancelling mid-conversion, menu bar icon + Quit, Settings ⌘,
- **Next step:** M4b (real "GIF ready" UI/actions, file naming/collision handling) or M5 (trim/crop) — whichever the developer wants to tackle first, since M4b and M5 don't depend on each other

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
- [x] File header, preview with looped playback (via `AVPlayerLayer`, not AVKit — see decision log)
- [x] Inspector: file name, presets, Advanced section (Colors slider and Dithering toggle stay hidden/disabled until M1b ships; until then Advanced exposes only frame rate and width)
- [x] "Custom" preset behavior when advanced values diverge
- [x] Footer: estimated size, 10 MB status, Convert to GIF (present but inert — M4 wires the real queue)

### M4. Converting and result
Split into two PRs: **M4a** (done) and **M4b** (not started).

**M4a — ConversionQueue, converting state, default save folder:**
- [x] File access layer, scoped to the default save folder only (`Services/FileAccess/SaveFolderService.swift`): resolves/creates `~/Movies/Giffy` via `getpwuid` (not FileManager's sandboxed Movies URL — see architecture §5), moves the temp GIF in. Bookmark store/custom folder pushed to M8, which is where they're actually used
- [x] `ConversionQueue` (`Services/ConversionQueue.swift`): one job at a time, FIFO, Factory `.singleton` (first shared-across-consumers Service in this app)
- [x] `ConverterPhase` gains `.converting(Draft, job: ConversionJob.ID)` and `.failed(Draft, ConversionError)`. `.done` carries a plain `ConvertedGIF` value, not `HistoryItem.ID` — M4a stays SwiftData-free; `.done`'s payload can be swapped for a real `HistoryItem` reference when M6 builds it, without touching anything else that reads `.done`
- [x] `SidebarSelection` gains `.job(ConversionJob.ID)` (selecting it doesn't yet route detail content — nothing new to show until M6/M7)
- [x] Converting state: progress (throttled ~10/s via `ConversionProgressThrottle`), "About N seconds remaining" (exponential moving average), Cancel (⌘./Esc)
- [x] Error state with Try Again

**M4b — GIF ready UI and file naming (not started):**
- [ ] "GIF ready" state: real GIF preview, details, actions (M4a ships only a bare placeholder `DoneView`)
- [ ] Copy to Clipboard, Reveal in Finder, Save As…, Move to Trash (with confirmation)
- [ ] File name sanitizing (`Core/Naming/FileNameSanitizer.swift` — not yet built, `Core/Naming/` is still empty) and numbered (`-2`, `-3`…) collision handling, replacing M4a's simple timestamp-suffix fallback

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
- 2026-11-08: Adopted [Factory](https://github.com/hmlongco/Factory) (`FactoryKit` product, v3.5.3) for dependency injection, replacing the hand-rolled `AppEnvironment`/`.environment(_:)` composition root from M2. `AppEnvironment.swift` is deleted; `App/Container+Registrations.swift` registers each Services/ type as a `Factory<T>`, and Features-layer consumers (e.g. `ConverterModel`) resolve via `@Injected` instead of constructor injection. Only the `FactoryKit` product is linked to the target (`FactoryKitDynamic` and `FactoryTesting` were dropped — the former is an alternate to `FactoryKit`, not additive; the latter is for a test target this project doesn't have). Each Services/ type also gets a short doc comment describing what it does, going forward
- 2026-11-08: M3's preview player uses `AVPlayerLayer` (AVFoundation) wrapped in a plain `NSViewRepresentable`, not AVKit's `VideoPlayer`/`AVPlayerView`. On this machine's macOS 26.4.1, any AVKit video component crashes at construction ("failed to demangle superclass of VideoPlayerView from mangled name 'So12AVPlayerViewC'") — a confirmed Apple regression (FB22221857, reported on Apple Developer Forums as affecting macOS 26.4 betas and release). `AVPlayerLayer` is a different framework/class hierarchy and doesn't hit that code path; verified working end-to-end (import, preview, preset/settings changes, size re-estimation) via a temporary debug harness. Revisit once Apple ships a fix — `VideoPlayer` is the simpler, more idiomatic choice once it's safe to use again
- 2026-11-08: M4 split into M4a (ConversionQueue, converting state, default save folder, error+Try Again) and M4b (real "GIF ready" UI/actions, file naming/collision handling) — M4's full checklist was unusually large for one PR. M4a stays SwiftData-free (`.done` carries a plain `ConvertedGIF`, not `HistoryItem.ID`) and file access is scoped to the default `~/Movies/Giffy` path only (bookmarks/custom folder are M8). M4a is also foreground-only: dropping a new file while one's converting is blocked, since a background job finishing after the user's navigated away has nowhere to surface its result without M6's `HistoryStore`
- 2026-11-08: Found and fixed a real bug while verifying M4a's Cancel: `ImageIOGIFEncoder`'s underlying `CGImageDestinationCreateWithURL` writes through a hidden `<name>.sb-<hash>-<random>` atomic-write staging sibling file that's only renamed into place on a successful `CGImageDestinationFinalize`. On cancellation/failure, `GIFConverter` was only removing its own named destination file, leaving that sibling orphaned in the temp directory. Root cause: the sibling can still be mid-write by ImageIO as long as the `CGImageDestination` (held by the in-flight `encoder` local) is alive — cleanup needed to happen after `convert()` explicitly drops `encoder`, not from inside `runPipeline`'s own catch (which runs while `encoder` is still owned by the still-active caller frame). Fixed in `Core/Pipeline/GIFConverter.swift`; verified clean across multiple cancellation runs via the debug harness
- 2026-11-08: A `/code-review high` pass against M4a's merged commit range surfaced 10 findings; verified each directly before fixing. One (the `.sb-` sibling-cleanup fix above) came back as a false alarm from the reviewer's own testing: it claimed ImageIO's staging-file pattern is actually `.<name>-<random>` (no `.sb-`), which a non-sandboxed standalone script reproduces — but re-running the real sandboxed app confirmed `.sb-<hash>-<random>` is exactly what occurs under App Sandbox (the non-sandboxed test exercised the wrong environment; `.sb-` is specifically the sandbox "safe save" pattern). The original fix was correct and needed no change. Four other findings were real and fixed: (1) `SizeEstimator.estimate` called `GIFConverter.runPipeline` directly, bypassing the sibling-cleanup fix entirely — a path that fires on every settings change, more often than real conversions; now has its own matching cleanup. (2) `ConversionQueue.cancel(_:)` silently removed a still-*queued* (not yet running) job from `jobs` instead of giving it a terminal status, which would permanently strand `ConverterModel.phase` in `.converting` the first time a second producer (M7/M8) queues behind a running job; now sets `.cancelled`. (3) `docs/architecture.md` still showed `case done(HistoryItem.ID)` and `.finished(HistoryItem.ID)`, never updated after the SwiftData-free decision — fixed to `ConvertedGIF`. (4) Dropping a file or pressing ⌘O during `.converting` silently no-opped with no UI feedback — the New button is now disabled and drops are rejected (not silently swallowed) while converting. Three more were confirmed real but correctly left alone: the `SaveFolderService` timestamp-collision race is exactly what M4b's `OutputFileResolver` replaces; the per-emit progress-update `Task` ordering and the unbounded `jobs` array are both low-severity and wait on later milestones. Also corrected a false claim in M4b's own checklist that `FileNameSanitizer` was "reserved since M1" — it wasn't; M1's checklist never mentions it
