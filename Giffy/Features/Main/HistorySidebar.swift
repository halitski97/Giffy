import SwiftUI

/// Structural stub: no rows until M6 adds SwiftData-backed history.
struct HistorySidebar: View {
    @Binding var selection: SidebarSelection
    @State private var searchText = ""

    var body: some View {
        List(selection: listSelection) {
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
        .overlay {
            ContentUnavailableView("No GIFs Yet", systemImage: "photo.stack")
        }
    }

    private var listSelection: Binding<SidebarSelection?> {
        Binding(get: { selection }, set: { selection = $0 ?? .current })
    }
}
