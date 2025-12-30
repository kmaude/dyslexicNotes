import Foundation
import GRDB
import AVFoundation

@MainActor
final class TranscriptionService: ObservableObject {
    enum State: Equatable { case idle, running(noteID: String), stopped }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastError: String?

    private var engine: LocalTranscriptionEngine = FallbackTranscriptionEngine()
    private var scheduler: ChunkScheduler?
    private var bufferTask: Task<Void, Never>?

    private var sampleBuffer: [Float] = []
    private var lastChunkEndSec: Double = 0
    private var resampler: PCMResampler?

    func configureEngine(_ engine: LocalTranscriptionEngine) {
        self.engine = engine
    }

    func start(
        noteID: String,
        chunkSeconds: Int,
        audioBuffers: AsyncStream<AVAudioPCMBuffer>,
        isMuted: @escaping @MainActor () -> Bool,
        db: DatabaseWriter
    ) {
        stop()
        state = .running(noteID: noteID)
        lastError = nil
        sampleBuffer = []
        lastChunkEndSec = 0
        resampler = nil

        // Consume buffers on a Task
        bufferTask = Task { [weak self] in
            guard let self else { return }
            for await buf in audioBuffers {
                guard self.isRunning(noteID: noteID) else { break }
                self.appendAndResample(buffer: buf)
            }
        }

        scheduler = ChunkScheduler(interval: TimeInterval(chunkSeconds)) { [weak self] in
            guard let self else { return }
            Task { await self.flushChunkIfReady(noteID: noteID, isMuted: isMuted, db: db, chunkSeconds: chunkSeconds) }
        }
        scheduler?.start()
    }

    func stop() {
        scheduler?.stop()
        scheduler = nil
        bufferTask?.cancel()
        bufferTask = nil
        state = .stopped
        sampleBuffer = []
        resampler = nil
    }

    func finalizeFullPass(noteID: String, audioURL: URL, db: DatabaseWriter) async {
        // M3: implement full-file refine pass via whisper.cpp.
        // For now, this is a no-op placeholder.
        _ = audioURL
        _ = db
        _ = noteID
    }

    private func isRunning(noteID: String) -> Bool {
        if case .running(let n) = state { return n == noteID }
        return false
    }

    private func appendAndResample(buffer: AVAudioPCMBuffer) {
        if resampler == nil || resampler?.inputSampleRate != buffer.format.sampleRate {
            resampler = PCMResampler(inputFormat: buffer.format)
        }
        guard let resampler else { return }
        guard let mono16k = resampler.convertTo16kMono(buffer) else { return }
        guard let data = mono16k.floatChannelData else { return }
        let frames = Int(mono16k.frameLength)
        sampleBuffer.append(contentsOf: UnsafeBufferPointer(start: data[0], count: frames))
    }

    private func flushChunkIfReady(
        noteID: String,
        isMuted: @escaping @MainActor () -> Bool,
        db: DatabaseWriter,
        chunkSeconds: Int
    ) async {
        guard isRunning(noteID: noteID) else { return }
        guard !isMuted() else {
            // do not transcribe muted ranges
            lastChunkEndSec += Double(chunkSeconds)
            return
        }

        // Best-effort: treat buffer as contiguous audio; timestamps based on chunk cadence.
        let start = lastChunkEndSec
        let end = lastChunkEndSec + Double(chunkSeconds)
        lastChunkEndSec = end

        // Snapshot samples (placeholder; real engine should run on true audio window)
        let samples = sampleBuffer
        sampleBuffer.removeAll(keepingCapacity: true)

        do {
            let sentences = try await engine.transcribe(samplesFloat32: samples, sampleRate: 16000, languageHint: nil)
            if !sentences.isEmpty {
                try await TranscriptDAO(db: db).replaceSentences(noteID: noteID, sentences: sentences)
                try await db.write { db in
                    let content = sentences.map(\.text).joined(separator: " ")
                    try TranscriptFTS.upsert(db: db, noteID: noteID, content: content)
                }
            } else {
                // Deterministic placeholder sentence so the UI can show progress.
                let text = "Transcribing… (\(TimeFormatting.mmss(start))–\(TimeFormatting.mmss(end)))"
                let s = TranscriptJSON.Sentence(startSec: start, endSec: end, text: text, language: nil)
                try await db.write { db in
                    try TranscriptSentenceModel(noteID: noteID, startSec: s.startSec, endSec: s.endSec, text: s.text, language: s.language).insert(db)
                    let all = try TranscriptSentenceModel.filter(Column("note_id") == noteID).fetchAll(db).map(\.text).joined(separator: " ")
                    try TranscriptFTS.upsert(db: db, noteID: noteID, content: all)
                }
            }
        } catch {
            lastError = "Transcription failed: \(error)"
        }
    }
}

private final class PCMResampler {
    private let targetFormat: AVAudioFormat
    private var converter: AVAudioConverter?
    let inputSampleRate: Double

    init(inputFormat: AVAudioFormat) {
        self.inputSampleRate = inputFormat.sampleRate
        self.targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false)!
        self.converter = AVAudioConverter(from: inputFormat, to: targetFormat)
    }

    func convertTo16kMono(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        if converter == nil || converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: targetFormat)
        }
        guard let converter else { return nil }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 8)
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return nil }

        var didProvide = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if didProvide {
                status.pointee = .endOfStream
                return nil
            } else {
                didProvide = true
                status.pointee = .haveData
                return buffer
            }
        }
        if error != nil { return nil }
        return out
    }
}
