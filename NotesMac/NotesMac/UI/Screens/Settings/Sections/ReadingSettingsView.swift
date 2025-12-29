import SwiftUI

struct ReadingSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Form {
            Section("Reading") {
                TextField("Font name (optional)", text: Binding(
                    get: { env.settingsStore.model.fontName ?? "" },
                    set: { env.settingsStore.update { $0.fontName = $1.isEmpty ? nil : $1 } }
                ))
                .textFieldStyle(.roundedBorder)

                Picker("Spacing", selection: Binding(
                    get: { env.settingsStore.model.spacingPreset },
                    set: { env.settingsStore.update { $0.spacingPreset = $1 } }
                )) {
                    Text("Normal").tag(DyslexiaSpacingPreset.normal)
                    Text("Relaxed").tag(DyslexiaSpacingPreset.relaxed)
                    Text("Extra").tag(DyslexiaSpacingPreset.extra)
                }

                Toggle("Reading ruler", isOn: Binding(
                    get: { env.settingsStore.model.readingRulerEnabled },
                    set: { env.settingsStore.update { $0.readingRulerEnabled = $1 } }
                ))

                Stepper(value: Binding(
                    get: { env.settingsStore.model.readingRulerLines },
                    set: { env.settingsStore.update { $0.readingRulerLines = $1 } }
                ), in: 1...3) {
                    Text("Ruler height: \(env.settingsStore.model.readingRulerLines) line(s)")
                }

                HStack {
                    Text("Ruler opacity")
                    Slider(value: Binding(
                        get: { env.settingsStore.model.readingRulerOpacity },
                        set: { env.settingsStore.update { $0.readingRulerOpacity = $1 } }
                    ), in: 0.10...0.50, step: 0.05)
                    Text(String(format: "%.2f", env.settingsStore.model.readingRulerOpacity))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Picker("Word chunking", selection: Binding(
                    get: { env.settingsStore.model.wordChunkMode },
                    set: { env.settingsStore.update { $0.wordChunkMode = $1 } }
                )) {
                    Text("Off").tag(WordChunkMode.off)
                    Text("Soft chunking").tag(WordChunkMode.softChunking)
                    Text("Syllable hinting").tag(WordChunkMode.syllableHinting)
                }

                ColorPicker("Highlight color", selection: Binding(
                    get: { Color(hex: env.settingsStore.model.highlightHex) ?? .blue },
                    set: { c in
                        env.settingsStore.update { $0.highlightHex = c.toHexRGB() ?? Constants.defaultHighlightHex }
                    }
                ), supportsOpacity: false)
            }
        }
    }
}
