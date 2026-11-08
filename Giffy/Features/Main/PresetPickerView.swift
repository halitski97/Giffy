import SwiftUI

struct PresetPickerView: View {
    let model: ConverterModel
    let draft: Draft

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker("Preset", selection: presetBinding) {
                ForEach(Preset.allCases, id: \.self) { preset in
                    Text(preset.label).tag(Optional(preset))
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(helperText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var currentPreset: Preset? {
        Preset.matching(draft.settings)
    }

    private var presetBinding: Binding<Preset?> {
        Binding(
            get: { currentPreset },
            set: { newValue in
                if let newValue {
                    model.applyPreset(newValue)
                }
            }
        )
    }

    private var helperText: String {
        switch currentPreset {
        case .small:
            "480 px wide, 10 fps, 64 colors. Smallest file, fine for simple UI changes."
        case .balanced:
            "640 px wide, 15 fps, 128 colors. Good default for pull requests."
        case .sharp:
            "960 px wide, 24 fps, 256 colors. For animations and fine detail."
        case nil:
            "Custom settings. Choose a preset to reset."
        }
    }
}
