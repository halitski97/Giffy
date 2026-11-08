import SwiftUI

/// M4a stand-in for HANDOFF's "State 4 — GIF ready". Proves the file actually saved;
/// the real preview/details/actions are M4b's job.
struct DoneView: View {
    let result: ConvertedGIF

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)
            Text("GIF ready")
                .font(.system(size: 17, weight: .semibold))
            Text(result.url.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Preview, details and actions arrive in M4b.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
