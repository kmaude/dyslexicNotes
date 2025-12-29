import Foundation

enum SentenceHighlighter {
    static func index(for timeSec: Double, in sentences: [TranscriptSentenceRow]) -> Int? {
        guard !sentences.isEmpty else { return nil }
        let t = timeSec

        var lo = 0
        var hi = sentences.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            let s = sentences[mid]
            if t < s.startSec {
                hi = mid - 1
            } else if t > s.endSec {
                lo = mid + 1
            } else {
                return mid
            }
        }
        // If between sentences, pick the last sentence that started before time.
        let idx = max(0, min(sentences.count - 1, hi))
        return idx
    }
}
