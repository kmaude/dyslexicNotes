import SwiftUI

struct TranscriptView: View {
    @EnvironmentObject private var env: AppEnvironment

    let sentences: [TranscriptSentenceRow]
    let highlightedIndex: Int?
    let onJumpTo: (Double) -> Void

    @State private var simplified: [String: String] = [:]

    var body: some View {
        ReadingRulerOverlay(
            enabled: env.settingsStore.model.readingRulerEnabled,
            lines: env.settingsStore.model.readingRulerLines,
            opacity: env.settingsStore.model.readingRulerOpacity,
            lineHeight: 22
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if sentences.isEmpty {
                        ContentUnavailableView("No transcript yet", systemImage: "text.alignleft", description: Text("Transcription starts in M3."))
                            .padding(.top, 24)
                    } else {
                        ForEach(Array(sentences.enumerated()), id: \.offset) { idx, s in
                            VStack(alignment: .leading, spacing: 8) {
                                sentenceRow(idx: idx, s: s)
                                    .onTapGesture { onJumpTo(s.startSec) }

                                if let simple = simplified[s.id] {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Explain simply")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Text(simple)
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(10)
                                    .background(.quaternary.opacity(0.25))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .padding(12)
            .background(.quaternary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private func sentenceRow(idx: Int, s: TranscriptSentenceRow) -> some View {
        let isCurrent = (highlightedIndex == idx)
        let bg = (Color(hex: env.settingsStore.model.highlightHex) ?? Color.blue.opacity(0.25))
        let attributed = WordChunkRenderer.attributed(s.text, mode: env.settingsStore.model.wordChunkMode)

        HStack(alignment: .top, spacing: 10) {
            Text(TimeFormatting.mmss(s.startSec))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)

            Text(attributed)
                .font(NotesTypography.readingFont(name: env.settingsStore.model.fontName, size: 15))
                .lineSpacing(spacingForPreset(env.settingsStore.model.spacingPreset))
                .padding(.vertical, 2)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isCurrent ? bg : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contextMenu {
            Button("Speak sentence") {
                env.tapToSpeak.speak(text: s.text, baseRate: Double(env.playback.baseRate))
            }
            Button(simplified[s.id] == nil ? "Explain this simply" : "Hide simplified") {
                if simplified[s.id] != nil {
                    simplified[s.id] = nil
                } else {
                    simplified[s.id] = env.explainSimply.simplify(s.text)
                }
            }
        }
    }

    private func spacingForPreset(_ preset: DyslexiaSpacingPreset) -> CGFloat {
        switch preset {
        case .normal: return 2
        case .relaxed: return 5
        case .extra: return 8
        }
    }
}
