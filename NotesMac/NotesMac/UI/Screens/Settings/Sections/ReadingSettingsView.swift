import SwiftUI

struct ReadingSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Form {
            Section("Reading") {
                Picker("Spacing", selection: Binding(
                    get: { env.settingsStore.model.spacingPreset },
                    set: { env.settingsStore.update { $0.spacingPreset = $1 } }
                )) {
                    Text("Normal").tag(DyslexiaSpacingPreset.normal)
                    Text("Relaxed").tag(DyslexiaSpacingPreset.relaxed)
                    Text("Extra").tag(DyslexiaSpacingPreset.extra)
                }
            }
        }
    }
}
