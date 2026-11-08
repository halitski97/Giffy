import SwiftUI

struct EstimatedSizeFooterView: View {
    let estimatedByteSize: Int64?
    let isEstimatingSize: Bool
    let onConvert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack(spacing: 6) {
                Text("Estimated size")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if let estimatedByteSize {
                    Text(SizeFormatting.megabytesString(estimatedByteSize))
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                }
                if isEstimatingSize {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if estimatedByteSize != nil {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isOverLimit ? Color.orange : Color.green)
                        .frame(width: 7, height: 7)
                    Text(isOverLimit ? "Over GitHub's 10 MB upload limit" : "Under GitHub's 10 MB upload limit")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Button("Convert to GIF", action: onConvert)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: .command)
                .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var isOverLimit: Bool {
        (estimatedByteSize ?? 0) > SizeFormatting.githubUploadLimitBytes
    }
}
