import Foundation

enum WhisperBridgeError: Error {
    case modelNotInstalled
    case engineUnavailable
}

/// Abstraction for local transcription (whisper.cpp).
///
/// M3: the app is wired so this can be backed by whisper.cpp when vendored and built.
protocol LocalTranscriptionEngine {
    func transcribe(samplesFloat32: [Float], sampleRate: Int, languageHint: String?) async throws -> [TranscriptJSON.Sentence]
}

/// Default engine used when whisper.cpp is not wired in this build.
struct FallbackTranscriptionEngine: LocalTranscriptionEngine {
    func transcribe(samplesFloat32: [Float], sampleRate: Int, languageHint: String?) async throws -> [TranscriptJSON.Sentence] {
        // Deterministic placeholder transcript to keep the pipeline functional even without the native engine.
        return []
    }
}

