import Foundation
import GRDB

struct MarkerModel: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable { static let databaseTableName = "markers"; var markerID: String; var noteID: String; var type: MarkerType; var atSec: Double; var createdAtLocal: String; var contextStartSec: Double; var contextEndSec: Double; var contextText: String; var id: String { markerID } enum CodingKeys: String, CodingKey { case markerID = "marker_id"; case noteID = "note_id"; case type; case atSec = "at_sec"; case createdAtLocal = "created_at_local"; case contextStartSec = "context_start_sec"; case contextEndSec = "context_end_sec"; case contextText = "context_text" } }
