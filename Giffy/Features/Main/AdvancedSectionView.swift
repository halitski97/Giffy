import SwiftUI

/// Colors slider and Dithering toggle are deliberately absent — they stay inert until M1b,
/// which isn't currently planned to ship (see docs/PLAN.md's decision log).
struct AdvancedSectionView: View {
    let model: ConverterModel
    let draft: Draft

    private static let frameRates = [10, 15, 24, 30]
    private static let widths: [Int?] = [360, 480, 640, 960, nil]

    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup("Advanced", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Frame rate", selection: frameRateBinding) {
                    ForEach(Self.frameRates, id: \.self) { fps in
                        Text("\(fps)").tag(fps)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Width", selection: widthBinding) {
                    ForEach(Self.widths, id: \.self) { width in
                        Text(width.map { "\($0) px" } ?? "Original").tag(width)
                    }
                }

                LabeledContent("Crop", value: cropText)
            }
            .padding(.top, 6)
        }
    }

    private var cropText: String {
        draft.settings.crop.map { "\(Int($0.width)) × \(Int($0.height))" } ?? "Off"
    }

    private var frameRateBinding: Binding<Int> {
        Binding(get: { draft.settings.fps }, set: { newValue in model.updateSettings { $0.fps = newValue } })
    }

    private var widthBinding: Binding<Int?> {
        Binding(get: { draft.settings.width }, set: { newValue in model.updateSettings { $0.width = newValue } })
    }
}
