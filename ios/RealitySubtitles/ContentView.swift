import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var recorder = AudioRecorder()

    @State private var transcriber = AudioTranscriber()
    @State private var isTranscribing = false
    @State private var transcription = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Text("Reality Subtitles")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.top, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isTranscribing {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(.gray)
                            Text("Metne dönüştürülüyor...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.red)
                    }

                    if !transcription.isEmpty {
                        Text(transcription)
                            .font(.title2)
                            .foregroundStyle(.black)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                Color(red: 0.95, green: 0.96, blue: 0.97),
                in: RoundedRectangle(cornerRadius: 24)
            )

            VStack(spacing: 12) {
                Button {
                    if recorder.isRecording {
                        isTranscribing = true
                        transcription = ""
                        errorMessage = nil
                        recorder.stopRecording()
                    } else {
                        recorder.startRecording()
                    }
                } label: {
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(.red, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isTranscribing)
                .opacity(isTranscribing ? 0.5 : 1)
                .accessibilityLabel(recorder.isRecording ? "Kaydı Durdur" : "Kaydı Başlat")
                .accessibilityValue(recorder.isRecording ? "Kayıt yapılıyor" : "")

                Text(recorder.isRecording ? "Kaydı Durdur" : "Kaydı Başlat")
                    .font(.subheadline)
                    .foregroundStyle(.black)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .preferredColorScheme(.light)
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
