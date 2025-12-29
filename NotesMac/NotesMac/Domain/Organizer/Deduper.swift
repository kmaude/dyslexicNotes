import Foundation

struct Deduper {
    /// Greedy dedupe by token overlap (Jaccard).
    func dedupe(_ candidates: [ScoredSentence], maxCount: Int, overlapThreshold: Double = 0.65) -> [ScoredSentence] {
        var picked: [ScoredSentence] = []
        for c in candidates.sorted(by: { $0.score > $1.score }) {
            if picked.count >= maxCount { break }
            if picked.allSatisfy({ jaccard($0.sentence.text, c.sentence.text) < overlapThreshold }) {
                picked.append(c)
            }
        }
        return picked
    }

    private func jaccard(_ a: String, _ b: String) -> Double {
        let ta = Set(a.tokensLowercased())
        let tb = Set(b.tokensLowercased())
        guard !ta.isEmpty, !tb.isEmpty else { return 0 }
        let inter = ta.intersection(tb).count
        let uni = ta.union(tb).count
        return Double(inter) / Double(uni)
    }
}
