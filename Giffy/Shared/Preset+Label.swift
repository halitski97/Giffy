import Foundation

extension Preset {
    var label: String {
        switch self {
        case .small:
            "Small"
        case .balanced:
            "Balanced"
        case .sharp:
            "Sharp"
        }
    }
}
