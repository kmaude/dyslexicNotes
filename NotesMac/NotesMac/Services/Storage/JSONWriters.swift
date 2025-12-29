import Foundation

enum JSONWriters {
    static func writeMeta(_ meta: MetaJSON, to url: URL) throws {
        let data = try JSONEncoder.pretty.encode(meta)
        try FileSafety.atomicWrite(data, to: url)
    }

    static func writeTranscript(_ transcript: TranscriptJSON, to url: URL) throws {
        let data = try JSONEncoder.pretty.encode(transcript)
        try FileSafety.atomicWrite(data, to: url)
    }

    static func writeTranscriptText(_ transcript: TranscriptJSON, to url: URL) throws {
        var lines: [String] = []

        for mr in transcript.mutedRanges {
            let a = TimeFormatting.mmss(mr.startSec)
            let b = TimeFormatting.mmss(mr.endSec)
            lines.append("⏸ MUTED (\(a)–\(b))")
        }
        for s in transcript.sentences {
            lines.append(s.text)
        }

        let text = lines.joined(separator: "\n") + "\n"
        try FileSafety.atomicWrite(Data(text.utf8), to: url)
    }

    static func writeMarkers(_ markers: MarkersJSON, to url: URL) throws {
        let data = try JSONEncoder.pretty.encode(markers)
        try FileSafety.atomicWrite(data, to: url)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }
}
