import Foundation
import WhisperKit

nonisolated struct TranscriptionMeasurement: Sendable {
    let modelName: String
    let text: String
    let processingTime: Double
}

// Keeps model loading and file transcription separate from the recorder and UI.
actor AudioTranscriber {
    private var whisperKit: WhisperKit?

    func transcribe(_ url: URL) async throws -> TranscriptionMeasurement {
        if whisperKit == nil {
            // Exact multilingual tiny variant; downloaded on first use.
            whisperKit = try await WhisperKit(WhisperKitConfig(
                model: "openai_whisper-tiny",
                load: true,
                download: true
            ))
        }

        guard let whisperKit else {
            throw CocoaError(.coderValueNotFound)
        }

        let options = DecodingOptions(
            task: .transcribe,
            language: "tr",
            usePrefillPrompt: true,
            detectLanguage: false,
            skipSpecialTokens: true
        )
        // Monotonic wall time for this call only; model loading above is excluded.
        let clock = ContinuousClock()
        let start = clock.now
        let results = try await whisperKit.transcribe(
            audioPath: url.path,
            decodeOptions: options
        )
        let elapsed = start.duration(to: clock.now).components
        let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
        print(String(format: "Processing time: %.3f seconds", locale: Locale(identifier: "en_US_POSIX"), seconds))

        return TranscriptionMeasurement(
            modelName: "Tiny",
            text: results.map { $0.text }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines),
            processingTime: seconds
        )
    }
}
