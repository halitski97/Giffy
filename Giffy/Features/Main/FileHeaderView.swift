import SwiftUI

struct FileHeaderView: View {
    let draft: Draft

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: draft.source.kind.sfSymbolName)
                .foregroundStyle(.secondary)
            Text(draft.displayName)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text(draft.source.headerText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
