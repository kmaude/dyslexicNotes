import SwiftUI

struct ModelsSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Models").font(.headline)
            if env.settingsStore.model.schoolModeEnabled {
                Text("School Mode is ON. Model downloads are blocked.").foregroundStyle(.secondary)
            } else {
                Text("Download Small/Medium in M3.").foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
