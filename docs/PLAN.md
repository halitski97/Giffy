# Giffy: Development Plan

## Current status

- **Stage:** M0, preparation
- **Done:** UI mockups, design handoff, app and menu bar icons designed, git repository created
- **In progress:** organizing `docs/design/`, creating the Xcode project, Plan Mode
- **Next step:** create the Xcode project, then finalize the architecture and write `docs/architecture.md`

> Update this section at the end of every session.

## Stages

Each stage = one branch and one PR. A stage is done when all items are checked and `swiftlint` and the build pass. UI details for every stage are in `docs/design/HANDOFF.md`.

### M0. Preparation
- [ ] Design material in `docs/design/`: `HANDOFF.md`, `Giffy macOS App v2.dc.html`, `support.js`, `assets/`, `icon/`
- [ ] `CLAUDE.md` and `docs/PLAN.md` in place; `.gitignore` includes `CLAUDE.local.md` and `.claude/settings.local.json`
- [ ] Xcode project created (macOS App, SwiftUI, name Giffy, deployment target macOS 26)
- [ ] App icon and menu bar icon added to `Assets.xcassets` (menu bar icon rendered as Template Image)
- [ ] SwiftLint configured (`.swiftlint.yml`)
- [ ] Plan Mode: requirements interview and remaining decisions
- [ ] `docs/architecture.md` written
- [ ] This plan refined after Plan Mode

### M1. Conversion core (no UI)
- [ ] Read frames from MOV/MP4 (AVFoundation)
- [ ] Encode to GIF (prototype, then pick the encoder)
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

### M3. Loaded state and options
- [ ] File header, preview with looped playback
- [ ] Inspector: file name, presets, Advanced section
- [ ] "Custom" preset behavior when advanced values diverge
- [ ] Footer: estimated size, 10 MB status, Convert to GIF

### M4. Converting and result
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
- [ ] "Convert last screen recording": newest MOV/MP4 in the recordings folder, converted with the default preset

### M9. Release
- [ ] Final polish
- [ ] Decide distribution method (DMG / Homebrew cask / Mac App Store) and sandbox setup accordingly
- [ ] Code signing and notarization

## Open questions

- GIF encoder: ImageIO vs. gifski (decided after the M1 prototype)
- Distribution method and App Sandbox: undecided. Decide before M8, since it affects access to the recordings folder (`~/Desktop` works without prompts only in a non-sandboxed build; a sandboxed build needs a one-time folder picker with a security-scoped bookmark)
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
