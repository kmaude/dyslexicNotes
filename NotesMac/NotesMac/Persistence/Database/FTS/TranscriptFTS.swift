import Foundation
import GRDB

enum TranscriptFTS {
    static func upsert(db: Database, noteID: String, content: String) throws {
        try db.execute(sql: "DELETE FROM transcript_fts WHERE note_id = ?", arguments: [noteID])
        try db.execute(sql: "INSERT INTO transcript_fts(note_id, content) VALUES (?, ?)", arguments: [noteID, content])
    }
}
