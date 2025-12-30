import Foundation

@MainActor
final class ReplayLoopController: ObservableObject {
    enum Mode: String, Codable, CaseIterable {
        case off
        case replayLastSentence
        case autoLoopCurrentSentence
    }

    @Published var mode: Mode = .off

    /// The sentence bounds currently eligible for looping/replay.
    private(set) var activeSentenceBounds: (start: Double, end: Double)?

    func setActiveSentenceBounds(start: Double, end: Double) {
        guard end > start else { activeSentenceBounds = nil; return }
        activeSentenceBounds = (start, end)
    }

    func clear() {
        activeSentenceBounds = nil
        mode = .off
    }
}
