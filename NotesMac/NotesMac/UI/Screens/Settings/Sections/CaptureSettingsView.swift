import SwiftUI

struct CaptureSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Form {
            Section("Capture") {
                Stepper(value: Binding(
                    get: { env.settingsStore.model.chunkSeconds },
                    set: { env.settingsStore.update { $0.chunkSeconds = $1 } }
                ), in: 5...30, step: 1) {
                    Text("Chunk seconds: \(env.settingsStore.model.chunkSeconds)")
                }

                LabeledContent("Auto-split minutes") { Text("\(Constants.autosplitMinutes) (locked)") }
                LabeledContent("Marker context") { Text("pre 10s / post 15s") }
            }
        }
    }
}
