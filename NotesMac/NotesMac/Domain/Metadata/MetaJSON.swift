import Foundation

struct MetaJSON: Codable {
    struct ClassInfo: Codable, Hashable {
        var name: String
        var classID: String
        var colorHex: String
        var languageMode: String
        var specialLanguage: String?

        enum CodingKeys: String, CodingKey {
            case name
            case classID = "class_id"
            case colorHex = "color_hex"
            case languageMode = "language_mode"
            case specialLanguage = "special_language"
        }
    }

    struct StorageInfo: Codable, Hashable {
        var basePath: String
        var classFolder: String
        var dateFolder: String

        enum CodingKeys: String, CodingKey {
            case basePath = "base_path"
            case classFolder = "class_folder"
            case dateFolder = "date_folder"
        }
    }

    struct AudioInfo: Codable, Hashable {
        var file: String
        var sampleRate: Double
        var channels: Int
        var inputDevice: String
        var noiseMode: String

        enum CodingKeys: String, CodingKey {
            case file
            case sampleRate = "sample_rate"
            case channels
            case inputDevice = "input_device"
            case noiseMode = "noise_mode"
        }
    }

    struct CaptureInfo: Codable, Hashable {
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

        struct MutedRange: Codable, Hashable {
            var startSec: Double
            var endSec: Double

            enum CodingKeys: String, CodingKey {
                case startSec = "start_sec"
                case endSec = "end_sec"
            }
        }

        var chunkSeconds: Int
        var autosplitMinutes: Int
        var durationSeconds: Int
        var segments: [Segment]
        var mutedRanges: [MutedRange]

        enum CodingKeys: String, CodingKey {
            case chunkSeconds = "chunk_seconds"
            case autosplitMinutes = "autosplit_minutes"
            case durationSeconds = "duration_seconds"
            case segments
            case mutedRanges = "muted_ranges"
        }
    }

    struct MarkersInfo: Codable, Hashable {
        var countStar: Int
        var countQuestion: Int
        var file: String

        enum CodingKeys: String, CodingKey {
            case countStar = "count_star"
            case countQuestion = "count_question"
            case file
        }
    }

    struct TranscriptInfo: Codable, Hashable {
        var engine: String
        var status: String
        var fileJSON: String
        var fileTXT: String

        enum CodingKeys: String, CodingKey {
            case engine
            case status
            case fileJSON = "file_json"
            case fileTXT = "file_txt"
        }
    }

    struct OrganizerInfo: Codable, Hashable {
        var mode: String
        var status: String
        var fileMD: String
        var lastRunAtLocal: String?

        enum CodingKeys: String, CodingKey {
            case mode
            case status
            case fileMD = "file_md"
            case lastRunAtLocal = "last_run_at_local"
        }
    }

    struct VersionInfo: Codable, Hashable {
        var cleanCopies: [CleanCopy]

        struct CleanCopy: Codable, Hashable {
            var idx: Int
            var createdAtLocal: String
            var rtfPath: String
            var docxPath: String

            enum CodingKeys: String, CodingKey {
                case idx
                case createdAtLocal = "created_at_local"
                case rtfPath = "rtf_path"
                case docxPath = "docx_path"
            }
        }

        enum CodingKeys: String, CodingKey {
            case cleanCopies = "clean_copies"
        }
    }

    struct PrivacyInfo: Codable, Hashable {
        var schoolModeEnabledAtCapture: Bool
        var networkCallsBlocked: Bool

        enum CodingKeys: String, CodingKey {
            case schoolModeEnabledAtCapture = "school_mode_enabled_at_capture"
            case networkCallsBlocked = "network_calls_blocked"
        }
    }

    var schemaVersion: Int
    var noteID: String
    var createdAtLocal: String
    var `class`: ClassInfo
    var storage: StorageInfo
    var audio: AudioInfo
    var capture: CaptureInfo
    var markers: MarkersInfo
    var transcript: TranscriptInfo
    var organizer: OrganizerInfo
    var versions: VersionInfo
    var privacy: PrivacyInfo

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case noteID = "note_id"
        case createdAtLocal = "created_at_local"
        case `class` = "class"
        case storage
        case audio
        case capture
        case markers
        case transcript
        case organizer
        case versions
        case privacy
    }
}
