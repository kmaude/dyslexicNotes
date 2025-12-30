import Foundation
import GRDB

struct MarkerRow: Identifiable, Hashable {
    var id: String { markerID }

    let markerID: String
    let noteID: String
    let type: String
    let atSec: Double
    let createdAtLocal: String
    let contextStartSec: Double
    let contextEndSec: Double
    let contextText: String
}

struct MarkersDAO {
    let db: DatabaseWriter

    func insertMarker(noteID: String, type: MarkerType, atSec: Double, createdAtLocal: String, contextStartSec: Double, contextEndSec: Double, contextText: String) async throws {
        try await db.write { db in
            try MarkerModel(
                markerID: UUID().uuidString,
                noteID: noteID,
                type: type,
                atSec: atSec,
                createdAtLocal: createdAtLocal,
                contextStartSec: contextStartSec,
                contextEndSec: contextEndSec,
                contextText: contextText
            ).insert(db)
        }
    }

    func fetchMarkers(noteID: String) async throws -> [MarkerRow] {
        try await db.read { db in
            try MarkerRow.fetchAll(
                db,
                sql: """
                SELECT
                  marker_id AS markerID,
                  note_id AS noteID,
                  type AS type,
                  at_sec AS atSec,
                  created_at_local AS createdAtLocal,
                  context_start_sec AS contextStartSec,
                  context_end_sec AS contextEndSec,
                  context_text AS contextText
                FROM markers
                WHERE note_id = ?
                ORDER BY at_sec ASC
                """,
                arguments: [noteID]
            )
        }
    }
}
