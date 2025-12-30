import Foundation

struct VocabularyItem: Hashable {
    let term: String
    let context: String
}

struct VocabularyExtractor {
    /// Extract simple key terms/phrases (1–3 tokens) with contexts.
    func extract(sentences: [TranscriptSentenceRow], mutedRanges: [TranscriptJSON.MutedRange], maxItems: Int) -> [VocabularyItem] {
        let muted = mutedRanges.map { ($0.startSec, $0.endSec) }
        let eligible = sentences.filter { s in
            !muted.contains(where: { s.endSec >= $0.0 && s.startSec <= $0.1 })
        }

        var counts: [String: Int] = [:]
        var contexts: [String: String] = [:]
        let stop: Set<String> = ["the","a","an","and","or","but","to","of","in","on","for","with","we","you","they","it","is","are","was","were","be","this","that","these","those"]

        for s in eligible {
            let toks = s.text.tokensLowercased().filter { $0.count >= 4 && !stop.contains($0) }
            // 1-grams
            for t in toks {
                counts[t, default: 0] += 1
                contexts[t] = contexts[t] ?? s.text
            }
            // 2-grams
            if toks.count >= 2 {
                for i in 0..<(toks.count - 1) {
                    let g = toks[i] + " " + toks[i + 1]
                    counts[g, default: 0] += 1
                    contexts[g] = contexts[g] ?? s.text
                }
            }
            // 3-grams
            if toks.count >= 3 {
                for i in 0..<(toks.count - 2) {
                    let g = toks[i] + " " + toks[i + 1] + " " + toks[i + 2]
                    counts[g, default: 0] += 1
                    contexts[g] = contexts[g] ?? s.text
                }
            }
        }

        let sorted = counts
            .filter { $0.key.count <= 40 }
            .sorted { $0.value == $1.value ? $0.key.count < $1.key.count : $0.value > $1.value }

        var out: [VocabularyItem] = []
        for (term, _) in sorted {
            if out.count >= maxItems { break }
            // Avoid sub-phrases when longer phrase already chosen
            if out.contains(where: { $0.term.contains(term) }) { continue }
            out.append(VocabularyItem(term: term, context: contexts[term] ?? ""))
        }
        return out
    }
}
