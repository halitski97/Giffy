import SwiftUI

struct ReadyView: View {
    let result: ConvertedGIF

    var body: some View {
        VStack(spacing: 12) {
            ReadyFileHeaderView(result: result)
            ZStack(alignment: .bottomLeading) {
                GIFPreviewView(url: result.url)
                    .id(result.url)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 4)

                Text("Playing · loops")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
                    .padding(10)
            }
            .frame(maxHeight: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.035))
            )
        }
        .padding(16)
    }
}
