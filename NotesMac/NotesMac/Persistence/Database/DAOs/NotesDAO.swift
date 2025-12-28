import Foundation
import GRDB

struct NoteCardRow: Identifiable, Hashable {
    var id: String { noteID }

    let noteID: String
    let classID: String
    let className: String
    let classColorHex: String
    let title: String
    let createdAtLocal: String
    let durationSeconds: Int
    let languageMode: String
    let segmentCount: Int
    let starCount: Int
    let questionCount: Int
    let hasCleanCopy: Bool
}

struct NotesDAO {
    let db: DatabaseWriter

    func fetchToday(search: String?) async throws -> [NoteCardRow] {
        let today = DateFormatters.isoLocalDate.string(from: Date())
        let searchTerm = (search ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        return try await db.read { db in
            var sql = """
            SELECT
              n.note_id AS noteID,
              n.class_id AS classID,
              c.name AS className,
              c.color_hex AS classColorHex,
              n.title AS title,
              n.created_at_local AS createdAtLocal,
              n.duration_seconds AS durationSeconds,
              c.language_mode AS languageMode,
              (SELECT COUNT(*) FROM note_segments s WHERE s.note_id = n.note_id) AS segmentCount,
              (SELECT COUNT(*) FROM markers m WHERE m.note_id = n.note_id AND m.type = 'STAR') AS starCount,
              (SELECT COUNT(*) FROM markers m WHERE m.note_id = n.note_id AND m.type = 'QUESTION') AS questionCount,
              n.has_clean_copy AS hasCleanCopy
            FROM notes n
            JOIN classes c ON c.class_id = n.class_id
            WHERE substr(n.created_at_local, 1, 10) = ?
            """
            var args: [DatabaseValueConvertible] = [today]

            if !searchTerm.isEmpty {
                sql += " AND (n.title LIKE ? OR n.note_id IN (SELECT note_id FROM transcript_fts WHERE transcript_fts MATCH ?))"
                args.append("%\(searchTerm)%")
                args.append(searchTerm)
            }

            sql += " ORDER BY n.created_at_local DESC"
            return try NoteCardRow.fetchAll(db, sql: sql, arguments: StatementArguments(args))
        }
    }
}
