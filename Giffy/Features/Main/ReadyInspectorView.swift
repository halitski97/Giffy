import SwiftUI

struct ReadyInspectorView: View {
    let model: ConverterModel
    let result: ConvertedGIF

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GIF ready")
                                .font(.system(size: 15, weight: .semibold))
                            Text(result.url.lastPathComponent)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }

                    GIFDetailsView(result: result)
                }
                .padding(14)
            }

            Divider()

            GIFActionsView(model: model, result: result)
                .padding(14)
        }
    }
}
