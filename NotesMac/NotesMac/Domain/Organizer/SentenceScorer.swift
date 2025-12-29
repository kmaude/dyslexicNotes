import Foundation

struct ScoredSentence: Hashable {
    let sentence: TranscriptSentenceRow
    let score: Double
    let reasons: [String]
}

struct SentenceScorer {
    private static let emphasisWords: Set<String> = [
        "important", "remember", "test", "quiz", "exam", "midterm", "final",
        "key", "note", "notes", "homework", "assignment", "due", "must"
    ]
    private static let stepWords: Set<String> = [
        "first", "second", "third", "next", "then", "finally", "step"
    ]

    func score(sentences: [TranscriptSentenceRow], mutedRanges: [TranscriptJSON.MutedRange]) -> [ScoredSentence] {
        let muted = mutedRanges.map { ($0.startSec, $0.endSec) }
        return sentences.compactMap { s in
            guard !isMuted(s, muted: muted) else { return nil }
            let (score, reasons) = scoreOne(s)
            return ScoredSentence(sentence: s, score: score, reasons: reasons)
        }
    }

    private func isMuted(_ s: TranscriptSentenceRow, muted: [(Double, Double)]) -> Bool {
        for (a, b) in muted {
            // any overlap means excluded
            if s.endSec >= a && s.startSec <= b { return true }
        }
        return false
    }

    private func scoreOne(_ s: TranscriptSentenceRow) -> (Double, [String]) {
        let t = s.text
        let tokens = t.tokensLowercased()
        guard !tokens.isEmpty else { return (0, []) }

        var score: Double = 0
        var reasons: [String] = []

        // Baseline: prefer medium-length sentences
        let len = Double(tokens.count)
        if len >= 6 && len <= 24 {
            score += 0.8
        } else if len < 6 {
            score -= 0.4
        } else {
            score -= 0.2
        }

        // Emphasis words
        let emphasisHits = tokens.filter { Self.emphasisWords.contains($0) }.count
        if emphasisHits > 0 {
            score += Double(emphasisHits) * 1.2
            reasons.append("emphasis")
        }

        // Definitions heuristics
        let lower = t.lowercased()
        if lower.contains(" is ") || lower.contains(" means ") || lower.contains(" called ") {
            score += 1.4
            reasons.append("definition")
        }

        // Step indicators
        let stepHits = tokens.filter { Self.stepWords.contains($0) }.count
        if stepHits > 0 {
            score += Double(stepHits) * 0.9
            reasons.append("steps")
        }

        // Keyword density: reward repeated non-stopword terms
        let stop: Set<String> = ["the","a","an","and","or","but","to","of","in","on","for","with","we","you","they","it","is","are","was","were","be","this","that","these","those"]
        let important = tokens.filter { $0.count >= 4 && !stop.contains($0) }
        let counts = Dictionary(grouping: important, by: { $0 }).mapValues(\.count)
        let repeats = counts.values.filter { $0 >= 2 }.count
        if repeats > 0 {
            score += Double(repeats) * 0.6
            reasons.append("keyword-density")
        }

        return (score, reasons)
    }
}
