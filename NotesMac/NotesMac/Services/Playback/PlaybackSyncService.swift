import Foundation

@MainActor
final class PlaybackSyncService: ObservableObject {
    @Published private(set) var highlightedSentenceIndex: Int? = nil

    private var sentences: [TranscriptSentenceRow] = []

    func setSentences(_ sentences: [TranscriptSentenceRow]) {
        self.sentences = sentences
        self.highlightedSentenceIndex = nil
    }

    func update(currentTimeSec: Double) {
        highlightedSentenceIndex = SentenceHighlighter.index(for: currentTimeSec, in: sentences)
    }
}
