import SwiftUI

struct InspectorView: View {
    let model: ConverterModel
    let draft: Draft

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

            EstimatedSizeFooterView(
                estimatedByteSize: model.estimatedByteSize,
                isEstimatingSize: model.isEstimatingSize
            )
            .padding(14)
        }
    }
}
