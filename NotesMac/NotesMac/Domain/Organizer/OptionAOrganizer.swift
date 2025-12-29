import Foundation

struct OptionAOrganizer {
    private let scorer = SentenceScorer()
    private let deduper = Deduper()
    private let vocab = VocabularyExtractor()
    private let qa = QuestionAnswerLinker()
    private let renderer = OrganizerOutputRenderer()

    func generate(
        className: String,
        dateYYYYMMDD: String,
        sentences: [TranscriptSentenceRow],
        mutedRanges: [TranscriptJSON.MutedRange],
        markers: [MarkerRow]
    ) -> String {
        let title = "\(className) — \(dateYYYYMMDD)"

        let stars = markers.filter { $0.type == "STAR" }
        let questions = markers.filter { $0.type == "QUESTION" }

        let scored = scorer.score(sentences: sentences, mutedRanges: mutedRanges)
        let top = deduper.dedupe(scored, maxCount: 24)

        // Summary: prefer star contexts, then fill with top-scored sentences.
        var summary: [String] = []
        for m in stars.prefix(3) {
            let s = m.contextText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { summary.append(s) }
        }
        for c in top {
            if summary.count >= 6 { break }
            let t = c.sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty, !summary.contains(t) { summary.append(t) }
        }
        if summary.count < 3 {
            for c in scored.sorted(by: { $0.score > $1.score }).prefix(6) {
                let t = c.sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if summary.count >= 3 { break }
                if !t.isEmpty, !summary.contains(t) { summary.append(t) }
            }
        }

        // ⭐ sections
        let starSections: [(heading: String, bullets: [String])] = stars.map { m in
            let heading = "\(TimeFormatting.mmss(m.atSec)) — \(truncate(m.contextText, max: 60))"
            let bullets = splitToBullets(m.contextText, maxBullets: 3)
            return (heading, bullets)
        }

        // ❓ linking
        let linked = qa.link(questions: questions, sentences: sentences)
        let qs: [(String, String?)] = linked.map { l in
            let qText = l.question.contextText.isEmpty ? "Question at \(TimeFormatting.mmss(l.question.atSec))" : l.question.contextText
            return (qText, l.possibleAnswer?.text)
        }

        // Vocabulary
        let vocabItems = vocab.extract(sentences: sentences, mutedRanges: mutedRanges, maxItems: 15)

        // Steps
        let stepLines = sentences
            .filter { s in
                let t = s.text.lowercased()
                return t.contains("first") || t.contains("next") || t.contains("then") || t.contains("finally") || t.contains("step")
            }
            .prefix(12)
            .map { $0.text }

        let output = OrganizerOutput(
            title: title,
            summaryBullets: summary,
            starSections: starSections,
            questions: qs,
            vocabulary: vocabItems,
            steps: Array(stepLines)
        )

        return renderer.renderMarkdown(output)
    }

    private func splitToBullets(_ text: String, maxBullets: Int) -> [String] {
        let parts = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { ".!?;".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(parts.prefix(maxBullets))
    }

    private func truncate(_ s: String, max: Int) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= max { return t }
        let idx = t.index(t.startIndex, offsetBy: max)
        return String(t[..<idx]) + "…"
    }
}
