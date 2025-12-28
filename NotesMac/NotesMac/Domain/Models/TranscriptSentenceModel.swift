import Foundation
import GRDB

struct TranscriptSentenceModel: Codable, FetchableRecord, PersistableRecord, Hashable { static let databaseTableName = "transcript_sentences"; var noteID: String; var startSec: Double; var endSec: Double; var text: String; var language: String?; enum CodingKeys: String, CodingKey { case noteID = "note_id"; case startSec = "start_sec"; case endSec = "end_sec"; case text; case language } }
