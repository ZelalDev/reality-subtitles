import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var recorder = AudioRecorder()
    @StateObject private var benchmarks = BenchmarkStore()
    @State private var processingTime: Double?

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

                    if let processingTime {
                        Text("İşlem süresi: \(BenchmarkStore.seconds(processingTime)) saniye")
                            .font(.subheadline.monospacedDigit())
                    }

                    if !transcription.isEmpty {
                        Text(transcription)
                            .font(.title2)
                            .foregroundStyle(.black)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                    }
                    Text("Ses kaydı işlemden sonra silinir. CSV’de son 10 sonuç tutulur.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if benchmarks.hasResults {
                        ShareLink("CSV sonuçlarını paylaş", item: benchmarks.resultsURL)
                            .disabled(isTranscribing || recorder.isRecording || recorder.isStarting)
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
                        processingTime = nil
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
                .disabled(isTranscribing || recorder.isStarting)
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
        .task {
            do { try benchmarks.refresh() }
            catch { errorMessage = error.localizedDescription }
        }
        .onChange(of: recorder.isRecording) { wasRecording, isRecording in
            // stopRecording publishes false only after closing the temporary audio file.
            guard wasRecording, !isRecording, isTranscribing else { return }

            Task {
                guard let url = recorder.recordedFileURL else {
                    isTranscribing = false
                    errorMessage = "Kayıt dosyası bulunamadı."
                    return
                }
                await transcribe(url)
            }
        }
    }

    @MainActor
    private func transcribe(_ url: URL) async {
        defer {
            do { try recorder.discardRecording(at: url) }
            catch {
                errorMessage = [errorMessage, "Ses kaydı silinemedi: \(error.localizedDescription)"]
                    .compactMap { $0 }.joined(separator: "\n")
            }
            isTranscribing = false
        }
        transcription = ""
        processingTime = nil
        errorMessage = nil
        do {
            // Metadata reading is outside the measured WhisperKit call.
            let audioDuration = try await AVURLAsset(url: url).load(.duration).seconds
            guard audioDuration.isFinite, audioDuration >= 0 else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let result = try await transcriber.transcribe(url)
            transcription = result.text
            processingTime = result.processingTime
            do {
                try benchmarks.appendResult(result, audioURL: url, audioDuration: audioDuration)
            } catch {
                errorMessage = "CSV sonucu kaydedilemedi: \(error.localizedDescription)"
            }
            if transcription.isEmpty, errorMessage == nil {
                errorMessage = "Konuşma algılanamadı. Lütfen tekrar deneyin."
            }
        } catch {
            errorMessage = "Ses metne dönüştürülemedi. Lütfen tekrar deneyin."
            print("❌ Transkripsiyon hatası: \(String(reflecting: error)); \((error as NSError).userInfo)")
        }
    }
}

#Preview {
    ContentView()
}
