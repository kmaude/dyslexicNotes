import Foundation
import GRDB

struct CleanCopyModel: Codable, FetchableRecord, PersistableRecord, Hashable { static let databaseTableName = "clean_copies"; var noteID: String; var idx: Int; var createdAtLocal: String; var rtfPath: String; var docxPath: String; enum CodingKeys: String, CodingKey { case noteID = "note_id"; case idx; case createdAtLocal = "created_at_local"; case rtfPath = "rtf_path"; case docxPath = "docx_path" } }
