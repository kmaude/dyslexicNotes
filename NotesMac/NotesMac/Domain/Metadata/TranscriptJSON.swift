import Foundation

struct TranscriptJSON: Codable {
    struct Sentence: Codable, Hashable {
        var startSec: Double
        var endSec: Double
        var text: String
        var language: String?

        enum CodingKeys: String, CodingKey {
            case startSec = "start_sec"
            case endSec = "end_sec"
            case text
            case language
        }
    }

    struct MutedRange: Codable, Hashable {
        var startSec: Double
        var endSec: Double
        var label: String

        enum CodingKeys: String, CodingKey {
            case startSec = "start_sec"
            case endSec = "end_sec"
            case label
        }
    }

    struct Segment: Codable, Hashable {
        var segmentIndex: Int
        var startSec: Double
        var endSec: Double

        enum CodingKeys: String, CodingKey {
            case segmentIndex = "segment_index"
            case startSec = "start_sec"
            case endSec = "end_sec"
        }
    }

    var noteID: String
    var sentences: [Sentence]
    var mutedRanges: [MutedRange]
    var segments: [Segment]

    enum CodingKeys: String, CodingKey {
        case noteID = "note_id"
        case sentences
        case mutedRanges = "muted_ranges"
        case segments
    }
}
