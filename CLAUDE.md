# Giffy

A native macOS app that converts screen recordings (MOV/MP4, primarily from Xcode Simulator) into GIF animations for use in pull requests.

@docs/PLAN.md

> Start every session by reading the "Current status" section in `docs/PLAN.md`.

## Product (summary)

Main flow: empty state → file loaded → converting → GIF ready.

- Input: drag & drop or file picker (Choose File… / ⌘O / New button), MOV and MP4
- Recording itself is done in Simulator (saved to the Desktop by default); Giffy only picks up the saved file. No in-app recording, no `simctl` integration
- Preview, trim by time, crop
- Presets (Small / Balanced / Sharp) + Advanced: frame rate, width, colors, dithering
- Estimated output size, checked against GitHub's 10 MB upload limit
- Result actions: Copy to Clipboard, Reveal in Finder, Save As…, Move to Trash
- Sidebar with conversion history and search
- Menu bar extra: recent GIFs, click to copy, drop a file to convert
- Settings window: General, Output, Shortcuts tabs
- Global hotkey "Convert last screen recording": finds the newest MOV/MP4 in the recordings folder (default `~/Desktop`, configurable in Settings) and converts it with the default preset

## Design and UI spec

All design material lives in `docs/design/`:

- `HANDOFF.md`: detailed UI spec (screens, SwiftUI components, copy, behavior, state model). **Read it before working on any UI task.** It is intentionally not imported here to keep the default context small.
- `Giffy macOS App v2.dc.html`: visual reference. Open in a browser; it needs `support.js` and `assets/` next to it.
- `icon/`: finished app icon (`AppIcon.appiconset`) and menu bar icon (`MenuBarIcon.imageset`), plus source PNGs

Rules:

- Use native SwiftUI controls; do not replicate the HTML/CSS. Prefer standard components so macOS 26 styling (Liquid Glass) comes for free.
- `assets/icons/` in the design folder are mock placeholders: use SF Symbols in the app.
- Overrides of `HANDOFF.md`: the app icon is already designed (add `AppIcon.appiconset` to `Assets.xcassets`); the menu bar extra uses the custom `MenuBarIcon` template image instead of the SF Symbol `photo.stack`; the minimum macOS version is 26, not 14.
- Where the handoff conflicts with this file or `docs/architecture.md`, this file and the architecture doc win.

## Stack

- Swift, SwiftUI, Swift Concurrency (`async/await`), `@Observable`
- Minimum deployment target: macOS 26
- Build system: plain Xcode project (no Tuist)
- Persistence: SwiftData (conversion history)
- Frame reading: AVFoundation
- GIF encoding: TBD, decided after the M1 prototype (native ImageIO vs. gifski)
- Dependencies: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (Swift Package) for global hotkeys. This is the only approved third-party dependency so far.
- Linting: [SwiftLint](https://github.com/realm/swiftlint)
- Automated tests: none for now

## Architecture

Details live in `docs/architecture.md` (created after Plan Mode). Core principles:

- The conversion core is a separate module/layer with no UI dependencies
- UI only calls the core and shows progress/results
- Screen state is modeled with explicit states: empty, loaded, converting, done
- Keep file-system access (recordings folder, save location) behind a small abstraction, because the distribution method (and therefore App Sandbox) is not decided yet
- Check the target's App Sandbox setting and entitlements before implementing file access; do not change them without discussion

## Repository layout

- `Giffy/Giffy.xcodeproj`: the Xcode project. Note the nesting: the project lives in the `Giffy/` subfolder, not in the repo root
- `Giffy/Giffy/`: app sources and `Assets.xcassets`. It is a synchronized folder group, so files created on disk appear in Xcode automatically
- `docs/`: `PLAN.md`, `architecture.md`, `design/`
- Repo root: `CLAUDE.md`, `README.md`, `.gitignore`, `.swiftlint.yml`, `.claude/settings.json` (permissions), `.githooks/` (git hooks)

## Commands

Run all commands from the repo root.

- Run the app: open `Giffy/Giffy.xcodeproj` in Xcode and press ⌘R
- Build check (for Claude): `xcodebuild -project Giffy/Giffy.xcodeproj -scheme Giffy -destination 'platform=macOS' build`
- Lint: `swiftlint` (use `swiftlint --fix` for auto-fixable issues)
- Git hooks live in `.githooks/`; enable once per clone with `git config core.hooksPath .githooks`. pre-commit runs SwiftLint on staged Swift files, pre-push runs it on the whole project

## Working rules

- Start larger changes in Plan Mode
- Do not change decisions in `docs/architecture.md` without discussion. If a decision looks outdated, propose a change and wait for approval
- Ask before adding any third-party dependency other than the approved ones
- Avoid hand-editing `project.pbxproj`; ask first when a project setting has to change
- One feature = one branch = one PR; keep commits small
- Never run `git commit` or `git push` (both are denied in `.claude/settings.json` and blocked by the git hooks). When a task is done, propose a commit message and let the developer commit and push
- Run `swiftlint` and a build check before declaring a task done
- At the end of a session, update "Current status" and the checkboxes in `docs/PLAN.md`
- Keep this file short: move details into `docs/`
