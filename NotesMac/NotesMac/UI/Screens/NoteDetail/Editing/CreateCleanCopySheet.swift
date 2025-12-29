import SwiftUI

struct CreateCleanCopySheet: View {
    @EnvironmentObject private var env: AppEnvironment

    let noteID: String
    let sourceText: String
    @Binding var isPresented: Bool

    @State private var status: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Clean Copy").font(.headline)
            Text("Generates RTF + DOCX in the note bundle.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !status.isEmpty {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Create") { Task { await create() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 440)
    }

    private func create() async {
        guard let db = env.dbManager.dbWriter else { return }
        guard let bundle = env.fileStore.locateBundle(noteID: noteID) else { return }

        status = "Creating…"
        do {
            let dao = VersionsDAO(db: db)
            let idx = try await dao.nextIndex(noteID: noteID)
            let createdAtLocal = DateFormatters.isoLocalDateTime.string(from: Date())

            let rtfURL = bundle.cleanCopyRTF(index: idx)
            let docxURL = bundle.cleanCopyDOCX(index: idx)

            try RTFExporter().export(text: sourceText, to: rtfURL)
            try DOCXExporter().export(text: sourceText, to: docxURL)

            try await dao.insert(
                noteID: noteID,
                idx: idx,
                createdAtLocal: createdAtLocal,
                rtfPath: rtfURL.path,
                docxPath: docxURL.path
            )

            // Update meta.json versions list if present.
            if let data = try? Data(contentsOf: bundle.metaJSON),
               var meta = try? JSONDecoder().decode(MetaJSON.self, from: data) {
                var copies = meta.versions.cleanCopies
                copies.append(.init(idx: idx, createdAtLocal: createdAtLocal, rtfPath: rtfURL.lastPathComponent, docxPath: docxURL.lastPathComponent))
                meta.versions.cleanCopies = copies
                try? JSONWriters.writeMeta(meta, to: bundle.metaJSON)
            }

            status = "Done."
            isPresented = false
        } catch {
            status = "Failed: \(error)"
        }
    }
}
