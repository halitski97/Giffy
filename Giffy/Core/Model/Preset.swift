import Foundation

nonisolated enum Preset: CaseIterable, Sendable, Hashable {
    case small
    case balanced
    case sharp

    struct Values: Sendable {
        let width: Int?
        let fps: Int
        let colors: Int
        let dithering: Bool
    }

    var values: Values {
        switch self {
        case .small:
            Values(width: 480, fps: 10, colors: 64, dithering: false)
        case .balanced:
            Values(width: 640, fps: 15, colors: 128, dithering: false)
        case .sharp:
            Values(width: 960, fps: 24, colors: 256, dithering: false)
        }
    }

    /// Returns the preset whose values match `settings`, or `nil` ("Custom") if none do.
    static func matching(_ settings: ConversionSettings) -> Preset? {
        allCases.first { preset in
            let values = preset.values
            return values.width == settings.width
                && values.fps == settings.fps
                && values.colors == settings.colors
                && values.dithering == settings.dithering
        }
    }
}
