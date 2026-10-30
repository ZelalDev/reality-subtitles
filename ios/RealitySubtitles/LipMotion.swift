import Foundation
import CoreGraphics

// Geometric activity only: this is not speech detection or word recognition.
nonisolated struct LipMotionSample: Sendable {
    let timestamp: Double
    let opening: Double
}

nonisolated struct LipMotion: Sendable {
    private(set) var samples: [LipMotionSample] = []
    var hasEnoughSamples: Bool {
        samples.count >= 4 && (samples.last!.timestamp - samples.first!.timestamp) >= 0.4
    }
    var hasMovement: Bool {
        guard hasEnoughSamples else { return false }
        let values = samples.map(\.opening)
        return (values.max()! - values.min()!) >= 0.04
    }
    mutating func clear() { samples.removeAll() }
    mutating func append(opening: Double?, at timestamp: Double) {
        guard let opening, opening.isFinite, timestamp.isFinite, opening >= 0 else { clear(); return }
        if let last = samples.last, timestamp <= last.timestamp || timestamp - last.timestamp > 0.5 { clear() }
        samples.removeAll { timestamp - $0.timestamp >= 2 }
        samples.append(.init(timestamp: timestamp, opening: opening))
        if samples.count > 16 { samples.removeFirst(samples.count - 16) }
    }

    // Project inner lip points onto the normal of the outer lip's longest axis.
    // Pixel coordinates avoid image aspect-ratio distortion; normalization removes scale.
    static func opening(outer: [CGPoint], inner: [CGPoint]) -> Double? {
        guard outer.count >= 4, inner.count >= 4,
              (outer + inner).allSatisfy({ $0.x.isFinite && $0.y.isFinite }) else { return nil }
        var axis = CGPoint.zero
        var longest: CGFloat = 0
        for a in outer { for b in outer {
            let dx = b.x - a.x, dy = b.y - a.y
            let squared = dx * dx + dy * dy
            if squared > longest { longest = squared; axis = CGPoint(x: dx, y: dy) }
        } }
        guard longest > 1 else { return nil }
        let width = sqrt(longest)
        let projections = inner.map { (-axis.y * $0.x + axis.x * $0.y) / width }
        return Double((projections.max()! - projections.min()!) / width)
    }
}
