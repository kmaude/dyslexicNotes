import SwiftUI
import AppKit

struct VersionsView: View {
    @EnvironmentObject private var env: AppEnvironment
    let noteID: String

    @State private var versions: [CleanCopyRow] = []

    var body: some View {
        Group {
            if versions.isEmpty {
                ContentUnavailableView("No versions yet", systemImage: "doc.on.doc", description: Text("Create a Clean Copy to save RTF/DOCX versions."))
                    .padding(.top, 24)
            } else {
                List(versions) { v in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Clean Copy \(v.idx)")
                            .font(.headline)
                        Text(v.createdAtLocal)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button("Open RTF") { NSWorkspace.shared.open(URL(fileURLWithPath: v.rtfPath)) }
                            Button("Open DOCX") { NSWorkspace.shared.open(URL(fileURLWithPath: v.docxPath)) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard let db = env.dbManager.dbWriter else { return }
        versions = (try? await VersionsDAO(db: db).fetch(noteID: noteID)) ?? []
    }
}
