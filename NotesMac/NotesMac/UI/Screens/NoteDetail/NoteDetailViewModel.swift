import Foundation

@MainActor
final class NoteDetailViewModel: ObservableObject {
    @Published private(set) var note: NoteModel?
    @Published private(set) var klass: ClassModel?
    @Published private(set) var sentences: [TranscriptSentenceRow] = []
    @Published private(set) var markers: [MarkerRow] = []

    @Published var editableTitle: String = ""

    @Published private(set) var bundle: NoteBundlePaths?

    func load(env: AppEnvironment, noteID: String) async {
        guard let db = env.dbManager.dbWriter else { return }
        do {
            let notesDAO = NotesDAO(db: db)
            note = try await notesDAO.fetchNote(noteID: noteID)
            if let note {
                klass = try await notesDAO.fetchClass(classID: note.classID)
                editableTitle = note.title
            }

            sentences = (try? await TranscriptDAO(db: db).fetchSentences(noteID: noteID)) ?? []
            markers = (try? await MarkersDAO(db: db).fetchMarkers(noteID: noteID)) ?? []

            bundle = env.fileStore.locateBundle(noteID: noteID)
        } catch { }
    }

    func saveTitle(env: AppEnvironment) async {
        guard let note else { return }
        guard let db = env.dbManager.dbWriter else { return }
        let trimmed = editableTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != note.title else { return }
        try? await NotesDAO(db: db).updateTitle(noteID: note.noteID, title: trimmed)
        self.note = try? await NotesDAO(db: db).fetchNote(noteID: note.noteID)
    }
}
