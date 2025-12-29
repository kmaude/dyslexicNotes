import SwiftUI
import GRDB

struct NoteDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let noteID: String

    @StateObject private var vm = NoteDetailViewModel()
    @StateObject private var sync = PlaybackSyncService()
    @StateObject private var replay = ReplayLoopController()

    @State private var selectedTab: Int = 1
    @State private var showRename: Bool = false
    @State private var showCleanCopy: Bool = false
    @State private var showExportDialog: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Picker("", selection: $selectedTab) {
                Text("Organized Notes").tag(0)
                Text("Transcript").tag(1)
                Text("Markers").tag(2)
                Text("Versions").tag(3)
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedTab {
                case 0:
                    OrganizedNotesView(markdownURL: vm.bundle?.notesMD)
                case 1:
                    TranscriptView(sentences: vm.sentences, highlightedIndex: sync.highlightedSentenceIndex) { t in
                        env.playback.seek(to: t)
                    }
                case 2:
                    MarkersView(markers: vm.markers) { t in
                        env.playback.seek(to: t)
                    }
                default:
                    VersionsView(noteID: noteID)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .navigationTitle("Note")
        .task {
            await vm.load(env: env, noteID: noteID)
            sync.setSentences(vm.sentences)
            if let audio = vm.bundle?.audioM4A {
                env.playback.load(url: audio)
                env.playback.clarityMode = env.settingsStore.model.playbackClarityMode
            }
        }
        .sheet(isPresented: $showRename) {
            RenameNoteSheet(noteID: noteID, isPresented: $showRename)
                .environmentObject(env)
        }
        .sheet(isPresented: $showCleanCopy) {
            CreateCleanCopySheet(noteID: noteID, sourceText: loadBestExportText(), isPresented: $showCleanCopy)
                .environmentObject(env)
        }
        .confirmationDialog("Export", isPresented: $showExportDialog, titleVisibility: .visible) {
            Button("Export RTF") { Task { await env.exportService.exportText(loadBestExportText(), suggestedName: exportBaseName(), format: .rtf) } }
            Button("Export DOCX") { Task { await env.exportService.exportText(loadBestExportText(), suggestedName: exportBaseName(), format: .docx) } }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: env.playback.currentTimeSec) { _, newValue in
            sync.update(currentTimeSec: newValue)
            if let idx = sync.highlightedSentenceIndex, idx < vm.sentences.count {
                let s = vm.sentences[idx]
                replay.setActiveSentenceBounds(start: s.startSec, end: s.endSec)
            }
        }
        .onChange(of: env.playback.isPlaying) { _, isPlaying in
            guard isPlaying else { return }
            // Simple auto-loop: when enabled, a periodic tick in the transcript view triggers re-seek.
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Title", text: $vm.editableTitle)
                        .font(.title2.weight(.semibold))
                        .textFieldStyle(.plain)
                        .onSubmit { Task { await vm.saveTitle(env: env) } }
                        .contextMenu {
                            Button("Rename…") { showRename = true }
                        }

                    Text("\(vm.klass?.name ?? "") • \(vm.note?.createdAtLocal ?? "")")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                PlaybackControlsView(
                    isPlaying: env.playback.isPlaying,
                    rate: Binding(
                        get: { Double(env.playback.baseRate) },
                        set: { env.playback.baseRate = Float($0) }
                    ),
                    clarityMode: Binding(
                        get: { env.settingsStore.model.playbackClarityMode },
                        set: { env.settingsStore.update { $0.playbackClarityMode = $1 }; env.playback.clarityMode = $1 }
                    ),
                    onPlayPause: {
                        if env.playback.isPlaying { env.playback.pause() } else { env.playback.play() }
                    },
                    onReplaySentence: {
                        if let b = replay.activeSentenceBounds {
                            env.playback.seek(to: b.start)
                            env.playback.play()
                        }
                    },
                    autoLoopEnabled: Binding(
                        get: { replay.mode == .autoLoopCurrentSentence },
                        set: { replay.mode = $0 ? .autoLoopCurrentSentence : .off }
                    ),
                    onReprocess: {
                        Task { await runOrganizer() }
                    },
                    onExport: { showExportDialog = true },
                    onCreateCleanCopy: { showCleanCopy = true }
                )
            }

            if replay.mode == .autoLoopCurrentSentence, let b = replay.activeSentenceBounds {
                Text("Auto-looping current sentence (\(TimeFormatting.mmss(b.start))–\(TimeFormatting.mmss(b.end)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onChange(of: env.playback.currentTimeSec) { _, t in
                        guard replay.mode == .autoLoopCurrentSentence else { return }
                        if t >= b.end - 0.03 {
                            env.playback.seek(to: b.start)
                            env.playback.play()
                        }
                    }
            }
        }
    }

    private func runOrganizer() async {
        guard let note = vm.note, let klass = vm.klass else { return }
        guard let db = env.dbManager.dbWriter else { return }
        guard let bundle = vm.bundle else { return }

        let mutedModels: [MutedRangeModel] = (try? await db.read { db in
            try MutedRangeModel.filter(Column("note_id") == note.noteID).fetchAll(db)
        }) ?? []
        let mutedRanges = mutedModels.map { TranscriptJSON.MutedRange(startSec: $0.startSec, endSec: $0.endSec, label: "MUTED") }

        let organizer = OptionAOrganizer()
        let date = String(note.createdAtLocal.prefix(10))
        let md = organizer.generate(
            className: klass.name,
            dateYYYYMMDD: date,
            sentences: vm.sentences,
            mutedRanges: mutedRanges,
            markers: vm.markers
        )

        do {
            try MarkdownWriter.write(md, to: bundle.notesMD)

            if let data = try? Data(contentsOf: bundle.metaJSON),
               var meta = try? JSONDecoder().decode(MetaJSON.self, from: data) {
                meta.organizer.status = "OK"
                meta.organizer.lastRunAtLocal = DateFormatters.isoLocalDateTime.string(from: Date())
                try JSONWriters.writeMeta(meta, to: bundle.metaJSON)
            }
        } catch {
            // M5: surface via toasts later.
        }
    }

    private func loadBestExportText() -> String {
        // Prefer organized notes markdown if present, otherwise join transcript.
        if let url = vm.bundle?.notesMD, let md = try? String(contentsOf: url), !md.isEmpty {
            return md
        }
        return vm.sentences.map { $0.text }.joined(separator: "\n")
    }

    private func exportBaseName() -> String {
        let className = vm.klass?.name ?? "Notes"
        let date = vm.note.map { String($0.createdAtLocal.prefix(10)) } ?? DateFormatters.isoLocalDate.string(from: Date())
        return "\(className) — \(date)"
    }
}
