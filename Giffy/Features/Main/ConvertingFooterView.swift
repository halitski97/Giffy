import SwiftUI

struct ConvertingFooterView: View {
    let progress: ConversionProgressSnapshot?
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            if let progress {
                HStack {
                    Text("Encoding frame \(progress.frameIndex) of \(progress.frameCount)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ProgressFormatting.percentText(progress.fraction))
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                }
                ProgressView(value: progress.fraction)
                if let secondsRemaining = progress.secondsRemaining {
                    Text(ProgressFormatting.secondsRemainingText(secondsRemaining))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }

            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(".", modifiers: .command)
                .frame(maxWidth: .infinity)
        }
        .onExitCommand(perform: onCancel)
    }
}
