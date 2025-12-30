import Foundation
import AVFoundation

enum AudioCaptureError: Error {
    case alreadyRunning
    case notRunning
    case exportFailed
}

struct AudioPart: Hashable {
    let url: URL
    let startSec: Double
    let endSec: Double
}

struct MutedRange: Hashable {
    let startSec: Double
    let endSec: Double
}

@MainActor
final class AudioCaptureService: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case paused
        case stopped
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var elapsedSec: Double = 0
    @Published private(set) var isMuted: Bool = false

    private let engine = AVAudioEngine()
    private var file: AVAudioFile?
    private var timer: Timer?

    private var startedAt: Date?
    private var pauseStartedAt: Date?
    private var accumulatedPause: TimeInterval = 0

    private var currentPartStartSec: Double = 0
    private var parts: [AudioPart] = []

    private var mutedStartSec: Double?
    private(set) var mutedRanges: [MutedRange] = []

    private var audioContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    private var audioStream: AsyncStream<AVAudioPCMBuffer>?

    private let tempRoot: URL = URL.notesAppSupport.appendingPathComponent("Temp", isDirectory: true)

    func buffers() -> AsyncStream<AVAudioPCMBuffer> {
        if let audioStream { return audioStream }
        let stream = AsyncStream<AVAudioPCMBuffer> { continuation in
            self.audioContinuation = continuation
        }
        self.audioStream = stream
        return stream
    }

    func start(noteID: String) throws {
        guard state == .idle || state == .stopped else { throw AudioCaptureError.alreadyRunning }

        try FileSafety.ensureDirectory(tempRoot)
        let noteTemp = tempRoot.appendingPathComponent(noteID, isDirectory: true)
        try? FileManager.default.removeItem(at: noteTemp)
        try FileSafety.ensureDirectory(noteTemp)

        parts = []
        mutedRanges = []
        mutedStartSec = nil
        accumulatedPause = 0
        startedAt = Date()
        pauseStartedAt = nil
        elapsedSec = 0

        isMuted = false
        currentPartStartSec = 0

        try startNewPCMPart(noteID: noteID, partIndex: 0)
        attachTap()
        try engine.start()

        state = .recording
        startTimer()
    }

    func pause() throws {
        guard state == .recording else { return }
        pauseStartedAt = Date()
        engine.pause()
        state = .paused
    }

    func resume(noteID: String) throws {
        guard state == .paused else { return }
        if let pauseStartedAt {
            accumulatedPause += Date().timeIntervalSince(pauseStartedAt)
        }
        self.pauseStartedAt = nil

        try startNewPCMPart(noteID: noteID, partIndex: parts.count)
        attachTap()
        try engine.start()
        state = .recording
    }

    func toggleMute() {
        guard state == .recording || state == .paused else { return }
        let newValue = !isMuted
        isMuted = newValue
        if newValue {
            mutedStartSec = elapsedSec
        } else {
            if let start = mutedStartSec {
                mutedRanges.append(MutedRange(startSec: start, endSec: elapsedSec))
            }
            mutedStartSec = nil
        }
    }

    func stopAndExport(to finalM4AURL: URL) async throws -> (parts: [AudioPart], muted: [MutedRange], sampleRate: Double, channels: Int) {
        guard state == .recording || state == .paused else { throw AudioCaptureError.notRunning }

        if isMuted, let start = mutedStartSec {
            mutedRanges.append(MutedRange(startSec: start, endSec: elapsedSec))
            mutedStartSec = nil
            isMuted = false
        }

        timer?.invalidate()
        timer = nil

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        file = nil

        // Close last part range
        if var last = parts.last {
            last = AudioPart(url: last.url, startSec: last.startSec, endSec: elapsedSec)
            parts[parts.count - 1] = last
        }

        state = .stopped

        // Stitch PCM parts into one M4A
        try await exportM4A(parts: parts.map(\.url), to: finalM4AURL)

        let format = engine.inputNode.outputFormat(forBus: 0)
        return (parts: parts, muted: mutedRanges, sampleRate: format.sampleRate, channels: Int(format.channelCount))
    }

    // MARK: - Internals

    private func startNewPCMPart(noteID: String, partIndex: Int) throws {
        let noteTemp = tempRoot.appendingPathComponent(noteID, isDirectory: true)
        try FileSafety.ensureDirectory(noteTemp)

        let partURL = noteTemp.appendingPathComponent(String(format: "part-%03d.caf", partIndex))
        let format = engine.inputNode.outputFormat(forBus: 0)
        file = try AVAudioFile(forWriting: partURL, settings: format.settings)

        // Close previous part's end if needed
        if var last = parts.last, last.endSec == 0 {
            last = AudioPart(url: last.url, startSec: last.startSec, endSec: elapsedSec)
            parts[parts.count - 1] = last
        }

        let start = elapsedSec
        parts.append(AudioPart(url: partURL, startSec: start, endSec: 0))
        currentPartStartSec = start
    }

    private func attachTap() {
        engine.inputNode.removeTap(onBus: 0)
        let format = engine.inputNode.outputFormat(forBus: 0)
        engine.inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                try self.file?.write(from: buffer)
            } catch {
                // If disk write fails, we still keep the engine alive; warnings monitor handles alerting.
            }
            self.audioContinuation?.yield(buffer)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let startedAt else { return }
            guard self.state == .recording || self.state == .paused else { return }

            if self.state == .paused {
                // elapsed stays frozen
                return
            }

            let wall = Date().timeIntervalSince(startedAt)
            self.elapsedSec = max(0, wall - self.accumulatedPause)
        }
    }

    private func exportM4A(parts: [URL], to outURL: URL) async throws {
        try FileSafety.ensureDirectory(outURL.deletingLastPathComponent())
        if FileManager.default.fileExists(atPath: outURL.path) {
            try FileManager.default.removeItem(at: outURL)
        }

        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw AudioCaptureError.exportFailed
        }

        var cursor = CMTime.zero
        for url in parts {
            let asset = AVURLAsset(url: url)
            guard let aTrack = try await asset.loadTracks(withMediaType: .audio).first else { continue }
            let duration = try await asset.load(.duration)
            try track.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: aTrack, at: cursor)
            cursor = cursor + duration
        }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioCaptureError.exportFailed
        }
        exporter.outputURL = outURL
        exporter.outputFileType = .m4a

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    cont.resume(returning: ())
                case .failed:
                    cont.resume(throwing: exporter.error ?? AudioCaptureError.exportFailed)
                case .cancelled:
                    cont.resume(throwing: AudioCaptureError.exportFailed)
                default:
                    cont.resume(throwing: AudioCaptureError.exportFailed)
                }
            }
        }
    }
}
