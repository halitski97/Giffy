import Foundation

extension SourceKind {
    var sfSymbolName: String {
        switch self {
        case .simulator:
            "iphone"
        case .mac:
            "desktopcomputer"
        case .other:
            "video"
        }
    }
}
