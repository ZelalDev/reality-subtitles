import Foundation
import WhisperKit

// Keeps model loading and file transcription separate from the recorder and UI.
actor AudioTranscriber {
    private var whisperKit: WhisperKit?

    func transcribe(_ url: URL) async throws -> String {
        if whisperKit == nil {
            // Exact multilingual base variant; downloaded on first use.
            whisperKit = try await WhisperKit(WhisperKitConfig(
                model: "openai_whisper-base",
                load: true,
                download: true
            ))
        }

        guard let whisperKit else {
            throw CocoaError(.coderValueNotFound)
        }

        let results = try await whisperKit.transcribe(
            audioPath: url.path,
            decodeOptions: DecodingOptions(
                task: .transcribe,
                language: "tr",
                usePrefillPrompt: true,
                detectLanguage: false,
                skipSpecialTokens: true
            )
        )

        return results.map { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
