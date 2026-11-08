import AVFoundation
import SwiftUI

/// Always loops the whole file. M5's trim range will need to loop a sub-range instead of
/// frame zero, which is why this uses a plain seek-to-zero observer rather than
/// `AVQueuePlayer`/`AVPlayerLooper` (built around looping a whole item).
///
/// Uses `AVPlayerLayer` (AVFoundation) directly rather than AVKit's `VideoPlayer`/`AVPlayerView`:
/// macOS 26.4 has a confirmed Apple regression (FB22221857) that crashes any AVKit video
/// component at construction ("failed to demangle superclass of VideoPlayerView from mangled
/// name 'So12AVPlayerViewC'"). `AVPlayerLayer` is a different framework/class hierarchy and
/// doesn't hit that code path.
struct PreviewPlayerView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.load(url: url)
        return view
    }

    func updateNSView(_ nsView: PlayerLayerView, context: Context) {
    }

    static func dismantleNSView(_ nsView: PlayerLayerView, coordinator: ()) {
        nsView.teardown()
    }
}

final class PlayerLayerView: NSView {
    private let playerLayer = AVPlayerLayer()
    private var endObserver: NSObjectProtocol?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        playerLayer.videoGravity = .resizeAspect
        wantsLayer = true
        layer = playerLayer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func load(url: URL) {
        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .none
        playerLayer.player = player
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        player.play()
    }

    func teardown() {
        playerLayer.player?.pause()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        playerLayer.player = nil
    }
}
