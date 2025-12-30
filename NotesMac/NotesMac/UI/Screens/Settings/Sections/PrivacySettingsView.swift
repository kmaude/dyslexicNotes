import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("School Mode (no networking)", isOn: Binding(
                    get: { env.settingsStore.model.schoolModeEnabled },
                    set: { env.settingsStore.update { $0.schoolModeEnabled = $1 } }
                ))
            }
        }
    }
}
