import Foundation

/// Pure frame-timing math: which source times to sample, and how long each resulting GIF
/// frame should be displayed. No I/O.
nonisolated enum FramePlan {
    /// Target source times, `trim.lowerBound + i / fps`, while `< trim.upperBound`.
    static func targetTimes(fps: Int, trim: ClosedRange<Double>) -> [Double] {
        guard fps > 0 else { return [] }
        let step = 1.0 / Double(fps)
        var times: [Double] = []
        var index = 0
        while true {
            let time = trim.lowerBound + Double(index) * step
            guard time < trim.upperBound else { break }
            times.append(time)
            index += 1
        }
        return times
    }

    /// Per-frame GIF delays in hundredths of a second (centiseconds), distributed so the
    /// cumulative delay tracks `frameCount / fps` without drifting, e.g. 15 fps gives
    /// 7, 7, 6, 7, 7, 6…
    static func delays(forFPS fps: Int, frameCount: Int) -> [Int] {
        guard fps > 0, frameCount > 0 else { return [] }
        let centisecondsPerFrame = 100.0 / Double(fps)
        var delays: [Int] = []
        delays.reserveCapacity(frameCount)
        var accumulated = 0.0
        var emitted = 0
        for _ in 0..<frameCount {
            accumulated += centisecondsPerFrame
            let target = Int((accumulated).rounded())
            delays.append(target - emitted)
            emitted = target
        }
        return delays
    }
}
