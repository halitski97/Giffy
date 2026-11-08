import SwiftUI

struct LoadedView: View {
    let draft: Draft
    var isDimmed = false

    var body: some View {
        VStack(spacing: 12) {
            FileHeaderView(draft: draft)
            PreviewPlayerView(url: draft.url)
                .id(draft.url)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(radius: 4)
                .frame(maxHeight: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.035))
                )
        }
        .padding(16)
        .opacity(isDimmed ? 0.55 : 1)
    }
}
