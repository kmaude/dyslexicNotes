import Foundation
import AppKit

struct RTFExporter {
    func export(text: String, to url: URL) throws {
        let font = NSFont(name: "OpenDyslexic-Regular", size: 12) ?? NSFont.systemFont(ofSize: 12)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        style.paragraphSpacing = 8

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: style,
        ]

        let plain = stripMarkdown(text)
        let attributed = NSAttributedString(string: plain, attributes: attrs)
        let data = try attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        try FileSafety.atomicWrite(data, to: url)
    }

    private func stripMarkdown(_ s: String) -> String {
        // Minimal: drop leading markdown markers for readability.
        return s
            .replacingOccurrences(of: "# ", with: "")
            .replacingOccurrences(of: "## ", with: "")
            .replacingOccurrences(of: "### ", with: "")
            .replacingOccurrences(of: "- ", with: "• ")
    }
}
