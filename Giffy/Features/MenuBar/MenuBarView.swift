import SwiftUI

/// Bare stub proving the scene exists. Recent GIFs grid and drop target arrive in M7.
struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Giffy")
                .font(.system(size: 15, weight: .semibold))
            Text("Menu bar features arrive in M7.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Divider()
            Button("Quit Giffy") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(12)
        .frame(width: 240)
    }
}
