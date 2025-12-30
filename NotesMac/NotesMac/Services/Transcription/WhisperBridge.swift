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

#if canImport(WhisperSwift)
import WhisperSwift

final class WhisperCPPTranscriptionEngine: LocalTranscriptionEngine {
    private let context: WhisperContext
    private let threads: Int

    init(modelURL: URL, threads: Int = max(2, ProcessInfo.processInfo.activeProcessorCount - 2)) throws {
        self.context = try WhisperContext(modelURL: modelURL)
        self.threads = threads
    }

    func transcribe(samplesFloat32: [Float], sampleRate: Int, languageHint: String?) async throws -> [TranscriptJSON.Sentence] {
        guard sampleRate == 16_000 else {
            // Resampling should be handled before calling the engine.
            throw NSError(domain: "Notes", code: 2, userInfo: [NSLocalizedDescriptionKey: "Expected 16kHz samples"])
        }

        let segs = try context.transcribe(samples16kMono: samplesFloat32, language: languageHint, threads: threads)
        return segs.map { seg in
            TranscriptJSON.Sentence(startSec: seg.startSec, endSec: seg.endSec, text: seg.text, language: languageHint)
        }
    }
}
#endif

