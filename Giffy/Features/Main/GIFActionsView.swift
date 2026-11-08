import FactoryKit
import SwiftUI
import UniformTypeIdentifiers

struct GIFActionsView: View {
    let model: ConverterModel
    let result: ConvertedGIF

    @Injected(\.pasteboard) private var pasteboard: Pasteboard
    @Injected(\.fileActions) private var fileActions: FileActions

    @State private var didCopy = false
    @State private var isTrashConfirmationPresented = false
    @State private var trashErrorMessage: String?
    @State private var isFileExporterPresented = false

    var body: some View {
        VStack(spacing: 10) {
            Button(action: copyToClipboard) {
                Label(didCopy ? "Copied" : "Copy to Clipboard", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("c", modifiers: .command)

            HStack(spacing: 10) {
                Button("Reveal in Finder") { fileActions.reveal(result.url) }
                    .frame(maxWidth: .infinity)
                Button("Save As…") { isFileExporterPresented = true }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button("Move to Trash", role: .destructive) {
                isTrashConfirmationPresented = true
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .keyboardShortcut(.delete, modifiers: .command)
        }
        .confirmationDialog(
            "Move “\(result.url.lastPathComponent)” to the Trash?",
            isPresented: $isTrashConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive, action: moveToTrash)
            Button("Cancel", role: .cancel) {}
        }
        .alert("Couldn't Move to Trash", isPresented: trashErrorBinding) {
            Button("OK") {}
        } message: {
            Text(trashErrorMessage ?? "")
        }
        .fileExporter(
            isPresented: $isFileExporterPresented,
            item: result.url,
            contentTypes: [.gif],
            defaultFilename: result.url.lastPathComponent
        ) { _ in
        }
    }

    private var trashErrorBinding: Binding<Bool> {
        Binding(get: { trashErrorMessage != nil }, set: { if !$0 { trashErrorMessage = nil } })
    }

    private func copyToClipboard() {
        guard (try? pasteboard.copy(gifAt: result.url)) != nil else { return }
        didCopy = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
        }
    }

    private func moveToTrash() {
        do {
            try model.moveCurrentResultToTrash()
        } catch {
            trashErrorMessage = "The file couldn't be moved to the Trash."
        }
    }
}
