import SwiftUI

struct AudioSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Form {
            Section("Audio") {
                Picker("Input device", selection: Binding(
                    get: { env.settingsStore.model.preferredInputDeviceID ?? "" },
                    set: { newID in
                        let device = env.audioInputs.availableInputs.first { $0.uniqueID == newID }
                        env.settingsStore.update {
                            $0.preferredInputDeviceID = newID.isEmpty ? nil : newID
                            $0.preferredInputDeviceName = device?.name
                        }
                    }
                )) {
                    Text("Default").tag("")
                    ForEach(env.audioInputs.availableInputs) { d in
                        Text(d.name).tag(d.uniqueID)
                    }
                }

                Text("Device switching is applied on next recording.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task { env.audioInputs.refresh() }
    }
}
