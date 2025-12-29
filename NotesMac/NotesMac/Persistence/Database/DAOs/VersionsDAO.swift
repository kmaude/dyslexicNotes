import Foundation
import GRDB

struct CleanCopyRow: Identifiable, Hashable {
    var id: String { "\(noteID):\(idx)" }
    let noteID: String
    let idx: Int
    let createdAtLocal: String
    let rtfPath: String
    let docxPath: String
}

struct VersionsDAO {
    let db: DatabaseWriter

    func fetch(noteID: String) async throws -> [CleanCopyRow] {
        try await db.read { db in
            try CleanCopyRow.fetchAll(
                db,
                sql: """
                SELECT note_id AS noteID, idx AS idx, created_at_local AS createdAtLocal, rtf_path AS rtfPath, docx_path AS docxPath
                FROM clean_copies
                WHERE note_id = ?
                ORDER BY idx ASC
                """,
                arguments: [noteID]
            )
        }
    }

    func nextIndex(noteID: String) async throws -> Int {
        try await db.read { db in
            let maxIdx = try Int.fetchOne(db, sql: "SELECT MAX(idx) FROM clean_copies WHERE note_id = ?", arguments: [noteID]) ?? 0
            return maxIdx + 1
        }
    }

    func insert(noteID: String, idx: Int, createdAtLocal: String, rtfPath: String, docxPath: String) async throws {
        try await db.write { db in
            try CleanCopyModel(noteID: noteID, idx: idx, createdAtLocal: createdAtLocal, rtfPath: rtfPath, docxPath: docxPath).insert(db)
            try db.execute(sql: "UPDATE notes SET has_clean_copy = 1 WHERE note_id = ?", arguments: [noteID])
        }
    }
}
