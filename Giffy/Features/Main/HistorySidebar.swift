import FactoryKit
import SwiftUI

/// Past-history rows are a structural stub until M6 adds SwiftData-backed history.
/// In-progress rows come from `ConversionQueue.jobs` (architecture §2), not SwiftData.
struct HistorySidebar: View {
    @Binding var selection: SidebarSelection
    @State private var searchText = ""

    @Injected(\.conversionQueue) private var conversionQueue: ConversionQueue

    var body: some View {
        List(selection: listSelection) {
            ForEach(activeJobs) { job in
                InProgressRow(job: job)
                    .tag(SidebarSelection.job(job.id))
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
        .overlay {
            if activeJobs.isEmpty {
                ContentUnavailableView("No GIFs Yet", systemImage: "photo.stack")
            }
        }
    }

    private var activeJobs: [ConversionJob] {
        conversionQueue.jobs.filter { $0.status.isQueued || $0.status.kind == .running }
    }

    private var listSelection: Binding<SidebarSelection?> {
        Binding(get: { selection }, set: { selection = $0 ?? .current })
    }
}
