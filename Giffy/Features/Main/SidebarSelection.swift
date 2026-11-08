import Foundation

enum SidebarSelection: Hashable {
    case current
    // M4 adds: case job(ConversionJob.ID)
    // M6 adds: case history(HistoryItem.ID)
}
