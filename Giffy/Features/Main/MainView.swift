import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    let converterModel: ConverterModel

    @State private var windowModel = MainWindowModel()
    @State private var isFileImporterPresented = false
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            HistorySidebar(selection: $windowModel.selection)
        } detail: {
            ConverterView(
                model: converterModel,
                isDropTargeted: isDropTargeted,
                onChooseFile: { isFileImporterPresented = true }
            )
        }
        .toolbar { toolbarContent }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            Task { await converterModel.importFile(at: url) }
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.movie]) { result in
            guard case .success(let url) = result else { return }
            Task { await converterModel.importFile(at: url) }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button {
                isFileImporterPresented = true
            } label: {
                Label("New", systemImage: "plus")
            }
            .keyboardShortcut("o", modifiers: .command)
        }
        ToolbarItem {
            Button {
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(true)
        }
    }
}
