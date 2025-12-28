import Foundation
import GRDB

struct NoteModel: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "notes"

    var noteID: String
    var classID: String
    var title: String
    var createdAtLocal: String
    var durationSeconds: Int
    var chunkSeconds: Int
    var autosplitMinutes: Int
    var inputDevice: String
    var noiseMode: NoiseMode
    var schoolModeEnabledAtCapture: Bool
    var networkCallsBlocked: Bool
    var hasCleanCopy: Bool

    var id: String { noteID }

    enum CodingKeys: String, CodingKey {
        case noteID = "note_id"
        case classID = "class_id"
        case title
        case createdAtLocal = "created_at_local"
        case durationSeconds = "duration_seconds"
        case chunkSeconds = "chunk_seconds"
        case autosplitMinutes = "autosplit_minutes"
        case inputDevice = "input_device"
        case noiseMode = "noise_mode"
        case schoolModeEnabledAtCapture = "school_mode_enabled_at_capture"
        case networkCallsBlocked = "network_calls_blocked"
        case hasCleanCopy = "has_clean_copy"
    }
}
