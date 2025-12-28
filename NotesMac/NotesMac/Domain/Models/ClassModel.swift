import Foundation
import GRDB

struct ClassModel: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "classes"

    var classID: String
    var name: String
    var colorHex: String
    var languageMode: LanguageMode
    var specialLanguage: String?
    var isSystem: Bool
    var createdAtLocal: String

    var id: String { classID }

    enum CodingKeys: String, CodingKey {
        case classID = "class_id"
        case name
        case colorHex = "color_hex"
        case languageMode = "language_mode"
        case specialLanguage = "special_language"
        case isSystem = "is_system"
        case createdAtLocal = "created_at_local"
    }
}
