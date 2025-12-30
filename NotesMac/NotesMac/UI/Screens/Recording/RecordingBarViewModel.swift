import Foundation
import GRDB

@MainActor
final class RecordingBarViewModel: ObservableObject {
    enum State { case idle, recording, paused, stopped }

    @Published var state: State = .idle
    @Published var isExpanded: Bool = false
    @Published private(set) var isMuted: Bool = false
    @Published private(set) var elapsed: TimeInterval = 0

    @Published var classOptions: [ClassModel] = []
    @Published var selectedClassID: String?

    @Published var starCount: Int = 0
    @Published var questionCount: Int = 0

    private(set) var activeNoteID: String?
    private(set) var activeBundle: NoteBundlePaths?
    private var elapsedTimer: Timer?

    func loadClasses(env: AppEnvironment) async {
        guard let db = env.dbManager.dbWriter else { return }
        do {
            classOptions = try await ClassesDAO(db: db).fetchAll()
            if selectedClassID == nil {
                selectedClassID = env.settingsStore.model.lastClassID ?? classOptions.first?.classID
            }
        } catch {
            classOptions = []
        }
    }

    func start(env: AppEnvironment) {
        Task { await startAsync(env: env) }
    }

    func togglePause(env: AppEnvironment) {
        Task { await togglePauseAsync(env: env) }
    }

    func stop(env: AppEnvironment) {
        Task { await stopAsync(env: env) }
    }

    func toggleMute(env: AppEnvironment) {
        guard state == .recording || state == .paused else { return }
        env.audioCapture.toggleMute()
        isMuted = env.audioCapture.isMuted
    }

    func addStar(env: AppEnvironment) { Task { await addMarker(env: env, type: .star) } }
    func addQuestion(env: AppEnvironment) { Task { await addMarker(env: env, type: .question) } }

    // MARK: - Internals

    private func startAsync(env: AppEnvironment) async {
        guard state == .idle || state == .stopped else { return }
        guard let classID = selectedClassID else { return }
        guard let db = env.dbManager.dbWriter else { return }

        do {
            let notesDAO = NotesDAO(db: db)
            let klass = try await notesDAO.fetchClass(classID: classID)
            let className = klass?.name ?? "Misc Notes"
            let now = Date()
            let createdAtLocal = DateFormatters.isoLocalDateTime.string(from: now)

            let noteID = UUID().uuidString
            let title = "\(className) — \(DateFormatters.isoLocalDate.string(from: now))"

            let bundle = try env.fileStore.createBundleFolder(className: className, createdAt: now, title: title)
            activeBundle = bundle
            activeNoteID = noteID

            env.settingsStore.update { $0.lastClassID = classID }

            let note = NoteModel(
                noteID: noteID,
                classID: classID,
                title: title,
                createdAtLocal: createdAtLocal,
                durationSeconds: 0,
                chunkSeconds: env.settingsStore.model.chunkSeconds,
                autosplitMinutes: Constants.autosplitMinutes,
                inputDevice: env.settingsStore.model.preferredInputDeviceName ?? "Default",
                noiseMode: .normal,
                schoolModeEnabledAtCapture: env.settingsStore.model.schoolModeEnabled,
                networkCallsBlocked: env.settingsStore.model.schoolModeEnabled,
                hasCleanCopy: false
            )
            try await notesDAO.createNote(note: note)

            try env.audioCapture.start(noteID: noteID)
            env.warnings.startMonitoring()

            // Prefer Small if installed, else Medium. If none installed, use fallback engine.
            #if canImport(WhisperSwift)
            let installed = env.models.status.installed
            if installed.contains(.small) {
                if let engine = try? WhisperCPPTranscriptionEngine(modelURL: env.models.localURL(for: .small)) {
                    env.transcription.configureEngine(engine)
                }
            } else if installed.contains(.medium) {
                if let engine = try? WhisperCPPTranscriptionEngine(modelURL: env.models.localURL(for: .medium)) {
                    env.transcription.configureEngine(engine)
                }
            }
            #endif

            env.transcription.start(
                noteID: noteID,
                chunkSeconds: note.chunkSeconds,
                audioBuffers: env.audioCapture.buffers(),
                isMuted: { env.audioCapture.isMuted },
                db: db
            )

            isMuted = env.audioCapture.isMuted
            elapsed = env.audioCapture.elapsedSec
            state = .recording
            starCount = 0
            questionCount = 0

            startElapsedTimer(env: env)
        } catch {
            state = .stopped
        }
    }

    private func togglePauseAsync(env: AppEnvironment) async {
        guard let noteID = activeNoteID else { return }
        do {
            switch state {
            case .recording:
                try env.audioCapture.pause()
                state = .paused
            case .paused:
                try env.audioCapture.resume(noteID: noteID)
                state = .recording
            default:
                break
            }
        } catch { }
    }

    private func stopAsync(env: AppEnvironment) async {
        guard let noteID = activeNoteID, let bundle = activeBundle else { return }
        guard let db = env.dbManager.dbWriter else { return }

        do {
            let export = try await env.audioCapture.stopAndExport(to: bundle.audioM4A)
            env.warnings.stopMonitoring()
            env.transcription.stop()

            let durationSeconds = Int(env.audioCapture.elapsedSec.rounded(.down))

            // segments
            let segments = makeSegments(durationSeconds: durationSeconds, autosplitMinutes: Constants.autosplitMinutes)
            let muted = export.muted.map { TranscriptJSON.MutedRange(startSec: $0.startSec, endSec: $0.endSec, label: "MUTED") }

            let notesDAO = NotesDAO(db: db)
            try await notesDAO.updateDuration(noteID: noteID, durationSeconds: durationSeconds)
            try await notesDAO.replaceSegments(noteID: noteID, segments: segments)
            try await notesDAO.replaceMutedRanges(noteID: noteID, ranges: muted)

            // transcript.json (may be empty in M2)
            let sentenceRows = try await TranscriptDAO(db: db).fetchSentences(noteID: noteID)
            let sentences = sentenceRows.map { TranscriptJSON.Sentence(startSec: $0.startSec, endSec: $0.endSec, text: $0.text, language: $0.language) }
            let transcript = TranscriptJSON(noteID: noteID, sentences: sentences, mutedRanges: muted, segments: segments)
            try JSONWriters.writeTranscript(transcript, to: bundle.transcriptJSON)
            try JSONWriters.writeTranscriptText(transcript, to: bundle.transcriptTXT)

            // markers.json
            let markerRows = try await MarkersDAO(db: db).fetchMarkers(noteID: noteID)
            let markersJSON = MarkersJSON(
                noteID: noteID,
                markerContext: .init(preSec: Int(Constants.markerPreSeconds), postSec: Int(Constants.markerPostSeconds)),
                markers: markerRows.map {
                    MarkersJSON.Marker(
                        id: $0.markerID,
                        type: $0.type,
                        atSec: $0.atSec,
                        createdAtLocal: $0.createdAtLocal,
                        context: .init(startSec: $0.contextStartSec, endSec: $0.contextEndSec, text: $0.contextText)
                    )
                }
            )
            try JSONWriters.writeMarkers(markersJSON, to: bundle.markersJSON)

            // meta.json
            if let note = try await notesDAO.fetchNote(noteID: noteID),
               let klass = try await notesDAO.fetchClass(classID: note.classID) {
                let meta = MetaJSON(
                    schemaVersion: 1,
                    noteID: noteID,
                    createdAtLocal: note.createdAtLocal,
                    class: .init(
                        name: klass.name,
                        classID: klass.classID,
                        colorHex: klass.colorHex,
                        languageMode: klass.languageMode.rawValue,
                        specialLanguage: klass.specialLanguage
                    ),
                    storage: .init(
                        basePath: Paths.notesBundlesBase.path,
                        classFolder: Paths.classFolderURL(className: klass.name).path,
                        dateFolder: bundle.folder.path
                    ),
                    audio: .init(
                        file: bundle.audioM4A.lastPathComponent,
                        sampleRate: export.sampleRate,
                        channels: export.channels,
                        inputDevice: note.inputDevice,
                        noiseMode: note.noiseMode.rawValue
                    ),
                    capture: .init(
                        chunkSeconds: note.chunkSeconds,
                        autosplitMinutes: note.autosplitMinutes,
                        durationSeconds: durationSeconds,
                        segments: segments.map { .init(segmentIndex: $0.segmentIndex, startSec: $0.startSec, endSec: $0.endSec) },
                        mutedRanges: muted.map { .init(startSec: $0.startSec, endSec: $0.endSec) }
                    ),
                    markers: .init(countStar: starCount, countQuestion: questionCount, file: bundle.markersJSON.lastPathComponent),
                    transcript: .init(
                        engine: "local-whisper",
                        status: sentences.isEmpty ? "PENDING" : "OK",
                        fileJSON: bundle.transcriptJSON.lastPathComponent,
                        fileTXT: bundle.transcriptTXT.lastPathComponent
                    ),
                    organizer: .init(mode: "OPTION_A_RULES", status: "PENDING", fileMD: bundle.notesMD.lastPathComponent, lastRunAtLocal: nil),
                    versions: .init(cleanCopies: []),
                    privacy: .init(
                        schoolModeEnabledAtCapture: note.schoolModeEnabledAtCapture,
                        networkCallsBlocked: note.networkCallsBlocked
                    )
                )
                try JSONWriters.writeMeta(meta, to: bundle.metaJSON)

                // M5: run organizer Option A right away (offline, deterministic)
                let mutedModels: [MutedRangeModel] = (try? await db.read { db in
                    try MutedRangeModel.filter(Column("note_id") == noteID).fetchAll(db)
                }) ?? []
                let mutedRanges = mutedModels.map { TranscriptJSON.MutedRange(startSec: $0.startSec, endSec: $0.endSec, label: "MUTED") }

                let sentenceRows = (try? await TranscriptDAO(db: db).fetchSentences(noteID: noteID)) ?? []
                let markerRows = (try? await MarkersDAO(db: db).fetchMarkers(noteID: noteID)) ?? []
                let md = OptionAOrganizer().generate(
                    className: klass.name,
                    dateYYYYMMDD: String(note.createdAtLocal.prefix(10)),
                    sentences: sentenceRows,
                    mutedRanges: mutedRanges,
                    markers: markerRows
                )
                try? MarkdownWriter.write(md, to: bundle.notesMD)

                if let data = try? Data(contentsOf: bundle.metaJSON),
                   var updated = try? JSONDecoder().decode(MetaJSON.self, from: data) {
                    updated.organizer.status = "OK"
                    updated.organizer.lastRunAtLocal = DateFormatters.isoLocalDateTime.string(from: Date())
                    try? JSONWriters.writeMeta(updated, to: bundle.metaJSON)
                }
            }

            // Full-file refine pass (M3) then rewrite transcript + FTS
            Task {
                await env.transcription.finalizeFullPass(noteID: noteID, audioURL: bundle.audioM4A, db: db)
            }

            state = .stopped
            elapsedTimer?.invalidate()
            elapsedTimer = nil
        } catch {
            state = .stopped
        }
    }

    private func addMarker(env: AppEnvironment, type: MarkerType) async {
        guard let noteID = activeNoteID else { return }
        guard let db = env.dbManager.dbWriter else { return }

        let at = env.audioCapture.elapsedSec
        let pre = Constants.markerPreSeconds
        let post = Constants.markerPostSeconds
        let contextStart = max(0, at - pre)
        let contextEnd = max(contextStart, at + post)
        let createdAtLocal = DateFormatters.isoLocalDateTime.string(from: Date())

        let contextText: String = (try? await db.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT text FROM transcript_sentences
                WHERE note_id = ? AND end_sec >= ? AND start_sec <= ?
                ORDER BY start_sec ASC
                """,
                arguments: [noteID, contextStart, contextEnd]
            )
            return rows.compactMap { $0["text"] as String? }.joined(separator: " ")
        }) ?? ""

        do {
            try await MarkersDAO(db: db).insertMarker(
                noteID: noteID,
                type: type,
                atSec: at,
                createdAtLocal: createdAtLocal,
                contextStartSec: contextStart,
                contextEndSec: contextEnd,
                contextText: contextText
            )
            switch type {
            case .star: starCount += 1
            case .question: questionCount += 1
            }
        } catch { }
    }

    private func makeSegments(durationSeconds: Int, autosplitMinutes: Int) -> [TranscriptJSON.Segment] {
        let split = autosplitMinutes * 60
        guard durationSeconds > split else {
            return [.init(segmentIndex: 0, startSec: 0, endSec: Double(durationSeconds))]
        }

        var segments: [TranscriptJSON.Segment] = []
        var idx = 0
        var start = 0
        while start < durationSeconds {
            let end = min(durationSeconds, start + split)
            segments.append(.init(segmentIndex: idx, startSec: Double(start), endSec: Double(end)))
            idx += 1
            start = end
        }
        return segments
    }

    private func startElapsedTimer(env: AppEnvironment) {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsed = env.audioCapture.elapsedSec
            self.isMuted = env.audioCapture.isMuted
        }
    }
}
