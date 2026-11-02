import CoreGraphics
import Foundation

nonisolated protocol GIFEncoder {
    mutating func begin(url: URL, frameCount: Int, loopCount: Int) throws
    mutating func add(frame: CGImage, delayCentiseconds: Int) throws
    mutating func finish() throws
}
