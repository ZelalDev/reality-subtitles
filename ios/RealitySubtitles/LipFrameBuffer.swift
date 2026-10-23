import CoreImage
import Foundation

// Immutable 96×96 sRGB RGBA frames, ordered by capture time. No camera buffer is retained.
nonisolated struct LipFrame: Sendable {
    let timestamp: TimeInterval
    let image: CGImage
}

// Owned exclusively by the camera queue. At 8 analyzed frames/second this holds
// at most 16 small images, and never samples older than two seconds.
nonisolated struct LipFrameBuffer {
    static let duration: TimeInterval = 2
    static let capacity = 16
    private(set) var frames: [LipFrame] = []

    mutating func append(_ frame: LipFrame) {
        if let last = frames.last, frame.timestamp <= last.timestamp { clear() }
        expire(at: frame.timestamp)
        frames.append(frame)
        if frames.count > Self.capacity { frames.removeFirst(frames.count - Self.capacity) }
    }

    mutating func expire(at timestamp: TimeInterval) {
        frames.removeAll { timestamp - $0.timestamp >= Self.duration }
    }

    mutating func clear() { frames.removeAll(keepingCapacity: false) }
}

nonisolated enum LipCrop {
    static let side = 96

    // Detection uses top-left normalized coordinates in the already rotated
    // camera buffer. Core Image uses bottom-left pixel coordinates in that same
    // buffer: flip Y once, without applying preview cropping or another rotation.
    static func pixelRect(normalized rect: CGRect, imageSize: CGSize) -> CGRect? {
        guard imageSize.width > 0, imageSize.height > 0,
              !rect.isNull, !rect.isInfinite, rect.width > 0, rect.height > 0 else { return nil }
        let pixels = CGRect(x: rect.minX * imageSize.width,
                            y: (1 - rect.maxY) * imageSize.height,
                            width: rect.width * imageSize.width,
                            height: rect.height * imageSize.height)
        // The detector already adds a small margin. Use a square to preserve
        // proportions when resizing; shift it inside the image at the edges.
        let side = min(ceil(max(pixels.width, pixels.height)), floor(min(imageSize.width, imageSize.height)))
        guard side >= 1 else { return nil }
        return CGRect(x: floor(max(0, min(pixels.midX - side / 2, imageSize.width - side))),
                      y: floor(max(0, min(pixels.midY - side / 2, imageSize.height - side))),
                      width: side, height: side)
    }

    static func render(_ image: CIImage, normalized rect: CGRect, context: CIContext) -> CGImage? {
        guard let crop = pixelRect(normalized: rect, imageSize: image.extent.size) else { return nil }
        let cropped = image.cropped(to: crop)
            .transformed(by: CGAffineTransform(translationX: -crop.minX, y: -crop.minY))
            .transformed(by: CGAffineTransform(scaleX: CGFloat(side) / crop.width, y: CGFloat(side) / crop.height))
        return context.createCGImage(cropped,
                                     from: CGRect(x: 0, y: 0, width: side, height: side),
                                     format: .RGBA8,
                                     colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
    }
}
