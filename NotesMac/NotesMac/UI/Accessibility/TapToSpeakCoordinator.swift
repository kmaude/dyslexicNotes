import Foundation
import AVFoundation

@MainActor
final class TapToSpeakCoordinator: ObservableObject {
    private let synth = AVSpeechSynthesizer()

    func speak(text: String, baseRate: Double = 1.0) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let u = AVSpeechUtterance(string: trimmed)
        // Map playback speed (0.7–1.6) to speech rate range.
        // AVSpeechUtterance rate is not linear; keep conservative.
        let clamped = max(0.7, min(1.6, baseRate))
        let r = Float(AVSpeechUtteranceDefaultSpeechRate) * Float(0.85 + (clamped - 1.0) * 0.35)
        u.rate = max(0.35, min(0.60, r))
        u.voice = AVSpeechSynthesisVoice(language: "en-US")

        synth.stopSpeaking(at: .immediate)
        synth.speak(u)
    }
}
