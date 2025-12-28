import Foundation
import GRDB

final class DatabaseManager {
    private(set) var dbWriter: DatabaseWriter?

    func start() throws {
        try FileSafety.ensureDirectory(URL.notesAppSupport)
        let pool = try DatabasePool(path: URL.notesDatabaseURL.path)
        try Migrations.migrator().migrate(pool)
        dbWriter = pool
    }

    func seedIfNeeded(settings: SettingsStore) throws {
        guard let dbWriter else { throw NSError(domain: "Notes", code: 1) }
        try dbWriter.write { db in
            let classCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM classes") ?? 0
            guard classCount == 0 else { return }

            let now = DateFormatters.isoLocalDateTime.string(from: Date())
            let miscID = UUID().uuidString
            let bioID = UUID().uuidString
            let histID = UUID().uuidString

            try ClassModel(classID: miscID, name: "Misc Notes", colorHex: "#9B9B9B", languageMode: .enOnly, specialLanguage: nil, isSystem: true, createdAtLocal: now).insert(db)
            try ClassModel(classID: bioID, name: "Biology", colorHex: "#4A90E2", languageMode: .enOnly, specialLanguage: nil, isSystem: false, createdAtLocal: now).insert(db)
            try ClassModel(classID: histID, name: "History", colorHex: "#F5A623", languageMode: .enOnly, specialLanguage: nil, isSystem: false, createdAtLocal: now).insert(db)

            // One sample note for UI demo.
            let noteID = UUID().uuidString
            let created = DateFormatters.isoLocalDateTime.string(from: Date())

            let sample = NoteModel(
                noteID: noteID,
                classID: bioID,
                title: "Cells & DNA",
                createdAtLocal: created,
                durationSeconds: 12 * 60,
                chunkSeconds: Constants.defaultChunkSeconds,
                autosplitMinutes: Constants.autosplitMinutes,
                inputDevice: "Internal Microphone",
                noiseMode: .normal,
                schoolModeEnabledAtCapture: settings.model.schoolModeEnabled,
                networkCallsBlocked: settings.model.schoolModeEnabled,
                hasCleanCopy: false
            )
            try sample.insert(db)
            try SegmentModel(noteID: noteID, segmentIndex: 0, startSec: 0, endSec: Double(sample.durationSeconds)).insert(db)

            let s1 = TranscriptSentenceModel(noteID: noteID, startSec: 0.0, endSec: 4.2, text: "Today we’re covering cell structure and DNA basics.", language: "en")
            let s2 = TranscriptSentenceModel(noteID: noteID, startSec: 4.2, endSec: 10.0, text: "Remember: the nucleus stores genetic information.", language: "en")
            try s1.insert(db)
            try s2.insert(db)
            try db.execute(sql: "INSERT INTO transcript_fts(note_id, content) VALUES (?, ?)", arguments: [noteID, s1.text + " " + s2.text])

            try MarkerModel(
                markerID: UUID().uuidString,
                noteID: noteID,
                type: .star,
                atSec: 4.4,
                createdAtLocal: created,
                contextStartSec: 0,
                contextEndSec: 19.4,
                contextText: "Cell structure overview; nucleus stores genetic information (DNA)."
            ).insert(db)

            settings.update { $0.lastClassID = bioID }
        }
    }
}
