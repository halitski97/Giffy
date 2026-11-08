import SwiftUI

struct GIFDetailsView: View {
    let result: ConvertedGIF

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Size", value: SizeFormatting.megabytesString(result.byteSize))
            LabeledContent("Dimensions", value: dimensionsText)
            LabeledContent("Duration", value: String(format: "%.1f s", result.duration))
            LabeledContent("Frames", value: "\(result.frameCount) at \(result.settings.fps) fps")
            LabeledContent("Colors", value: colorsText)
            LabeledContent("Location", value: "~/Movies/Giffy")
        }
        .font(.system(size: 12))
    }

    private var dimensionsText: String {
        "\(Int(result.pixelSize.width.rounded())) × \(Int(result.pixelSize.height.rounded()))"
    }

    private var colorsText: String {
        result.settings.dithering ? "\(result.settings.colors), dithered" : "\(result.settings.colors)"
    }
}
