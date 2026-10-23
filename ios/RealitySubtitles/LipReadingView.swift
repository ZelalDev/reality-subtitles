import SwiftUI
import AVFoundation
import UIKit

struct LipReadingView: View {
    @StateObject private var camera = LipCamera()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CameraPreview(session: camera.session, detection: camera.detection)
                    .frame(height: 360)
                    .overlay {
                        if !camera.isRunning {
                            ZStack {
                                Color.black
                                if camera.isStarting {
                                    ProgressView("Kamera hazırlanıyor…").tint(.white)
                                } else {
                                    Label("Kamera kapalı", systemImage: "camera")
                                }
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityLabel("Arka kamera canlı görüntüsü")

                VStack(spacing: 8) {
                    Text("Canlı dudak görüntüsü")
                        .font(.subheadline.weight(.semibold))
                    ZStack {
                        Color(red: 0.95, green: 0.96, blue: 0.97)
                        if let image = camera.detection?.lipImage {
                            Image(decorative: image, scale: 1, orientation: .up)
                                .resizable()
                                .scaledToFit()
                                .accessibilityLabel("Canlı kırpılmış dudak görüntüsü")
                        } else {
                            Text("Dudak görüntüsü yok")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(8)
                        }
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(camera.detection?.rect == nil ? "Dudak algılanamadı" : "Dudak algılandı")
                    .font(.headline)
                    .foregroundStyle(camera.detection?.rect == nil ? Color.secondary : .green)

                if let message = camera.message {
                    Text(message).font(.subheadline).foregroundStyle(.secondary)
                }
                if camera.permissionDenied {
                    Button("Ayarları Aç") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }

                HStack(spacing: 16) {
                    Button("Kamerayı Başlat", systemImage: "camera.fill") { camera.start() }
                        .disabled(camera.isRunning || camera.isStarting || scenePhase != .active)
                    Button("Durdur", systemImage: "stop.fill") { camera.stop() }
                        .disabled(!camera.isRunning && !camera.isStarting)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Text("Yalnızca yüz ve dudak tespiti yapılır; kelime tahmini yapılmaz. Görüntüler kaydedilmez ve hiçbir sunucuya gönderilmez.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .background(.white)
        .navigationTitle("Lip Reading")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { camera.stop() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            camera.stop()
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let detection: LipDetection?

    func makeUIView(context: Context) -> LipPreviewView {
        let view = LipPreviewView()
        view.preview.session = session
        view.preview.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: LipPreviewView, context: Context) {
        view.detection = detection
        view.setNeedsLayout()
    }

    static func dismantleUIView(_ view: LipPreviewView, coordinator: ()) {
        view.preview.session = nil
    }
}

private final class LipPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var preview: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    var detection: LipDetection?
    private let lipOutline = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        lipOutline.strokeColor = UIColor.systemGreen.cgColor
        lipOutline.fillColor = UIColor.clear.cgColor
        lipOutline.lineWidth = 3
        layer.addSublayer(lipOutline)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let connection = preview.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        lipOutline.frame = bounds
        guard let detection, let rect = detection.rect,
              detection.imageSize.width > 0, detection.imageSize.height > 0 else {
            lipOutline.path = nil
            return
        }
        // Match resizeAspectFill, including its centered cropping on every layout.
        let size = detection.imageSize
        let scale = max(bounds.width / size.width, bounds.height / size.height)
        let width = size.width * scale
        let height = size.height * scale
        let mapped = CGRect(x: (bounds.width - width) / 2 + rect.minX * width,
                            y: (bounds.height - height) / 2 + rect.minY * height,
                            width: rect.width * width, height: rect.height * height)
        lipOutline.path = UIBezierPath(roundedRect: mapped, cornerRadius: 6).cgPath
    }
}
