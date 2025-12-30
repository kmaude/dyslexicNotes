import SwiftUI

struct OrganizedNotesView: View {
    @EnvironmentObject private var env: AppEnvironment
    let markdownURL: URL?

    @State private var markdown: String = ""
    @State private var simplified: String? = nil

    var body: some View {
        ReadingRulerOverlay(
            enabled: env.settingsStore.model.readingRulerEnabled,
            lines: env.settingsStore.model.readingRulerLines,
            opacity: env.settingsStore.model.readingRulerOpacity,
            lineHeight: 22
        ) {
            Group {
                if markdown.isEmpty {
                    ContentUnavailableView(
                        "Organized notes not generated yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Press Reprocess to generate notes.md (Option A).")
                    )
                    .padding(.top, 24)
                } else {
                    ScrollView {
                        Text(.init(markdown))
                            .font(NotesTypography.readingFont(name: env.settingsStore.model.fontName, size: 15))
                            .lineSpacing(spacingForPreset(env.settingsStore.model.spacingPreset))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .contextMenu {
                                Button("Speak") {
                                    env.tapToSpeak.speak(text: markdown, baseRate: Double(env.playback.baseRate))
                                }
                                Button(simplified == nil ? "Explain this simply" : "Hide simplified") {
                                    if simplified != nil {
                                        simplified = nil
                                    } else {
                                        simplified = env.explainSimply.simplify(markdown)
                                    }
                                }
                            }
                    }
                }
            }
            .padding(12)
            .background(.quaternary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                if let simplified {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Explain simply")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(simplified)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(10)
                }
            }
        }
        .task { load() }
        .onChange(of: markdownURL?.path ?? "") { _, _ in load() }
    }

    private func load() {
        guard let markdownURL else { markdown = ""; return }
        markdown = (try? String(contentsOf: markdownURL)) ?? ""
    }

    private func spacingForPreset(_ preset: DyslexiaSpacingPreset) -> CGFloat {
        switch preset {
        case .normal: return 2
        case .relaxed: return 5
        case .extra: return 8
        }
    }
}
