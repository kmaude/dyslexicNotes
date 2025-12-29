import Foundation

struct LinkedQuestion: Hashable {
    let question: MarkerRow
    let possibleAnswer: TranscriptSentenceRow?
}

struct QuestionAnswerLinker {
    /// Find a "possible answer" by searching forward 30–120 seconds for token overlap.
    func link(
        questions: [MarkerRow],
        sentences: [TranscriptSentenceRow]
    ) -> [LinkedQuestion] {
        questions.map { q in
            let windowStart = q.atSec + 30
            let windowEnd = q.atSec + 120
            let qTokens = Set(q.contextText.tokensLowercased())

            let candidates = sentences.filter { $0.startSec >= windowStart && $0.startSec <= windowEnd }
            let best = candidates.max { a, b in
                overlapScore(qTokens: qTokens, s: a) < overlapScore(qTokens: qTokens, s: b)
            }
            return LinkedQuestion(question: q, possibleAnswer: best)
        }
    }

    private func overlapScore(qTokens: Set<String>, s: TranscriptSentenceRow) -> Double {
        let sTokens = Set(s.text.tokensLowercased())
        guard !qTokens.isEmpty, !sTokens.isEmpty else { return 0 }
        let inter = qTokens.intersection(sTokens).count
        let denom = max(1, qTokens.count)
        return Double(inter) / Double(denom)
    }
}
