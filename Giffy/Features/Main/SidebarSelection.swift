import Foundation

enum SidebarSelection: Hashable {
    case current
    /// Doesn't yet change what the detail area shows — nothing new exists to show until M6/M7
    /// add a second routable thing (history, other queued jobs).
    case job(ConversionJob.ID)
    // M6 adds: case history(HistoryItem.ID)
}
