import SwiftUI

struct FileNameFieldView: View {
    let model: ConverterModel
    let draft: Draft

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField(draft.recordingName, text: fileNameBinding)
                Text(".gif")
                    .foregroundStyle(.secondary)
            }
            Text("Leave empty to use the recording name.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var fileNameBinding: Binding<String> {
        Binding(get: { draft.fileName }, set: { model.updateFileName($0) })
    }
}
