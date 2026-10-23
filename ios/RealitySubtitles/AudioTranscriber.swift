import Foundation
import WhisperKit

nonisolated enum WhisperModel: String, CaseIterable, Sendable {
    case tiny
    case base

    var displayName: String {
        switch self {
        case .tiny: "Whisper Tiny"
        case .base: "Whisper Base"
        }
    }

    var modelName: String {
        switch self {
        case .tiny: "openai_whisper-tiny"
        case .base: "openai_whisper-base"
        }
    }
}

// Keeps model loading and file transcription separate from the recorder and UI.
actor AudioTranscriber {
    private var whisperKit: WhisperKit?
    private var loadedModel: WhisperModel?

    func transcribe(_ url: URL, model: WhisperModel) async throws -> String {
        if whisperKit == nil || loadedModel != model {
            // Release the previous model before loading the selected one.
            whisperKit = nil
            loadedModel = nil
            whisperKit = try await WhisperKit(WhisperKitConfig(
                model: model.modelName,
                load: true,
                download: true
            ))
            loadedModel = model
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
        let results = try await whisperKit.transcribe(
            audioPath: url.path,
            decodeOptions: options
        )
        return results.map { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
