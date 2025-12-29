import Foundation
import WhisperC

public final class WhisperContext {
    private var raw: UnsafeMutablePointer<notes_whisper_context>?

    public init(modelURL: URL) throws {
        let path = modelURL.path
        guard let ctx = path.withCString({ notes_whisper_init($0) }) else {
            throw NSError(domain: "WhisperSwift", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to init whisper context"])
        }
        self.raw = ctx
    }

    deinit {
        if let raw {
            notes_whisper_free(raw)
        }
    }

    public struct Segment: Hashable {
        public let startSec: Double
        public let endSec: Double
        public let text: String
    }

    public func transcribe(samples16kMono: [Float], language: String?, threads: Int) throws -> [Segment] {
        guard let raw else { return [] }

        let rc: Int32 = samples16kMono.withUnsafeBufferPointer { buf in
            guard let base = buf.baseAddress else { return -1 }
            return (language ?? "").withCString { lang in
                Int32(notes_whisper_transcribe(raw, base, Int32(buf.count), lang, Int32(threads)))
            }
        }
        if rc != 0 {
            throw NSError(domain: "WhisperSwift", code: Int(rc), userInfo: [NSLocalizedDescriptionKey: "whisper_full failed (\(rc))"])
        }

        let n = Int(notes_whisper_n_segments(raw))
        guard n > 0 else { return [] }

        var out: [Segment] = []
        out.reserveCapacity(n)
        for i in 0..<n {
            let t0 = Double(notes_whisper_segment_t0(raw, Int32(i))) * 0.01
            let t1 = Double(notes_whisper_segment_t1(raw, Int32(i))) * 0.01
            let cstr = notes_whisper_segment_text(raw, Int32(i))
            let text = String(cString: cstr).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                out.append(Segment(startSec: t0, endSec: t1, text: text))
            }
        }
        return out
    }
}

