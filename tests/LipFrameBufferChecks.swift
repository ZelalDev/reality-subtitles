// Run on macOS with:
// xcrun swiftc ios/RealitySubtitles/LipFrameBuffer.swift tests/LipFrameBufferChecks.swift -o /tmp/lip-frame-checks
// /tmp/lip-frame-checks
import CoreImage
import Foundation

@main
struct LipFrameBufferChecks {
    static func main() {
        let size = CGSize(width: 480, height: 640)
        let top = LipCrop.pixelRect(normalized: CGRect(x: 0.25, y: 0.1, width: 0.2, height: 0.1), imageSize: size)!
        assert(top == CGRect(x: 120, y: 496, width: 96, height: 96), "Top-left detection must flip Y exactly once")
        for rect in [CGRect(x: 0, y: 0, width: 0.2, height: 0.05),
                     CGRect(x: 0.9, y: 0.95, width: 0.1, height: 0.05)] {
            let crop = LipCrop.pixelRect(normalized: rect, imageSize: size)!
            assert(CGRect(origin: .zero, size: size).contains(crop))
            assert(crop.width == crop.height, "Crop must not stretch lips")
        }
        assert(LipCrop.pixelRect(normalized: .zero, imageSize: size) == nil)
        assert(LipCrop.pixelRect(normalized: .null, imageSize: size) == nil)

        let context = CIContext(options: [.cacheIntermediates: false, .useSoftwareRenderer: true])
        let bounds = CGRect(origin: .zero, size: size)
        let redTop = CIImage(color: CIColor(red: 1, green: 0, blue: 0))
            .cropped(to: CGRect(x: 0, y: 320, width: 480, height: 320))
        let blue = CIImage(color: CIColor(red: 0, green: 0, blue: 1)).cropped(to: bounds)
        let synthetic = redTop.composited(over: blue)
        let image = LipCrop.render(synthetic, normalized: CGRect(x: 0.25, y: 0.1, width: 0.2, height: 0.1), context: context)!
        assert(image.width == 96 && image.height == 96 && image.bitsPerPixel == 32)
        let bytes = CFDataGetBytePtr(image.dataProvider!.data!)!
        assert(bytes[0] > 240 && bytes[2] < 10, "Top lip crop must be red, not the blue bottom half")

        var buffer = LipFrameBuffer()
        for index in 0..<100 { buffer.append(LipFrame(timestamp: Double(index) * 0.125, image: image)) }
        assert(buffer.frames.count == 16)
        assert(buffer.frames.first!.timestamp == 10.5)
        assert(buffer.frames.last!.timestamp - buffer.frames.first!.timestamp < 2)
        buffer.expire(at: 14.375)
        assert(buffer.frames.isEmpty, "Boundary at two seconds must expire")
        for index in 0..<100 { buffer.append(LipFrame(timestamp: Double(index) * 0.001, image: image)) }
        assert(buffer.frames.count == 16, "Capacity must hold even if capture frequency changes")
        buffer.append(LipFrame(timestamp: 0, image: image))
        assert(buffer.frames.count == 1, "A timestamp reset must start a new sequence")
        buffer.clear()
        assert(buffer.frames.isEmpty)
        print("PASS: crop orientation, edge bounds, 96×96 RGBA output, ordering, age, capacity, and clearing")
    }
}
