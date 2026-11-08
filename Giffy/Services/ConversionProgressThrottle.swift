import Foundation

/// Smooths Core's per-frame progress callback (zero throttling by design) down to ~10
/// updates/second with a rough "seconds remaining" estimate, via an exponential moving
/// average of inter-frame time. `@unchecked Sendable` because it's captured by the
/// `@Sendable` progress closure crossing into Core's `@concurrent` pipeline; an `NSLock`
/// protects the handful of mutable fields since calls arrive strictly sequentially in
/// practice but the type still needs to type-check as thread-safe.
nonisolated final class ConversionProgressThrottle: @unchecked Sendable {
    private let lock = NSLock()
    private var lastEmit: ContinuousClock.Instant?
    private var lastFrameTime: ContinuousClock.Instant?
    private var averageFrameSeconds: Double?

    private static let minimumInterval: Duration = .milliseconds(100)
    private static let smoothing = 0.2

    func record(_ progress: ConversionProgress) -> ConversionProgressSnapshot? {
        lock.lock()
        defer { lock.unlock() }

        let now = ContinuousClock.now
        if let lastFrameTime {
            let delta = now - lastFrameTime
            let deltaSeconds = Double(delta.components.seconds) + Double(delta.components.attoseconds) / 1e18
            averageFrameSeconds = averageFrameSeconds
                .map { $0 * (1 - Self.smoothing) + deltaSeconds * Self.smoothing } ?? deltaSeconds
        }
        lastFrameTime = now

        let isFinalFrame = progress.frameIndex == progress.frameCount
        if let lastEmit, !isFinalFrame, now - lastEmit < Self.minimumInterval {
            return nil
        }
        lastEmit = now

        let remaining = averageFrameSeconds.map { $0 * Double(max(progress.frameCount - progress.frameIndex, 0)) }
        return ConversionProgressSnapshot(
            frameIndex: progress.frameIndex,
            frameCount: progress.frameCount,
            fraction: progress.fraction,
            secondsRemaining: remaining
        )
    }
}
