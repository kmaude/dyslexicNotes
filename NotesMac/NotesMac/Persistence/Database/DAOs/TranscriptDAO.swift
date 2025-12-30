import Foundation
import GRDB

struct TranscriptSentenceRow: Identifiable, Hashable {
    var id: String { "\(noteID):\(startSec)" }
    let noteID: String
    let startSec: Double
    let endSec: Double
    let text: String
    let language: String?
}

struct TranscriptDAO {
    let db: DatabaseWriter

    func fetchSentences(noteID: String) async throws -> [TranscriptSentenceRow] {
        try await db.read { db in
            try TranscriptSentenceRow.fetchAll(
                db,
                sql: """
                SELECT note_id AS noteID, start_sec AS startSec, end_sec AS endSec, text AS text, language AS language
                FROM transcript_sentences
                WHERE note_id = ?
                ORDER BY start_sec ASC
                """,
                arguments: [noteID]
            )
        }
    }

    func replaceSentences(noteID: String, sentences: [TranscriptJSON.Sentence]) async throws {
        try await db.write { db in
            try db.execute(sql: "DELETE FROM transcript_sentences WHERE note_id = ?", arguments: [noteID])
            for s in sentences {
                try TranscriptSentenceModel(noteID: noteID, startSec: s.startSec, endSec: s.endSec, text: s.text, language: s.language).insert(db)
            }
        }
    }
}
