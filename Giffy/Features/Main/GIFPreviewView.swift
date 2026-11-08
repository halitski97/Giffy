import AppKit
import SwiftUI

/// Animated GIF playback via AppKit's long-standing `NSImageView.animates`, not AVKit — much
/// more battle-tested than AVKit's `VideoPlayer`/`AVPlayerView`, which crashes at construction
/// on this machine's macOS 26.4.1 (confirmed Apple regression FB22221857, see M3's decision log).
struct GIFPreviewView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> AnimatedGIFView {
        let view = AnimatedGIFView()
        view.load(url: url)
        return view
    }

    func updateNSView(_ nsView: AnimatedGIFView, context: Context) {
    }
}

/// A plain `NSView` container, not `NSImageView` itself: `NSImageView` reports an
/// `intrinsicContentSize` equal to the image's native pixel size, which — even behind
/// Auto Layout constraints pinning it to an "unconstrained" superview — still bubbles up
/// through the superview's own fitting-size calculation and fights SwiftUI's `.frame()`-driven
/// layout, blowing the view (and the whole window) up to the GIF's raw dimensions. Manually
/// framing the image view in `layout()` instead of using Auto Layout sidesteps that calculation
/// entirely, so SwiftUI stays fully in control of this container's size.
final class AnimatedGIFView: NSView {
    private let imageView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        addSubview(imageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override func layout() {
        super.layout()
        imageView.frame = bounds
    }

    func load(url: URL) {
        imageView.image = NSImage(contentsOf: url)
    }
}
