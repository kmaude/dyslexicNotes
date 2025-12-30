import Foundation
#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

struct DOCXExporter {
    func export(text: String, to url: URL) throws {
        #if canImport(ZIPFoundation)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        guard let archive = Archive(url: url, accessMode: .create) else {
            throw NSError(domain: "Notes", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create DOCX archive"])
        }

        let docXML = makeDocumentXML(text: text)
        let contentTypes = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
        </Types>
        """

        let rels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
        </Relationships>
        """

        try add(archive: archive, path: "[Content_Types].xml", contents: contentTypes)
        try add(archive: archive, path: "_rels/.rels", contents: rels)
        try add(archive: archive, path: "word/document.xml", contents: docXML)
        #else
        throw NSError(domain: "Notes", code: 2, userInfo: [NSLocalizedDescriptionKey: "DOCX export requires ZIPFoundation (not linked)"])
        #endif
    }

    #if canImport(ZIPFoundation)
    private func add(archive: Archive, path: String, contents: String) throws {
        let data = Data(contents.utf8)
        try archive.addEntry(with: path, type: .file, uncompressedSize: UInt32(data.count), compressionMethod: .deflate) { position, size in
            let start = Int(position)
            let end = min(start + Int(size), data.count)
            return data.subdata(in: start..<end)
        }
    }
    #endif

    private func makeDocumentXML(text: String) -> String {
        let escapedLines = stripMarkdown(text)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { escapeXML(String($0)) }

        let paragraphs = escapedLines.map { line in
            """
            <w:p><w:r><w:t xml:space="preserve">\(line)</w:t></w:r></w:p>
            """
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:body>
            \(paragraphs)
          </w:body>
        </w:document>
        """
    }

    private func escapeXML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func stripMarkdown(_ s: String) -> String {
        s.replacingOccurrences(of: "# ", with: "")
            .replacingOccurrences(of: "## ", with: "")
            .replacingOccurrences(of: "### ", with: "")
            .replacingOccurrences(of: "- ", with: "• ")
    }
}
