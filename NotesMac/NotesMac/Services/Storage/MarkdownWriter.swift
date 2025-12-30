import Foundation

enum MarkdownWriter {
    static func write(_ markdown: String, to url: URL) throws {
        try FileSafety.atomicWrite(Data((markdown + "\n").utf8), to: url)
    }
}
