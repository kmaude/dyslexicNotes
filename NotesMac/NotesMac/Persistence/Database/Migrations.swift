import Foundation
import GRDB

enum Migrations {
    static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createCoreTables") { db in
            try db.create(table: "classes") { t in
                t.column("class_id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("color_hex", .text).notNull()
                t.column("language_mode", .text).notNull()
                t.column("special_language", .text)
                t.column("is_system", .integer).notNull()
                t.column("created_at_local", .text).notNull()
            }

            try db.create(table: "notes") { t in
                t.column("note_id", .text).primaryKey()
                t.column("class_id", .text).notNull().indexed().references("classes", column: "class_id")
                t.column("title", .text).notNull()
                t.column("created_at_local", .text).notNull().indexed()
                t.column("duration_seconds", .integer).notNull()
                t.column("chunk_seconds", .integer).notNull().defaults(to: Constants.defaultChunkSeconds)
                t.column("autosplit_minutes", .integer).notNull().defaults(to: Constants.autosplitMinutes)
                t.column("input_device", .text).notNull()
                t.column("noise_mode", .text).notNull()
                t.column("school_mode_enabled_at_capture", .integer).notNull()
                t.column("network_calls_blocked", .integer).notNull()
                t.column("has_clean_copy", .integer).notNull().defaults(to: 0)
            }

            try db.create(table: "note_segments") { t in
                t.column("note_id", .text).notNull().indexed().references("notes", column: "note_id", onDelete: .cascade)
                t.column("segment_index", .integer).notNull()
                t.column("start_sec", .double).notNull()
                t.column("end_sec", .double).notNull()
                t.primaryKey(["note_id", "segment_index"])
            }

            try db.create(table: "muted_ranges") { t in
                t.column("note_id", .text).notNull().indexed().references("notes", column: "note_id", onDelete: .cascade)
                t.column("start_sec", .double).notNull()
                t.column("end_sec", .double).notNull()
            }

            try db.create(table: "transcript_sentences") { t in
                t.column("note_id", .text).notNull().indexed().references("notes", column: "note_id", onDelete: .cascade)
                t.column("start_sec", .double).notNull()
                t.column("end_sec", .double).notNull()
                t.column("text", .text).notNull()
                t.column("language", .text)
            }

            try db.create(table: "markers") { t in
                t.column("marker_id", .text).primaryKey()
                t.column("note_id", .text).notNull().indexed().references("notes", column: "note_id", onDelete: .cascade)
                t.column("type", .text).notNull()
                t.column("at_sec", .double).notNull()
                t.column("created_at_local", .text).notNull()
                t.column("context_start_sec", .double).notNull()
                t.column("context_end_sec", .double).notNull()
                t.column("context_text", .text).notNull()
            }

            try db.create(table: "clean_copies") { t in
                t.column("note_id", .text).notNull().indexed().references("notes", column: "note_id", onDelete: .cascade)
                t.column("idx", .integer).notNull()
                t.column("created_at_local", .text).notNull()
                t.column("rtf_path", .text).notNull()
                t.column("docx_path", .text).notNull()
                t.primaryKey(["note_id", "idx"])
            }
        }

        migrator.registerMigration("createFTS") { db in
            try db.create(virtualTable: "transcript_fts", using: FTS5()) { t in
                t.column("note_id")
                t.column("content")
            }
        }

        return migrator
    }
}
