import Foundation

struct OrganizerOutput: Hashable {
    let title: String
    let summaryBullets: [String]
    let starSections: [(heading: String, bullets: [String])]
    let questions: [(question: String, possibleAnswer: String?)]
    let vocabulary: [VocabularyItem]
    let steps: [String]
}

struct OrganizerOutputRenderer {
    func renderMarkdown(_ out: OrganizerOutput) -> String {
        var lines: [String] = []
        lines.append("# \(out.title)")
        lines.append("")

        lines.append("## Summary")
        for b in out.summaryBullets.prefix(6) {
            lines.append("- \(b)")
        }
        lines.append("")

        if !out.starSections.isEmpty {
            lines.append("## Key Points ⭐")
            for sec in out.starSections {
                lines.append("### \(sec.heading)")
                for b in sec.bullets.prefix(3) {
                    lines.append("- \(b)")
                }
                lines.append("")
            }
        }

        if !out.questions.isEmpty {
            lines.append("## Questions ❓")
            for q in out.questions {
                lines.append("- **\(q.question)**")
                if let a = q.possibleAnswer, !a.isEmpty {
                    lines.append("  - Possible answer: \(a)")
                } else {
                    lines.append("  - Possible answer: (not found yet)")
                }
            }
            lines.append("")
        }

        if !out.vocabulary.isEmpty {
            lines.append("## Vocabulary / Key Terms")
            for v in out.vocabulary.prefix(20) {
                lines.append("- **\(v.term)** — \(v.context)")
            }
            lines.append("")
        }

        if !out.steps.isEmpty {
            lines.append("## Steps / Timeline")
            for s in out.steps {
                lines.append("- \(s)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
