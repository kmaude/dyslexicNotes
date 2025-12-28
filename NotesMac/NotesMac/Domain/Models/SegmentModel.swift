import Foundation
import GRDB

struct SegmentModel: Codable, FetchableRecord, PersistableRecord, Hashable { static let databaseTableName = "note_segments"; var noteID: String; var segmentIndex: Int; var startSec: Double; var endSec: Double; enum CodingKeys: String, CodingKey { case noteID = "note_id"; case segmentIndex = "segment_index"; case startSec = "start_sec"; case endSec = "end_sec" } }
