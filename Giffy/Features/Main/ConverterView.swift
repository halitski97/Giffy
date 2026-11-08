import SwiftUI

struct ConverterView: View {
    let model: ConverterModel
    let isDropTargeted: Bool
    let onChooseFile: () -> Void

    var body: some View {
        switch model.phase {
        case .empty(let importError):
            EmptyStateView(importError: importError, isDropTargeted: isDropTargeted, onChooseFile: onChooseFile)
        case .loaded(let draft):
            LoadedPlaceholderView(draft: draft)
        }
    }
}
