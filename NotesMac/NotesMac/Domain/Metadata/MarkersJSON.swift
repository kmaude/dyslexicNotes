import Foundation

struct MarkersJSON: Codable {
    struct MarkerContext: Codable, Hashable {
        var preSec: Int
        var postSec: Int

        enum CodingKeys: String, CodingKey {
            case preSec = "pre_sec"
            case postSec = "post_sec"
        }
    }

    struct Marker: Codable, Hashable {
        struct Context: Codable, Hashable {
            var startSec: Double
            var endSec: Double
            var text: String

            enum CodingKeys: String, CodingKey {
                case startSec = "start_sec"
                case endSec = "end_sec"
                case text
            }
        }

        var id: String
        var type: String
        var atSec: Double
        var createdAtLocal: String
        var context: Context

        enum CodingKeys: String, CodingKey {
            case id
            case type
            case atSec = "at_sec"
            case createdAtLocal = "created_at_local"
            case context
        }
    }

    var noteID: String
    var markerContext: MarkerContext
    var markers: [Marker]

    enum CodingKeys: String, CodingKey {
        case noteID = "note_id"
        case markerContext = "marker_context"
        case markers
    }
}
