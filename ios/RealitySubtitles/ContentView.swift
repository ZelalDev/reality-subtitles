import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var recorder = AudioRecorder()

    @State private var transcriber = AudioTranscriber()
    @State private var isTranscribing = false
    @State private var transcription = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 25) {

            Text("Reality Subtitles")
                .font(.largeTitle)
                .bold()

            Text("Türkçe konuşmayı yazıya dönüştürme")
                .font(.subheadline)

            if recorder.isRecording {

                Text("🔴 Kayıt yapılıyor...")
                    .foregroundStyle(.red)

                Button("Kaydı Durdur") {
                    isTranscribing = true
                    transcription = ""
                    errorMessage = nil
                    recorder.stopRecording()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isTranscribing)

            } else {

                Button("Kaydı Başlat") {
                    recorder.startRecording()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isTranscribing)
            }

            if isTranscribing {
                Text("Metne dönüştürülüyor...")
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if !transcription.isEmpty {
                ScrollView {
                    Text(transcription)
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
        .padding()
        .onChange(of: recorder.isRecording) { wasRecording, isRecording in
            // stopRecording publishes false only after closing recording.m4a.
            guard wasRecording, !isRecording, isTranscribing else { return }

            Task {
                defer { isTranscribing = false }

                do {
                    guard let url = recorder.recordedFileURL else {
                        throw CocoaError(.fileNoSuchFile)
                    }
                    transcription = try await transcriber.transcribe(url)
                    if transcription.isEmpty {
                        errorMessage = "Konuşma algılanamadı. Lütfen tekrar deneyin."
                    }
                } catch {
                    errorMessage = "Ses metne dönüştürülemedi. Lütfen tekrar deneyin."
                    print("❌ Transkripsiyon hatası: \(String(reflecting: error)); \((error as NSError).userInfo)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
