# Handoff: Giffy — screen recording → GIF converter for macOS

## Overview
Giffy is a small macOS utility that converts screen recordings (Xcode Simulator, QuickTime, macOS screenshot tool — `.mov` / `.mp4`) into GIFs for use in pull requests. It has:

1. **Main window** — sidebar of previously converted GIFs + one content area that walks through: empty drop zone → file loaded (name, preset, trim, crop) → converting → GIF ready (the result replaces the drop zone in the same window).
2. **Menu bar extra** — reachable from any app: quick drop target, grid of recent GIFs (click = copy), Open / Settings / Quit.
3. **Settings window** — General, Output, Shortcuts tabs.

Target: **SwiftUI, macOS 14+** (macOS 26 visual style preferred — Liquid Glass toolbar/sidebar come for free when built with standard components).

## About the design files
`Giffy macOS App v2.dc.html` is a **design reference built in HTML**, not production code. Open it in a browser (keep `support.js` and `assets/` next to it) to see all states side by side; several controls are clickable (preset, FPS, width, colors, dithering, crop, Advanced disclosure, Settings tabs, toggles).

Recreate it with **native SwiftUI components**. Where the HTML hand-draws a macOS control (switch, segmented picker, pop-up button, slider, text field, capsule buttons), use the real SwiftUI control — do not replicate the CSS. Measurements below are for layout intent; system controls should keep their native metrics.

## Fidelity
**High-fidelity** for layout, hierarchy, copy, states and behavior. Visual styling = standard macOS system appearance (system font, system colors, accent color). Icons in the mock are placeholders — use SF Symbols (mapping below).

---

## App structure (SwiftUI)

```swift
@main struct GiffyApp: App {
  var body: some Scene {
    WindowGroup("Giffy", id: "main") { MainView() }
      .defaultSize(width: 1080, height: 660)
      .windowToolbarStyle(.unified)
    MenuBarExtra("Giffy", systemImage: "photo.stack") { MenuBarView() }
      .menuBarExtraStyle(.window)
    Settings { SettingsView() }
  }
}
```

- `MainView` = `NavigationSplitView { HistorySidebar } detail: { ConverterView }` with `.inspector(isPresented:)` for the right-hand settings/result panel.
- `MenuBarExtra` visibility bound to the "Show Giffy in the menu bar" setting (`MenuBarExtra(isInserted:)`).
- Launch at login via `SMAppService.mainApp`.

---

## Screens

### 1. Main window (1080 × 660 default, min ~900 × 560)

**Sidebar (≈236 pt, `List(selection:)`, `.listStyle(.sidebar)`)**
- `.searchable(text:, placement: .sidebar)` — placeholder "Search".
- Sections grouped by date: "Today", "Yesterday", "Previous 7 days", then older by month.
- Row: 34×34 thumbnail (rounded 7 pt; animated GIF first frame; SF Symbol `iphone` / `desktopcomputer` as fallback by source), title (13 pt, filename), subtitle (11 pt, secondary, tabular digits): `"1.9 MB · 6.0 s · 11:40"`. For dates older than yesterday show `"Sep 19"` instead of time.
- In-progress row: subtitle `"Converting · 62%"` + thin `ProgressView(value:)` under it.
- Selected row: system selection; selecting a past GIF shows it in state 4 (GIF ready).
- Context menu on rows: Copy to Clipboard, Reveal in Finder, Save As…, Move to Trash.
- Drag a row out → provides the GIF file (`.draggable` / `NSItemProvider` with file URL).

**Toolbar**
- Title "Giffy", subtitle (`.navigationSubtitle`) varies by state:
  - Empty: `"7 GIFs"` (count of history)
  - Loaded: source description, e.g. `"iPhone 16 Pro recording"`
  - Converting: `"Converting…"`
  - Done: `"Saved to ~/Movies/Giffy"`
- Trailing items: **Crop** toggle (only when a file is loaded, not converting; `Toggle(.button)`, filled accent when on), **New** (`plus`, ⌘O, opens file importer), **Share** (`square.and.arrow.up`, `ShareLink` of the current GIF; disabled until done).

**State 1 — Empty**
- Detail area, padding 16: rounded-rect (radius 14) dashed border 2 pt, `Color.secondary.opacity(0.3)`; on drag-over border = accent + light accent fill.
- Centered stack (spacing 10): 64 pt rounded square with `square.and.arrow.down` (30 pt, secondary) · "Drop a screen recording here" (17 pt semibold) · "MOV or MP4 from iPhone, iPad or Mac — Xcode Simulator, QuickTime Player or the screenshot tool." (13 pt secondary, max width 380, centered) · row: `Button("Choose File…")` `.borderedProminent` `.controlSize(.large)` + caption "or press ⌘O".
- `.onDrop(of: [.movie, .mpeg4Movie, .quickTimeMovie])` and `.fileImporter(allowedContentTypes: [.movie])`. Whole window accepts drops in every state (drop replaces current file after confirm if converting).
- Inspector hidden in this state.

**State 2 — File loaded**
- Detail column, padding 0/16/16:
  - File header row: SF Symbol by source (`iphone`/`desktopcomputer`), filename (13 pt medium, truncate middle), trailing metadata (11 pt secondary, tabular): `"1179 × 2556 · 14.0 s · 60 fps · 38.2 MB"`.
  - Preview: rounded rect (radius 12) with `Color.primary.opacity(0.035)` background; video (`AVPlayerView` via `NSViewRepresentable`, or `VideoPlayer`) fitted at the recording's aspect ratio, ~86% of height, radius 6, subtle shadow. Plays looped within trim range.
  - **Crop overlay** (when Crop on): white 1.5 pt rect with draggable edges/corners; outside area dimmed black 28%. Pill label at bottom center: `"1179 × 1840"` (source pixels, 11 pt white on black 70%).
  - **Trim bar** (below preview): 40 pt tall filmstrip of frame thumbnails (generate with `AVAssetImageGenerator`), unselected parts overlaid white 65%, selection bordered by QuickTime-style yellow handle frame (`#FFCC00`, 3 pt top/bottom, 11 pt side handles, radius 6). Labels under it (11 pt tabular): start `0:01.8` · center `7.4 s of 14.0 s` · end `0:09.2`.
- **Inspector (300 pt)**, scrollable content, padding 14:
  1. **File name** — `TextField` with placeholder = original recording name without extension; trailing fixed `.gif` suffix label. Helper: "Leave empty to use the recording name."
  2. **Preset** — `Picker(.segmented)`: Small / Balanced / Sharp. Helper text (11 pt secondary):
     - Small: "480 px wide, 10 fps, 64 colors. Smallest file, fine for simple UI changes."
     - Balanced: "640 px wide, 15 fps, 128 colors. Good default for pull requests."
     - Sharp: "960 px wide, 24 fps, 256 colors. For animations and fine detail."
     - If advanced values don't match a preset: segment deselected, helper "Custom settings. Choose a preset to reset."
  3. **Advanced** — `DisclosureGroup` (open by default, remember state), contents in a `Form` `.formStyle(.grouped)`-style group:
     - Frame rate — segmented: 10 / 15 / 24 / 30
     - Width — `Picker(.menu)`: 360 px, 480 px, 640 px, 960 px, Original
     - Colors — `Slider` 16…256 step 16, value shown trailing
     - Dithering — `Toggle(.switch)`
     - Crop — read-only value: crop size in px or "Off"
  - **Footer** (pinned, top divider): "Estimated size" + `≈ 2.8 MB` (semibold, tabular); status line with 7 pt dot: green `"Under GitHub's 10 MB upload limit"` / orange `"Over GitHub's 10 MB upload limit"`; `Button("Convert to GIF")` `.borderedProminent`, full width, `.controlSize(.large)`, ⌘↩.

**State 3 — Converting**
- Preview dimmed (opacity ~0.55), accent playhead line moves across the trim bar.
- Inspector controls disabled (`.disabled(true)`).
- Footer: "Encoding frame 69 of 111" + "62%"; `ProgressView(value:)` linear; "About 4 seconds remaining" (11 pt secondary); `Button("Cancel")` full width, ⌘. / Esc.
- New sidebar row appears at top of "Today" with progress.

**State 4 — GIF ready** (replaces the converter in the same window)
- Preview shows the resulting GIF playing in a loop; pill "Playing · loops".
- File header: `photo` symbol, `onboarding-flow.gif`, `"640 × 1388 · 7.4 s · 2.8 MB"`.
- Inspector:
  - Header: `checkmark.circle.fill` (green, 22 pt) + "GIF ready" (15 pt semibold) + filename (secondary).
  - Details group (`LabeledContent` rows): Size 2.8 MB · Dimensions 640 × 1388 · Duration 7.4 s · Frames 111 at 15 fps · Colors 128, dithered · Location ~/Movies/Giffy.
  - Actions (bottom): `Copy to Clipboard` (prominent, full width, `doc.on.doc`, ⌘C) · two-up row `Reveal in Finder` / `Save As…` (⇧⌘S) · `Move to Trash` (destructive, borderless, red, ⌘⌫ with confirmation).
- If "Copy GIF to clipboard after converting" is on, the GIF is already on the clipboard; show a brief toast/HUD "Copied to clipboard".

### 2. Menu bar extra (`MenuBarExtra` `.window`, width 340)
- Status item icon: SF Symbol `photo.stack` (template).
- Header: "Giffy" (15 pt semibold) + trailing caption "Click a GIF to copy it".
- Drop target: dashed rounded rect (radius 10), `square.and.arrow.down` in 36 pt tile, "Drop a recording to convert" / "Balanced preset. Copied to the clipboard when done." (uses the default preset from Settings). Converting in the menu bar replaces this card with progress.
- "Recent" section: 3-column grid, 6 most recent, tiles 70 pt tall radius 8 with animated GIF thumbnail, filename caption (11 pt, truncate). Click → copy GIF to pasteboard, tile shows overlay "✓ Copied" for ~1.2 s with accent ring.
- Divider, then menu-style rows (24 pt, hover = accent highlight): Open Giffy ⌘O · Settings… ⌘, · Quit Giffy ⌘Q.

### 3. Settings (`Settings` scene, `TabView`, width ~600)
Tabs with SF Symbols: **General** (`gearshape`), **Output** (`photo`), **Shortcuts** (`keyboard`). Content uses `Form` `.formStyle(.grouped)`.

- **General**
  - Save GIFs to — path `~/Movies/Giffy` with folder icon + `Button("Change…")` (NSOpenPanel, directories).
  - Copy GIF to clipboard after converting — Toggle (default on)
  - Show Giffy in the menu bar — Toggle (default on)
  - Launch at login — Toggle (default off)
  - Keep history — Picker: 7 Days / 30 Days (default) / 90 Days / Forever
  - Below group: caption "Clearing history removes the list only. GIF files stay on disk." + `Button("Clear History…", role: .destructive)` with confirmation.
- **Output**
  - Default preset — Picker: Small / Balanced / Sharp
  - Default file name — TextField, default token "Recording name" + `.gif` suffix
  - Warn when a GIF is over 10 MB — Toggle (default on)
  - Loop forever — Toggle (default on)
  - Caption: "The file name is used when you leave the name field empty during conversion."
- **Shortcuts** (global hotkeys; e.g. KeyboardShortcuts package by sindresorhus)
  - Open menu bar extra — ⌥⌘G
  - Convert last screen recording — ⌥⌘R (finds newest recording in Desktop / screenshot location and converts with default preset)

---

## Interactions & behavior
- Preset selection sets width/fps/colors. Changing any advanced value → preset becomes "Custom" (no segment selected).
- Estimated size updates live. Mock formula (replace with real estimate, e.g. encode a 1 s sample): `2.8 MB × (width/640)² × (fps/15) × (0.55 + 0.45 × colors/128) × (dither ? 1 : 0.91) × (crop ? 1 : 1.35)` scaled by trimmed duration.
- Output file name: user text or fallback to the source filename without extension; sanitize; append `-2`, `-3` on collisions.
- Trim handles: drag, snap to frames, min length 0.5 s. Space = play/pause preview.
- Animations: standard SwiftUI defaults (`.smooth`); state transitions crossfade ~0.25 s. No custom springs.
- Errors: unsupported file → inline alert in drop zone "This file isn't a video Giffy can read."; encode failure → inspector footer shows error + "Try Again".
- Everything must work in Light and Dark mode (use semantic colors only).

## State
```swift
enum ConverterPhase { case empty, loaded(Source), converting(Source, progress: Double), done(GIFItem) }
struct ConversionSettings { var preset: Preset?; var fps: Int; var width: Int?; var colors: Int; var dithering: Bool; var crop: CGRect?; var trim: ClosedRange<Double>; var fileName: String }
struct GIFItem: Identifiable, Codable { id, url, sourceKind (.simulator/.mac), size, dimensions, duration, frames, fps, colors, dithered, createdAt }
```
- History persisted with SwiftData (or JSON in Application Support); prune by "Keep history".
- Settings in `@AppStorage`.
- Encoding: `AVAssetImageGenerator`/`AVAssetReader` for frames → `CGImageDestination` (`UTType.gif`) with `kCGImagePropertyGIFLoopCount = 0` when looping. For better quality/size, consider a palette quantizer (e.g. gifski via Swift wrapper). Run off the main actor with progress reporting.

## Design tokens
Use system values; mock equivalents:
- Accent: system accent (mock `#007AFF`; alternates tested: `#AF52DE`, `#FF2D55`, `#FF9500`, `#34C759`, `#8E8E93`)
- Text: `.primary` (≈ rgba(0,0,0,0.85)), `.secondary` (≈ 0.5), tertiary (≈ 0.4)
- Success `#28C840` (use `.green`), warning `#FF9500` (`.orange`), destructive `#FF3B30` (`.red`), trim handle `#FFCC00` (`.yellow`)
- Group background: `Color.primary.opacity(0.035)` (or `.quaternary` fill / grouped Form)
- Separators: 0.5 pt `Color.primary.opacity(0.08–0.1)`
- Type: SF Pro — title 15 semibold, body 13, caption 11, empty-state title 17 semibold, tabular digits for numbers
- Radius: window 16 (system), sidebar/cards 10–14, thumbnails 7–8, controls system
- Spacing: 4 / 6 / 8 / 10 / 12 / 14 / 16

## Assets / SF Symbol mapping
The mock uses placeholder SVG icons in `assets/icons/`. Use SF Symbols:
- upload/drop → `square.and.arrow.down` · plus → `plus` · export/share → `square.and.arrow.up`
- mobile → `iphone` · desktop → `desktopcomputer` · picture → `photo` · menu bar → `photo.stack`
- copy → `doc.on.doc` · folder → `folder` · delete → `trash` · check → `checkmark` / `checkmark.circle.fill`
- search → `magnifyingglass` · settings → `gearshape` · shortcuts → `keyboard` · disclosure → native
- App icon: not designed yet.

## Files
- `Giffy macOS App v2.dc.html` — the design (open in a browser with `support.js` + `assets/` alongside).
- `assets/icons/` — placeholder icons used by the mock.
