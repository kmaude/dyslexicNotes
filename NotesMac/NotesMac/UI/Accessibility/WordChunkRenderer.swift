import Foundation
import SwiftUI

enum WordChunkRenderer {
    static func attributed(_ text: String, mode: WordChunkMode) -> AttributedString {
        guard mode != .off else { return AttributedString(text) }

        var out = AttributedString()
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        for (wi, wSub) in words.enumerated() {
            let w = String(wSub)
            if wi > 0 { out.append(AttributedString(" ")) }

            if w.count >= 7 {
                out.append(attributedLongWord(w, mode: mode))
            } else {
                out.append(AttributedString(w))
            }
        }
        return out
    }

    private static func attributedLongWord(_ word: String, mode: WordChunkMode) -> AttributedString {
        switch mode {
        case .off:
            return AttributedString(word)
        case .softChunking:
            return chunk(word, by: 3, tint: .secondary.opacity(0.75))
        case .syllableHinting:
            return syllableHint(word)
        }
    }

    private static func chunk(_ word: String, by n: Int, tint: Color) -> AttributedString {
        var a = AttributedString()
        var i = 0
        var alt = false
        while i < word.count {
            let start = word.index(word.startIndex, offsetBy: i)
            let end = word.index(start, offsetBy: min(n, word.count - i), limitedBy: word.endIndex) ?? word.endIndex
            var part = AttributedString(String(word[start..<end]))
            if alt {
                part.foregroundColor = tint
            }
            a.append(part)
            alt.toggle()
            i += n
        }
        return a
    }

    private static func syllableHint(_ word: String) -> AttributedString {
        let vowels = CharacterSet(charactersIn: "aeiouyAEIOUY")
        var a = AttributedString()
        var current = ""
        var currentIsVowelGroup = false
        var alt = false

        func flush() {
            guard !current.isEmpty else { return }
            var part = AttributedString(current)
            if currentIsVowelGroup {
                part.foregroundColor = alt ? .secondary.opacity(0.85) : .primary
                alt.toggle()
            }
            a.append(part)
            current = ""
        }

        for ch in word {
            let isVowel = String(ch).rangeOfCharacter(from: vowels) != nil
            if current.isEmpty {
                current = String(ch)
                currentIsVowelGroup = isVowel
                continue
            }
            if isVowel == currentIsVowelGroup {
                current.append(ch)
            } else {
                flush()
                current = String(ch)
                currentIsVowelGroup = isVowel
            }
        }
        flush()
        return a
    }
}
