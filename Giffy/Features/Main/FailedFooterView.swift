import SwiftUI

struct FailedFooterView: View {
    let error: ConversionError
    let onTryAgain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Text(error.message)
                .font(.system(size: 12))
                .foregroundStyle(.red)

            Button("Try Again", action: onTryAgain)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
    }
}
