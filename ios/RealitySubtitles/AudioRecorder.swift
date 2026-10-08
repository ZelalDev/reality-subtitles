import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {

    private var audioRecorder: AVAudioRecorder?

    private let audioQueue = DispatchQueue(
        label: "AudioRecorder.audioQueue"
    )

    @Published private(set) var isRecording = false
    @Published private(set) var recordedFileURL: URL?

    func startRecording() {
        audioQueue.async { [self] in
            guard audioRecorder == nil else { return }

            let session = AVAudioSession.sharedInstance()

            do {
                try session.setCategory(.record, mode: .default)
                try session.setActive(true)

                let documents = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0]

                let url = documents.appendingPathComponent(
                    "recording.m4a"
                )

                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey:
                        AVAudioQuality.high.rawValue
                ]

                let recorder = try AVAudioRecorder(
                    url: url,
                    settings: settings
                )

                guard recorder.record() else {
                    recorder.deleteRecording()
                    throw NSError(
                        domain: "AudioRecorder",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Ses kaydı başlatılamadı."
                        ]
                    )
                }

                audioRecorder = recorder

                DispatchQueue.main.async { [self] in
                    recordedFileURL = url
                    isRecording = true
                }

                print("🎙️ Kayıt başladı")
                print("📁 \(url.path)")

            } catch {
                audioRecorder = nil

                do {
                    try session.setActive(
                        false,
                        options: .notifyOthersOnDeactivation
                    )
                } catch {
                    print("⚠️ Ses oturumu kapatılamadı: \(error)")
                }

                print("❌ Kayıt başlatılamadı: \(error)")
            }
        }
    }

    func stopRecording() {
        audioQueue.async { [self] in
            guard let recorder = audioRecorder else { return }

            let url = recorder.url

            recorder.stop()
            audioRecorder = nil

            do {
                try AVAudioSession.sharedInstance().setActive(
                    false,
                    options: .notifyOthersOnDeactivation
                )
            } catch {
                print("⚠️ Ses oturumu kapatılamadı: \(error)")
            }

            DispatchQueue.main.async { [self] in
                isRecording = false
            }

            print("⏹️ Kayıt durduruldu")

            do {
                let attributes =
                    try FileManager.default.attributesOfItem(
                        atPath: url.path
                    )

                let size = (attributes[.size] as? NSNumber)?
                    .uint64Value ?? 0

                print("📁 \(url.path)")
                print("📦 Dosya boyutu: \(size) byte")

            } catch {
                print("❌ Kayıt dosyası okunamadı: \(error)")
            }
        }
    }
}
