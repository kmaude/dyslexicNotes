import SwiftUI

struct RenameNoteSheet: View {
    @EnvironmentObject private var env: AppEnvironment

    let noteID: String
    @Binding var isPresented: Bool

    @State private var title: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rename note").font(.headline)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Rename") { Task { await rename() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420)
        .task { await load() }
    }

    private func load() async {
        guard let db = env.dbManager.dbWriter else { return }
        if let note = try? await NotesDAO(db: db).fetchNote(noteID: noteID) {
            title = note.title
        }
    }

    private func rename() async {
        guard let db = env.dbManager.dbWriter else { return }
        let newTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newTitle.isEmpty else { return }

        // Update bundle filenames
        if let bundle = env.fileStore.locateBundle(noteID: noteID),
           let updated = try? RenameManager.renameBundleFiles(bundle: bundle, newTitle: newTitle) {
            // Update meta.json filenames to stay consistent
            if let data = try? Data(contentsOf: updated.metaJSON),
               var meta = try? JSONDecoder().decode(MetaJSON.self, from: data) {
                meta.audio.file = updated.audioM4A.lastPathComponent
                meta.transcript.fileJSON = updated.transcriptJSON.lastPathComponent
                meta.transcript.fileTXT = updated.transcriptTXT.lastPathComponent
                meta.markers.file = updated.markersJSON.lastPathComponent
                meta.organizer.fileMD = updated.notesMD.lastPathComponent
                meta.versions.cleanCopies = meta.versions.cleanCopies.map { c in
                    .init(
                        idx: c.idx,
                        createdAtLocal: c.createdAtLocal,
                        rtfPath: updated.cleanCopyRTF(index: c.idx).lastPathComponent,
                        docxPath: updated.cleanCopyDOCX(index: c.idx).lastPathComponent
                    )
                }
                try? JSONWriters.writeMeta(meta, to: updated.metaJSON)
            }
        }

        try? await NotesDAO(db: db).updateTitle(noteID: noteID, title: newTitle)
        isPresented = false
    }
}
