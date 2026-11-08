import SwiftUI

struct ConverterView: View {
    let model: ConverterModel
    let isDropTargeted: Bool
    let onChooseFile: () -> Void

    var body: some View {
        content
            .inspector(isPresented: isInspectorPresented) {
                inspectorContent
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .empty(let importError):
            EmptyStateView(importError: importError, isDropTargeted: isDropTargeted, onChooseFile: onChooseFile)
        case .loaded(let draft):
            LoadedView(draft: draft)
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        if case .loaded(let draft) = model.phase {
            InspectorView(model: model, draft: draft)
                .inspectorColumnWidth(ideal: 300)
        }
    }

    private var isInspectorPresented: Binding<Bool> {
        Binding(
            get: { if case .loaded = model.phase { true } else { false } },
            set: { _ in }
        )
    }
}
