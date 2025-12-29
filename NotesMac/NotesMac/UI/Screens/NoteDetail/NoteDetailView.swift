import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let noteID: String

    @StateObject private var vm = NoteDetailViewModel()
    @StateObject private var sync = PlaybackSyncService()
    @StateObject private var replay = ReplayLoopController()

    @State private var selectedTab: Int = 1

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
                    OrganizedNotesView()
                case 1:
                    TranscriptView(sentences: vm.sentences, highlightedIndex: sync.highlightedSentenceIndex) { t in
                        env.playback.seek(to: t)
                    }
                case 2:
                    MarkersView(markers: vm.markers) { t in
                        env.playback.seek(to: t)
                    }
                default:
                    VersionsView()
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
            }
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

                    Text("\(vm.klass?.name ?? "") • \(vm.note?.createdAtLocal ?? "")")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                PlaybackControlsView(
                    isPlaying: env.playback.isPlaying,
                    rate: Binding(
                        get: { Double(env.playback.rate) },
                        set: { env.playback.rate = Float($0) }
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
                    onReprocess: { /* M3 */ },
                    onExport: { /* M7 */ },
                    onCreateCleanCopy: { /* M7 */ }
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
}
