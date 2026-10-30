import AVFoundation
import Combine
import Vision
import CoreImage

// Only geometry and a rendered 96×96 crop cross to the UI; full camera buffers stay on the capture queue.
nonisolated struct LipDetection: Sendable {
    let rect: CGRect?
    let imageSize: CGSize
    let lipImage: CGImage?
    var motion = LipMotion()
    var frames: [LipFrame] = []
}

@MainActor
final class LipCamera: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isStarting = false
    @Published private(set) var permissionDenied = false
    @Published private(set) var message: String?
    @Published private(set) var detection: LipDetection?

    private let worker = LipCameraWorker()
    private var activeID: UUID?
    var session: AVCaptureSession { worker.session }

    func start() {
        guard activeID == nil else { return }
        let id = UUID()
        activeID = id
        isStarting = true
        permissionDenied = false
        message = nil
        Task { [self] in
            let allowed: Bool
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: allowed = true
            case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .video)
            default: allowed = false
            }
            // A permission reply must not restart a camera after leaving the screen.
            guard activeID == id else { return }
            guard allowed else {
                stop()
                permissionDenied = true
                message = "Dudak tespiti için kamera izni gerekiyor. Ayarlar’dan kamera erişimini açabilirsiniz."
                return
            }
            worker.start(id: id) { [weak self] id, event in
                Task { @MainActor [weak self] in
                    guard let self, self.activeID == id else { return }
                    switch event {
                    case .started:
                        self.isStarting = false
                        self.isRunning = true
                    case .detected(let detection):
                        self.detection = detection
                    case .failed(let message):
                        self.stop()
                        self.message = message
                    }
                }
            }
        }
    }

    func stop() {
        activeID = nil
        isStarting = false
        isRunning = false
        detection = nil
        worker.stop()
    }
}

// Session configuration, capture, and Vision share one serial queue. At most one
// frame is analyzed at a time; late frames are discarded instead of accumulated.
nonisolated final class LipCameraWorker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum Event: Sendable {
        case started
        case detected(LipDetection)
        case failed(String)
    }

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "RealitySubtitles.lipCamera", qos: .userInitiated)
    private var output: AVCaptureVideoDataOutput?
    private var runID: UUID?
    private var receive: (@Sendable (UUID, Event) -> Void)?
    private var lastAnalysis = -Double.infinity
    private var observers: [NSObjectProtocol] = []
    private let cropContext = CIContext(options: [.cacheIntermediates: false])
    private var frameBuffer = LipFrameBuffer()
    private var motion = LipMotion()

    // Future model integration can read a bounded chronological snapshot here.
    // The completion runs on the camera queue, never on the UI thread.
    func withBufferedFrames(_ completion: @escaping @Sendable ([LipFrame]) -> Void) {
        queue.async { [self] in completion(frameBuffer.frames) }
    }

    func start(id: UUID, receive: @escaping @Sendable (UUID, Event) -> Void) {
        queue.async { [self] in
            runID = id
            self.receive = receive
            lastAnalysis = -.infinity
            frameBuffer.clear()
            motion.clear()
            do {
                if output == nil { try configure() }
                session.startRunning()
                if session.isRunning {
                    receive(id, .started)
                } else {
                    receive(id, .failed("Kamera başlatılamadı. Lütfen tekrar deneyin."))
                }
            } catch {
                receive(id, .failed("Arka kamera kullanılamıyor. Lütfen kameranın kullanılabilir olduğunu kontrol edin."))
            }
        }
    }

    func stop() {
        queue.async { [self] in
            runID = nil
            receive = nil
            frameBuffer.clear()
            motion.clear()
            cropContext.clearCaches()
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CocoaError(.featureUnsupported)
        }
        let input = try AVCaptureDeviceInput(device: device)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        if session.canSetSessionPreset(.vga640x480) { session.sessionPreset = .vga640x480 }
        guard session.canAddInput(input) else { throw CocoaError(.featureUnsupported) }
        session.addInput(input)
        guard session.canAddOutput(videoOutput) else {
            session.removeInput(input)
            throw CocoaError(.featureUnsupported)
        }
        session.addOutput(videoOutput)
        // Both preview and delivered buffers use the same portrait orientation.
        if let connection = videoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        output = videoOutput
        for name in [AVCaptureSession.wasInterruptedNotification, AVCaptureSession.runtimeErrorNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.queue.async { [self] in
                    guard let runID = self.runID else { return }
                    self.receive?(runID, .failed("Kamera kesintiye uğradı. Kamerayı yeniden başlatabilirsiniz."))
                }
            })
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let runID else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        guard timestamp.isFinite else { return }
        frameBuffer.expire(at: timestamp)
        guard timestamp - lastAnalysis >= 0.125 else { return }
        lastAnalysis = timestamp
        autoreleasepool {
            guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                frameBuffer.clear()
                motion.clear()
                receive?(runID, .detected(LipDetection(rect: nil, imageSize: .zero, lipImage: nil)))
                return
            }
            let size = CGSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
            let request = VNDetectFaceLandmarksRequest()
            do {
                try VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:]).perform([request])
                // Follow the largest visible face when several people are in view.
                let face = request.results?.max { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }
                let rect = face.flatMap(Self.lipRect)
                let crop = rect.flatMap { LipCrop.render(CIImage(cvPixelBuffer: buffer), normalized: $0, context: cropContext) }
                if let crop {
                    frameBuffer.append(LipFrame(timestamp: timestamp, image: crop))
                } else {
                    // Do not combine separate visible speech segments across a detection gap.
                    frameBuffer.clear()
                    motion.clear()
                }
                let opening = face.flatMap { face -> Double? in
                    guard crop != nil, let outer = face.landmarks?.outerLips,
                          let inner = face.landmarks?.innerLips else { return nil }
                    func pixels(_ region: VNFaceLandmarkRegion2D) -> [CGPoint] {
                        region.normalizedPoints.map {
                            CGPoint(x: CGFloat($0.x) * face.boundingBox.width * size.width,
                                    y: CGFloat($0.y) * face.boundingBox.height * size.height)
                        }
                    }
                    return LipMotion.opening(outer: pixels(outer), inner: pixels(inner))
                }
                motion.append(opening: opening, at: timestamp)
                receive?(runID, .detected(LipDetection(rect: rect, imageSize: size, lipImage: crop,
                                                     motion: motion, frames: frameBuffer.frames)))
            } catch {
                frameBuffer.clear()
                motion.clear()
                receive?(runID, .detected(LipDetection(rect: nil, imageSize: size, lipImage: nil)))
            }
        }
    }

    private static func lipRect(_ face: VNFaceObservation) -> CGRect? {
        guard let lips = face.landmarks?.outerLips, lips.pointCount > 0 else { return nil }
        let points = lips.normalizedPoints
        let box = face.boundingBox
        let xs = points.map { box.minX + CGFloat($0.x) * box.width }
        let ys = points.map { box.minY + CGFloat($0.y) * box.height }
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else { return nil }
        // Vision's origin is bottom-left; the preview uses top-left coordinates.
        let rect = CGRect(x: minX, y: 1 - maxY, width: maxX - minX, height: maxY - minY)
        return rect.insetBy(dx: -0.012, dy: -0.012).intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }
}
