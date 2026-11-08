import SwiftUI

struct InspectorView<Footer: View>: View {
    let model: ConverterModel
    let draft: Draft
    var isInteractive = true
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FileNameFieldView(model: model, draft: draft)
                    PresetPickerView(model: model, draft: draft)
                    AdvancedSectionView(model: model, draft: draft)
                }
                .padding(14)
            }
            .disabled(!isInteractive)

            footer()
                .padding(14)
        }
    }
}
