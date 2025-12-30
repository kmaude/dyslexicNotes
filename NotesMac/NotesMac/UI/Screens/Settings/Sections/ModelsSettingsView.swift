import SwiftUI

struct ModelsSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Models").font(.headline)
            if env.settingsStore.model.schoolModeEnabled {
                Text("School Mode is ON. Model downloads are blocked.")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                modelRow(.small)
                modelRow(.medium)
            }

            if let err = env.models.status.lastError {
                Text(err).foregroundStyle(.red).font(.caption)
            }

            Spacer()
        }
        .task { env.models.refreshInstalled() }
    }

    @ViewBuilder
    private func modelRow(_ model: WhisperModelManager.Model) -> some View {
        let installed = env.models.status.installed.contains(model)
        VStack(alignment: .leading, spacing: 6) {
            Text(model.rawValue.capitalized).font(.subheadline.weight(.semibold))
            Text(installed ? "Installed" : "Not installed").font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button(installed ? "Re-download" : "Download") {
                    Task { await env.models.download(model: model) }
                }
                .disabled(env.settingsStore.model.schoolModeEnabled)

                if installed {
                    Button("Delete") { env.models.delete(model: model) }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(10)
        .background(.quaternary.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
