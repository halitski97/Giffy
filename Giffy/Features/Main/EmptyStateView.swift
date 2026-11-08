import SwiftUI

struct EmptyStateView: View {
    let importError: ImportError?
    let isDropTargeted: Bool
    let onChooseFile: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : .clear)
            )
            .overlay(content)
            .padding(16)
    }

    private var content: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }

            Text("Drop a screen recording here")
                .font(.system(size: 17, weight: .semibold))

            Text("MOV or MP4 from iPhone, iPad or Mac — Xcode Simulator, QuickTime Player or the screenshot tool.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            VStack(spacing: 4) {
                Button("Choose File…", action: onChooseFile)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Text("or press ⌘O")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            if let importError {
                Text(importError.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(.top, 6)
            }
        }
    }
}
