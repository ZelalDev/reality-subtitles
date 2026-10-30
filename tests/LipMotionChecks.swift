import Foundation
import CoreGraphics

@main struct LipMotionChecks {
    static func main() {
        let outer = [CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0), CGPoint(x: 0, y: 15), CGPoint(x: 0, y: -15)]
        let inner = [CGPoint(x: -30, y: 0), CGPoint(x: 30, y: 0), CGPoint(x: 0, y: 10), CGPoint(x: 0, y: -10)]
        let base = LipMotion.opening(outer: outer, inner: inner)!
        assert(abs(base - 0.2) < 0.00001)
        func transform(_ p: CGPoint) -> CGPoint { CGPoint(x: -p.y * 3 + 40, y: p.x * 3 + 70) }
        assert(abs(LipMotion.opening(outer: outer.map(transform), inner: inner.map(transform))! - base) < 0.00001)
        assert(LipMotion.opening(outer: [], inner: inner) == nil)
        var motion = LipMotion()
        for i in 0..<8 { motion.append(opening: 0.2, at: Double(i) * 0.125) }
        assert(motion.hasEnoughSamples && !motion.hasMovement)
        motion.append(opening: 0.3, at: 1)
        assert(motion.hasMovement)
        motion.append(opening: nil, at: 1.125)
        assert(motion.samples.isEmpty && !motion.hasMovement)
        for i in 0..<100 { motion.append(opening: 0.2, at: Double(i) * 0.125) }
        assert(motion.samples.count == 16)
        assert(motion.samples.last!.timestamp - motion.samples.first!.timestamp < 2)
        motion.append(opening: 0.3, at: 20)
        assert(motion.samples.count == 1 && !motion.hasEnoughSamples)
        motion.append(opening: 0.3, at: 0)
        assert(motion.samples.count == 1)
        motion.append(opening: .nan, at: 1)
        assert(motion.samples.isEmpty)
        print("PASS: geometry, scale/rotation/translation, missing landmarks, stable/moving samples, capacity, expiry, gaps, timestamp reset, invalid values")
    }
}
