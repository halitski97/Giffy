import SwiftUI

/// M2 stand-in for HANDOFF's "State 2 — File loaded". The real preview, trim bar and
/// inspector are M3's job; this just proves a real file was inspected successfully.
struct LoadedPlaceholderView: View {
    let draft: Draft

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)
            Text("Loaded")
                .font(.system(size: 17, weight: .semibold))
            Text(draft.source.headerText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("Preview, trim, crop and presets arrive in M3.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
