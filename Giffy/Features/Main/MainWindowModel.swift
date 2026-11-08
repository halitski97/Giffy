import Observation

@Observable
final class MainWindowModel {
    var selection: SidebarSelection = .current
}
