import Foundation
import GRDB

struct MutedRangeModel: Codable, FetchableRecord, PersistableRecord, Hashable { static let databaseTableName = "muted_ranges"; var noteID: String; var startSec: Double; var endSec: Double; enum CodingKeys: String, CodingKey { case noteID = "note_id"; case startSec = "start_sec"; case endSec = "end_sec" } }
