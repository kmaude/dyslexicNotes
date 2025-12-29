import Foundation

struct ExplainSimplyEngine {
    /// Deterministic, offline simplification. Never overwrites original.
    func simplify(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "" }

        // 1) Split very long sentences at commas/semicolons/and/because.
        t = t.replacingOccurrences(of: ";", with: ". ")
        t = t.replacingOccurrences(of: " because ", with: ". Because ")
        t = t.replacingOccurrences(of: ", and ", with: ". ")
        t = t.replacingOccurrences(of: ",", with: ". ")

        // 2) Replace a few common complex phrases.
        let replacements: [(String, String)] = [
            ("therefore", "so"),
            ("however", "but"),
            ("approximately", "about"),
            ("utilize", "use"),
            ("obtain", "get"),
            ("demonstrate", "show"),
            ("indicate", "show"),
        ]
        for (a, b) in replacements {
            t = t.replacingOccurrences(of: a, with: b, options: [.caseInsensitive])
        }

        // 3) Clean up extra whitespace / repeated periods.
        while t.contains("..") { t = t.replacingOccurrences(of: "..", with: ".") }
        t = t.replacingOccurrences(of: "  ", with: " ")

        // 4) Make it bullet-like if multiple sentences.
        let parts = t
            .split(separator: ".", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.count <= 1 {
            return t
        }
        return parts.map { "• \($0)." }.joined(separator: "\n")
    }
}
